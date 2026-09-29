import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/staff_med_options.dart';
import '../../domain/repositories/staff_medication_repository.dart';

/// Add Medicine / Add PRN Medicine sheet matching web MAR create modals.
class StaffAddMedicineSheet extends StatefulWidget {
  final VoidCallback? onCreated;

  const StaffAddMedicineSheet({super.key, this.onCreated});

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onCreated,
  }) {
    final height = MediaQuery.sizeOf(context).height;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: AppColors.surfaceWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 720,
            height: height * 0.9,
            child: StaffAddMedicineSheet(onCreated: onCreated),
          ),
        ),
      );
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: height * 0.94,
        child: StaffAddMedicineSheet(onCreated: onCreated),
      ),
    );
  }

  @override
  State<StaffAddMedicineSheet> createState() => _StaffAddMedicineSheetState();
}

class _MedicineDraft {
  final name = TextEditingController();
  final dose = TextEditingController();
  final route = TextEditingController();
  final stock = TextEditingController();
  final whenToGive = TextEditingController();
  final timeInput = TextEditingController();
  final minGap = TextEditingController();
  bool controlled = false;
  String frequency = 'daily';
  final List<String> times = ['08:00'];
  DateTime? startsAt;
  DateTime? endsAt;
  String? requiresCheckScheduleId;

  void dispose() {
    name.dispose();
    dose.dispose();
    route.dispose();
    stock.dispose();
    whenToGive.dispose();
    timeInput.dispose();
    minGap.dispose();
  }
}

class _StaffAddMedicineSheetState extends State<StaffAddMedicineSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _repo = GetIt.instance<StaffMedicationRepository>();
  final _scroll = ScrollController();

  List<StaffMedResidenceOption> _residences = [];
  List<StaffMedClientOption> _clients = [];
  List<StaffMedCheckOption> _checks = [];
  bool _loadingOptions = true;
  bool _submitting = false;
  String? _banner;

  StaffMedResidenceOption? _residence;
  StaffMedClientOption? _client;
  final List<_MedicineDraft> _medicines = [_MedicineDraft()];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() => _banner = null);
    });
    _loadOptions();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _scroll.dispose();
    for (final m in _medicines) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    final residences = await _repo.getResidences();
    residences.when(
      success: (list) => _residences = list,
      failure: (_) {},
    );
    await _reloadClientsAndChecks();
    if (mounted) setState(() => _loadingOptions = false);
  }

  Future<void> _reloadClientsAndChecks() async {
    final clients = await _repo.getClients(residenceId: _residence?.id);
    clients.when(
      success: (list) {
        _clients = list;
        if (_client != null && list.every((c) => c.id != _client!.id)) {
          _client = null;
        }
      },
      failure: (_) => _clients = [],
    );
    final checks = await _repo.getCheckSchedules(residenceId: _residence?.id);
    checks.when(
      success: (list) {
        _checks = list;
        for (final m in _medicines) {
          if (m.requiresCheckScheduleId != null &&
              list.every((c) => c.id != m.requiresCheckScheduleId)) {
            m.requiresCheckScheduleId = null;
          }
        }
      },
      failure: (_) => _checks = [],
    );
  }

  bool get _isPrn => _tabs.index == 1;

  String get _title => _isPrn ? 'Add a PRN medicine' : 'Add a medicine';

  String get _subtitle => _isPrn
      ? 'Not prescribed by a doctor — given as needed.'
      : 'Charted at set times against one resident.';

  void _addMedicine() {
    setState(() => _medicines.add(_MedicineDraft()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeMedicine(int index) {
    if (_medicines.length <= 1) return;
    setState(() => _medicines.removeAt(index).dispose());
  }

  String? _validate() {
    if (_residence == null) return 'House / residence is required.';
    if (!_isPrn && _client == null) return 'Resident is required.';
    for (var i = 0; i < _medicines.length; i++) {
      final m = _medicines[i];
      if (m.name.text.trim().isEmpty) {
        return 'Medicine ${i + 1}: name is required.';
      }
      if (!_isPrn && m.times.isEmpty) {
        return 'Medicine ${i + 1}: add at least one schedule time.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      setState(() => _banner = error);
      return;
    }
    setState(() {
      _banner = null;
      _submitting = true;
    });

    String? firstError;
    var saved = 0;
    for (final m in _medicines) {
      final stock = int.tryParse(m.stock.text.trim());
      final gap = int.tryParse(m.minGap.text.trim());
      final result = _isPrn
          ? await _repo.createPrnMedication(
              StaffCreatePrnMedicationInput(
                residenceId: _residence!.id,
                clientId: _client?.id,
                name: m.name.text.trim(),
                dose: m.dose.text.trim().isEmpty ? null : m.dose.text.trim(),
                route: m.route.text.trim().isEmpty ? null : m.route.text.trim(),
                instructions: m.whenToGive.text.trim().isEmpty
                    ? null
                    : m.whenToGive.text.trim(),
                stockUnitsPerDose: stock,
                startsAt: m.startsAt,
                endsAt: m.endsAt,
                isControlled: m.controlled,
                minIntervalMinutes: gap,
                requiresCheckScheduleId: m.requiresCheckScheduleId,
              ),
            )
          : await _repo.createMedication(
              StaffCreateMedicationInput(
                residenceId: _residence!.id,
                clientId: _client!.id,
                name: m.name.text.trim(),
                dose: m.dose.text.trim().isEmpty ? null : m.dose.text.trim(),
                route: m.route.text.trim().isEmpty ? null : m.route.text.trim(),
                stockUnitsPerDose: stock,
                scheduleFrequency: m.frequency,
                scheduleTimes: List<String>.from(m.times)..sort(),
                startsAt: m.startsAt,
                endsAt: m.endsAt,
                isControlled: m.controlled,
                requiresCheckScheduleId: m.requiresCheckScheduleId,
              ),
            );
      if (result.isFailure) {
        firstError ??= result.error?.message ?? 'Could not save.';
        break;
      }
      saved += 1;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (firstError != null) {
      setState(
        () => _banner = saved == 0
            ? firstError
            : 'Saved $saved, then failed: $firstError',
      );
      AppErrorDialog.showPageError(
        title: 'Could not add medicine',
        message: firstError,
      );
      return;
    }

    widget.onCreated?.call();
    AppSnackbar.show(
      'Medicine added',
      saved == 1
          ? (_isPrn
              ? 'PRN medicine was created.'
              : 'Scheduled medicine was created.')
          : '$saved medicines were created.',
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDate(_MedicineDraft m, {required bool start}) async {
    final initial = (start ? m.startsAt : m.endsAt) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        m.startsAt = picked;
      } else {
        m.endsAt = picked;
      }
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'dd/mm/yyyy';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Medicine'),
                    Tab(text: 'PRN Medicine'),
                  ],
                ),
              ),
            ),
            if (_banner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBackgroundSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.criticalBackground),
                  ),
                  child: Text(
                    _banner!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: AppColors.criticalRed,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loadingOptions
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    )
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        Text(
                          _isPrn ? 'Where this is held' : 'Who this is for',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Labeled(
                          label: 'House *',
                          child: DropdownButtonFormField<
                              StaffMedResidenceOption>(
                            key: ValueKey('house-${_residence?.id}'),
                            initialValue: _residence,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'Where it is held',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              for (final r in _residences)
                                DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) async {
                              setState(() {
                                _residence = value;
                                _client = null;
                              });
                              await _reloadClientsAndChecks();
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Labeled(
                          label: _isPrn ? 'Resident (optional)' : 'Resident *',
                          child: DropdownButtonFormField<
                              StaffMedClientOption?>(
                            key: ValueKey(
                              'resident-${_residence?.id}-${_client?.id}-${_clients.length}',
                            ),
                            initialValue: _client,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: _residence == null
                                  ? 'Choose a house first'
                                  : (_clients.isEmpty
                                      ? 'No residents in house'
                                      : 'Choose a resident'),
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              if (_isPrn)
                                const DropdownMenuItem<StaffMedClientOption?>(
                                  value: null,
                                  child: Text('— None —'),
                                ),
                              for (final c in _clients)
                                DropdownMenuItem<StaffMedClientOption?>(
                                  value: c,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _residence == null
                                ? null
                                : (value) => setState(() => _client = value),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _addMedicine,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add another medicine',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        for (var i = 0; i < _medicines.length; i++)
                          _MedicineCard(
                            index: i,
                            draft: _medicines[i],
                            isPrn: _isPrn,
                            canRemove: _medicines.length > 1,
                            checks: _checks,
                            onRemove: () => _removeMedicine(i),
                            onChanged: () => setState(() {}),
                            onPickStart: () =>
                                _pickDate(_medicines[i], start: true),
                            onPickEnd: () =>
                                _pickDate(_medicines[i], start: false),
                            formatDate: _fmt,
                          ),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed:
                          _submitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('staff-mar-add-medicine-save'),
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        minimumSize: Size(
                          ResponsiveHelper.getResponsiveWidth(context, 120),
                          44,
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;

  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final int index;
  final _MedicineDraft draft;
  final bool isPrn;
  final bool canRemove;
  final List<StaffMedCheckOption> checks;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final String Function(DateTime?) formatDate;

  const _MedicineCard({
    required this.index,
    required this.draft,
    required this.isPrn,
    required this.canRemove,
    required this.checks,
    required this.onRemove,
    required this.onChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.formatDate,
  });

  void _commitTime() {
    final raw = draft.timeInput.text.trim();
    if (raw.isEmpty) return;
    final normalized = _normalizeTime(raw);
    if (normalized == null) return;
    if (!draft.times.contains(normalized)) {
      draft.times.add(normalized);
      draft.times.sort();
    }
    draft.timeInput.clear();
    onChanged();
  }

  static String? _normalizeTime(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d:]'), '');
    final match = RegExp(r'^(\d{1,2}):?(\d{2})$').firstMatch(cleaned);
    if (match == null) return null;
    final h = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _medicinesLabel(index),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove',
                ),
            ],
          ),
          // Medicine * | Dose
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Labeled(
                  label: 'Medicine *',
                  child: TextField(
                    controller: draft.name,
                    decoration: const InputDecoration(
                      hintText: 'Paracetamol 500mg',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Labeled(
                  label: 'Dose',
                  child: TextField(
                    controller: draft.dose,
                    decoration: const InputDecoration(
                      hintText: '1 tablet',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isPrn) ...[
            const SizedBox(height: 12),
            _Labeled(
              label: 'When to give it',
              child: TextField(
                controller: draft.whenToGive,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'For pain, up to 4 in 24 hours, at least 4 hours apart...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            // How often | At what times
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Labeled(
                    label: 'How often',
                    child: DropdownButtonFormField<String>(
                      initialValue: draft.frequency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text('Every day'),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        draft.frequency = value;
                        onChanged();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Labeled(
                    label: 'At what times',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: draft.timeInput,
                          decoration: const InputDecoration(
                            hintText: 'Type and press Enter...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.datetime,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _commitTime(),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9:]'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '24-hour, one per entry — 08:00, 14:00, 20:00',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (draft.times.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final t in draft.times)
                                InputChip(
                                  label: Text(t),
                                  onDeleted: () {
                                    draft.times.remove(t);
                                    onChanged();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Route | Units of stock
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Labeled(
                  label: 'Route',
                  child: TextField(
                    controller: draft.route,
                    decoration: const InputDecoration(
                      hintText: 'Oral, topical, inhaled...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Labeled(
                  label: 'Units of stock per dose',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: draft.stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Leave blank to count stock by hand',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Only set this where a dose maps cleanly onto the stock unit.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Starts | Ends
          Row(
            children: [
              Expanded(
                child: _Labeled(
                  label: 'Starts (optional)',
                  child: OutlinedButton.icon(
                    onPressed: onPickStart,
                    icon: const Icon(Icons.calendar_today_outlined, size: 14),
                    label: Text(formatDate(draft.startsAt)),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Labeled(
                  label: 'Ends (optional)',
                  child: OutlinedButton.icon(
                    onPressed: onPickEnd,
                    icon: const Icon(Icons.calendar_today_outlined, size: 14),
                    label: Text(formatDate(draft.endsAt)),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPrn
                ? 'Leave both blank for standing house stock.'
                : 'Leave both blank for a standing prescription.',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          if (isPrn) ...[
            const SizedBox(height: 12),
            _Labeled(
              label: 'Shortest gap between doses (minutes)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: draft.minGap,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Leave blank for no minimum',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '240 for a medicine prescribed no more often than four hourly.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.controlled,
            onChanged: (v) {
              draft.controlled = v ?? false;
              onChanged();
            },
            title: const Text(
              'Controlled drug — a witness is required to chart a dose',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 13),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.secondaryTeal,
          ),
          _Labeled(
            label: 'Requires a check first',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String?>(
                  key: ValueKey(
                    'check-${draft.requiresCheckScheduleId}-${checks.length}',
                  ),
                  initialValue: draft.requiresCheckScheduleId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No check required'),
                    ),
                    for (final c in checks)
                      DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(
                          c.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    draft.requiresCheckScheduleId = value;
                    onChanged();
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  'A dose cannot be charted until this check has been recorded',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _medicinesLabel(int index) =>
      index == 0 ? 'Medication details' : 'Medicine ${index + 1}';
}
