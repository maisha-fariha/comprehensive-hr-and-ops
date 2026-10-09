import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import '../../domain/entities/staff_med_options.dart';
import '../../domain/repositories/staff_medication_repository.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Add Medicine / Add PRN, or the web "Correct a medicine" when [editing] is
/// set — styled to match staff form field theme.
class StaffAddMedicineSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  final StaffClientMedicationItem? editing;

  const StaffAddMedicineSheet({super.key, this.onCreated, this.editing});

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onCreated,
    StaffClientMedicationItem? editing,
  }) {
    final height = MediaQuery.sizeOf(context).height;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return showAppPopup<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AppSheetPanel(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: AppColors.surfaceWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 720,
            height: height * 0.9,
            child: StaffAddMedicineSheet(onCreated: onCreated, editing: editing),
          ),
        ),
      );
    }
    return showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: height * 0.94,
        child: StaffAddMedicineSheet(onCreated: onCreated, editing: editing),
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
  final Set<int> weekdays = <int>{};
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

/// Shared field chrome used across staff forms.
InputDecoration _medFieldDecoration({
  String? hint,
  bool dense = true,
}) {
  const radius = 12.0;
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: AppColors.textMuted,
    ),
    filled: true,
    fillColor: AppColors.surfaceWhite,
    isDense: dense,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 1.4),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: AppColors.searchBorder.withValues(alpha: 0.7),
      ),
    ),
  );
}

/// Web "How often" options (`e_` in the MAR page chunk).
const List<(String, String)> _frequencies = [
  ('daily', 'Every day'),
  ('weekly', 'Weekly'),
  ('custom', 'Something else'),
];

const _fieldTextStyle = TextStyle(
  fontFamily: 'Outfit',
  fontWeight: FontWeight.w500,
  fontSize: 14,
  color: AppColors.textHeading,
);

class _StaffAddMedicineSheetState extends State<StaffAddMedicineSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _repo = GetIt.instance<StaffMedicationRepository>();
  final _scroll = ScrollController();

  List<StaffMedResidenceOption> _residences = [];
  List<StaffMedClientOption> _allClients = [];
  List<StaffMedCheckOption> _checks = [];
  bool _loadingOptions = true;
  bool _submitting = false;
  String? _banner;

  StaffMedResidenceOption? _residence;
  StaffMedClientOption? _client;
  final List<_MedicineDraft> _medicines = [_MedicineDraft()];

  bool get _editingMode => widget.editing != null;

  /// Residents of the chosen house, filtered locally like the web form.
  List<StaffMedClientOption> get _clients {
    final house = _residence?.id;
    if (house == null) return const [];
    final list = [
      for (final c in _allClients)
        if (c.residenceId == null ||
            c.residenceId!.isEmpty ||
            c.residenceId == house)
          c,
    ];
    final current = _client;
    if (current != null && !list.contains(current)) list.add(current);
    return list;
  }

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: editing?.isPrn == true ? 1 : 0,
    );
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() => _banner = null);
    });
    if (editing != null) _prefill(editing);
    _loadOptions();
  }

  void _prefill(StaffClientMedicationItem m) {
    final draft = _medicines.first;
    draft.name.text = m.name;
    draft.dose.text = m.dose == '—' ? '' : m.dose;
    draft.route.text = m.route;
    draft.whenToGive.text = m.instructions ?? '';
    draft.stock.text = m.stockUnitsPerDose?.toString() ?? '';
    draft.minGap.text = m.minIntervalMinutes?.toString() ?? '';
    draft.controlled = m.isControlled;
    // Kept from the record so a correction does not wipe the round times.
    if (_frequencies.any((f) => f.$1 == m.frequency)) {
      draft.frequency = m.frequency;
    }
    draft.times
      ..clear()
      ..addAll(m.times);
    draft.weekdays
      ..clear()
      ..addAll(m.weekdays);
    draft.startsAt = m.startsAt?.toUtc();
    draft.endsAt = m.endsAt?.toUtc();
    draft.requiresCheckScheduleId = m.requiresCheckScheduleId;
    if (m.residenceId.isNotEmpty) {
      _residence = StaffMedResidenceOption(
        id: m.residenceId,
        name: m.residenceName.isEmpty ? 'Current house' : m.residenceName,
      );
    }
    if (m.clientId.isNotEmpty) {
      _client = StaffMedClientOption(
        id: m.clientId,
        name: m.clientName.isEmpty ? 'Resident' : m.clientName,
        residenceId: m.residenceId,
      );
    }
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
    final residences = await _repo.getResidences();
    residences.when(
      success: (list) => _residences = list,
      failure: (_) {},
    );
    final current = _residence;
    if (current != null) {
      final match = _residences.where((r) => r == current).firstOrNull;
      if (match != null) {
        _residence = match;
      } else {
        _residences = [..._residences, current];
      }
    }
    final clients = await _repo.getClients();
    clients.when(
      success: (list) {
        _allClients = list;
        final picked = _client;
        if (picked != null) {
          _client = list.where((c) => c == picked).firstOrNull ?? picked;
        }
      },
      failure: (_) {},
    );
    await _reloadChecks();
    if (mounted) setState(() => _loadingOptions = false);
  }

  Future<void> _reloadChecks() async {
    final checks = await _repo.getCheckSchedules(residenceId: _residence?.id);
    final list = [...?checks.value];
    // A dropdown value must be one of its items: a correction keeps the
    // record's check, a new medicine drops one that is no longer offered.
    for (final m in _medicines) {
      final id = m.requiresCheckScheduleId;
      if (id == null || list.any((c) => c.id == id)) continue;
      if (_editingMode) {
        list.add(StaffMedCheckOption(id: id, name: 'Current check'));
      } else {
        m.requiresCheckScheduleId = null;
      }
    }
    _checks = list;
  }

  bool get _isPrn => widget.editing?.isPrn ?? _tabs.index == 1;

  String get _title => _editingMode
      ? (_isPrn ? 'Correct a PRN medicine' : 'Correct a medicine')
      : (_isPrn ? 'Add a PRN medicine' : 'Add a medicine');

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
      if (!_isPrn && m.frequency == 'weekly' && m.weekdays.isEmpty) {
        return 'Medicine ${i + 1}: pick at least one weekday for weekly.';
      }
      if (m.startsAt != null &&
          m.endsAt != null &&
          m.endsAt!.isBefore(m.startsAt!)) {
        return 'Medicine ${i + 1}: end date must be on or after start date.';
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
    final editing = widget.editing;
    for (final m in _medicines) {
      final stock = int.tryParse(m.stock.text.trim());
      final gap = int.tryParse(m.minGap.text.trim());
      final prnInput = StaffCreatePrnMedicationInput(
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
        requiresCheckWithinMinutes: editing?.requiresCheckWithinMinutes,
      );
      final medicationInput = _isPrn
          ? null
          : StaffCreateMedicationInput(
              residenceId: _residence!.id,
              clientId: _client!.id,
              name: m.name.text.trim(),
              dose: m.dose.text.trim().isEmpty ? null : m.dose.text.trim(),
              route: m.route.text.trim().isEmpty ? null : m.route.text.trim(),
              stockUnitsPerDose: stock,
              scheduleFrequency: m.frequency,
              scheduleTimes: List<String>.from(m.times)..sort(),
              scheduleWeekdays: m.frequency == 'weekly'
                  ? (m.weekdays.toList()..sort())
                  : const [],
              startsAt: m.startsAt,
              endsAt: m.endsAt,
              isControlled: m.controlled,
              requiresCheckScheduleId: m.requiresCheckScheduleId,
              requiresCheckWithinMinutes: editing?.requiresCheckWithinMinutes,
            );
      final result = switch ((editing, medicationInput)) {
        (final StaffClientMedicationItem e, null) =>
          await _repo.updatePrnMedication(e.id, prnInput),
        (final StaffClientMedicationItem e, final input?) =>
          await _repo.updateMedication(e.id, input),
        (null, null) => await _repo.createPrnMedication(prnInput),
        (null, final input?) => await _repo.createMedication(input),
      };
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
        title: _editingMode ? 'Could not save changes' : 'Could not add medicine',
        message: firstError,
      );
      return;
    }

    widget.onCreated?.call();
    final String toast;
    if (_editingMode) {
      toast = _isPrn ? 'Medicine updated' : 'Prescription updated';
    } else if (saved == 1) {
      toast = _isPrn ? 'Medicine added' : 'Prescription added';
    } else {
      toast = _isPrn
          ? '$saved medicines added'
          : '$saved medicines prescribed';
    }
    AppSnackbar.show(toast, '');
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
      color: AppColors.scaffoldBackground,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.surfaceWhite,
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
                    padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.quickActionCreateShiftBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            color: AppColors.secondaryTeal,
                            size: 22,
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
                                  fontSize: 12.5,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_editingMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.filterButtonBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.shadowNavy.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        labelColor: AppColors.secondaryTeal,
                        unselectedLabelColor: AppColors.textMuted,
                        labelStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Medicine'),
                          Tab(text: 'PRN Medicine'),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _SectionCard(
                          title: _isPrn ? 'Where this is held' : 'Who this is for',
                          child: Column(
                            children: [
                              _Labeled(
                                label: 'House',
                                required: true,
                                hint: _editingMode
                                    ? 'Moving a medicine between houses is not an edit.'
                                    : null,
                                child: DropdownButtonFormField<
                                    StaffMedResidenceOption>(
                                  key: ValueKey('house-${_residence?.id}'),
                                  initialValue: _residence,
                                  isExpanded: true,
                                  style: _fieldTextStyle,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                  decoration: _medFieldDecoration(
                                    hint: 'Where it is held',
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
                                  onChanged: _editingMode
                                      ? null
                                      : (value) async {
                                          setState(() {
                                            _residence = value;
                                            if (_client?.residenceId !=
                                                value?.id) {
                                              _client = null;
                                            }
                                          });
                                          await _reloadChecks();
                                          if (mounted) setState(() {});
                                        },
                                ),
                              ),
                              const SizedBox(height: 14),
                              _Labeled(
                                label: _isPrn ? 'Resident (optional)' : 'Resident',
                                required: !_isPrn,
                                child: DropdownButtonFormField<
                                    StaffMedClientOption?>(
                                  key: ValueKey(
                                    'resident-${_residence?.id}-${_client?.id}-${_clients.length}',
                                  ),
                                  initialValue: _client,
                                  isExpanded: true,
                                  style: _fieldTextStyle,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                  decoration: _medFieldDecoration(
                                    hint: _residence == null
                                        ? 'Choose a house first'
                                        : (_clients.isEmpty
                                            ? 'No residents in house'
                                            : 'Choose a resident'),
                                  ),
                                  items: [
                                    if (_isPrn)
                                      const DropdownMenuItem<
                                          StaffMedClientOption?>(
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
                                      : (value) =>
                                          setState(() => _client = value),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_editingMode)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _addMedicine,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondaryTeal,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Add another medicine',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(
                  top: BorderSide(
                    color: AppColors.cardBorder.withValues(alpha: 0.9),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textHeading,
                            side: const BorderSide(
                              color: AppColors.searchBorder,
                            ),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key('staff-mar-add-medicine-save'),
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondaryTeal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                              : Text(
                                  _editingMode ? 'Save changes' : 'Add',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final Widget child;

  const _Labeled({
    required this.label,
    required this.child,
    this.required = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppColors.textHeading,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.criticalRed),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _DateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'dd/mm/yyyy';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isPlaceholder
                        ? AppColors.textMuted
                        : AppColors.textHeading,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
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
    final wide = MediaQuery.sizeOf(context).width >= 600;

    Widget pair(Widget a, Widget b) {
      if (!wide) {
        return Column(
          children: [
            a,
            const SizedBox(height: 14),
            b,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SectionCard(
        title: index == 0 ? 'Medication details' : 'Medicine ${index + 1}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canRemove)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'Remove',
                ),
              ),
            pair(
              _Labeled(
                label: 'Medicine',
                required: true,
                child: TextField(
                  controller: draft.name,
                  style: _fieldTextStyle,
                  decoration: _medFieldDecoration(hint: 'Paracetamol 500mg'),
                ),
              ),
              _Labeled(
                label: 'Dose',
                child: TextField(
                  controller: draft.dose,
                  style: _fieldTextStyle,
                  decoration: _medFieldDecoration(hint: '1 tablet'),
                ),
              ),
            ),
            if (isPrn) ...[
              const SizedBox(height: 14),
              _Labeled(
                label: 'When to give it',
                child: TextField(
                  controller: draft.whenToGive,
                  maxLines: 3,
                  style: _fieldTextStyle,
                  decoration: _medFieldDecoration(
                    hint:
                        'For pain, up to 4 in 24 hours, at least 4 hours apart...',
                  ).copyWith(
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              pair(
                _Labeled(
                  label: 'How often',
                  child: DropdownButtonFormField<String>(
                    initialValue: draft.frequency,
                    isExpanded: true,
                    style: _fieldTextStyle,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                    decoration: _medFieldDecoration(),
                    items: [
                      for (final f in _frequencies)
                        DropdownMenuItem(value: f.$1, child: Text(f.$2)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      draft.frequency = value;
                      if (value != 'weekly') draft.weekdays.clear();
                      onChanged();
                    },
                  ),
                ),
                _Labeled(
                  label: 'At what times',
                  hint: '24-hour, one per entry — 08:00, 14:00, 20:00',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: draft.timeInput,
                        style: _fieldTextStyle,
                        decoration: _medFieldDecoration(
                          hint: 'Type and press Enter...',
                        ),
                        keyboardType: TextInputType.datetime,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _commitTime(),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                        ],
                      ),
                      if (draft.times.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in draft.times)
                              InputChip(
                                label: Text(
                                  t,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: AppColors.secondaryTeal,
                                  ),
                                ),
                                backgroundColor:
                                    AppColors.quickActionCreateShiftBg,
                                side: BorderSide.none,
                                deleteIconColor: AppColors.secondaryTeal,
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
              if (draft.frequency == 'weekly') ...[
                const SizedBox(height: 14),
                _Labeled(
                  label: 'Weekdays',
                  hint: 'Which days this weekly dose falls on',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in const [
                        (1, 'Mon'),
                        (2, 'Tue'),
                        (3, 'Wed'),
                        (4, 'Thu'),
                        (5, 'Fri'),
                        (6, 'Sat'),
                        (7, 'Sun'),
                      ])
                        FilterChip(
                          label: Text(entry.$2),
                          selected: draft.weekdays.contains(entry.$1),
                          onSelected: (selected) {
                            if (selected) {
                              draft.weekdays.add(entry.$1);
                            } else {
                              draft.weekdays.remove(entry.$1);
                            }
                            onChanged();
                          },
                          selectedColor: AppColors.quickActionCreateShiftBg,
                          checkmarkColor: AppColors.secondaryTeal,
                          labelStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: draft.weekdays.contains(entry.$1)
                                ? AppColors.secondaryTeal
                                : AppColors.textHeading,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
            pair(
              _Labeled(
                label: 'Route',
                child: TextField(
                  controller: draft.route,
                  style: _fieldTextStyle,
                  decoration: _medFieldDecoration(
                    hint: 'Oral, topical, inhaled...',
                  ),
                ),
              ),
              _Labeled(
                label: 'Units of stock per dose',
                hint:
                    'Only set this where a dose maps cleanly onto the stock unit.',
                child: TextField(
                  controller: draft.stock,
                  style: _fieldTextStyle,
                  keyboardType: TextInputType.number,
                  decoration: _medFieldDecoration(
                    hint: 'Leave blank to count stock by hand',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            pair(
              _Labeled(
                label: 'Starts (optional)',
                child: _DateField(
                  value: formatDate(draft.startsAt),
                  onTap: onPickStart,
                ),
              ),
              _Labeled(
                label: 'Ends (optional)',
                child: _DateField(
                  value: formatDate(draft.endsAt),
                  onTap: onPickEnd,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPrn
                  ? 'Leave both blank for standing house stock.'
                  : 'Leave both blank for a standing prescription.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
            if (isPrn) ...[
              const SizedBox(height: 14),
              _Labeled(
                label: 'Shortest gap between doses (minutes)',
                hint:
                    '240 for a medicine prescribed no more often than four hourly.',
                child: TextField(
                  controller: draft.minGap,
                  style: _fieldTextStyle,
                  keyboardType: TextInputType.number,
                  decoration: _medFieldDecoration(
                    hint: 'Leave blank for no minimum',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: draft.controlled,
              onChanged: (v) {
                draft.controlled = v ?? false;
                onChanged();
              },
              title: const Text(
                'Controlled drug — a witness is required to chart a dose',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textHeading,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.secondaryTeal,
            ),
            _Labeled(
              label: 'Requires a check first',
              hint:
                  'A dose cannot be charted until this check has been recorded',
              child: DropdownButtonFormField<String?>(
                key: ValueKey(
                  'check-${draft.requiresCheckScheduleId}-${checks.length}',
                ),
                initialValue: draft.requiresCheckScheduleId,
                isExpanded: true,
                style: _fieldTextStyle,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
                decoration: _medFieldDecoration(),
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
            ),
          ],
        ),
      ),
    );
  }
}
