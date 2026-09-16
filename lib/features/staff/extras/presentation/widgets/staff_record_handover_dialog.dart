import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/repositories/staff_extras_repository.dart';

/// Reference-matched "Record handover" modal.
class StaffRecordHandoverDialog extends StatefulWidget {
  const StaffRecordHandoverDialog({super.key});

  /// Returns `true` when a handover was saved (draft or submitted).
  static Future<bool?> show() {
    return Get.dialog<bool>(
      const StaffRecordHandoverDialog(),
      barrierDismissible: false,
    );
  }

  @override
  State<StaffRecordHandoverDialog> createState() =>
      _StaffRecordHandoverDialogState();
}

class _PendingJob {
  final String title;
  final String priority;

  const _PendingJob({required this.title, required this.priority});
}

class _StaffRecordHandoverDialogState extends State<StaffRecordHandoverDialog> {
  static const _priorities = <String>['normal', 'important', 'urgent'];
  static const _flagOptions = <({String? value, String label})>[
    (value: null, label: 'Not flagged'),
    (value: 'behaviour', label: 'Behaviour'),
    (value: 'medication', label: 'Medication'),
    (value: 'health', label: 'Health'),
    (value: 'safeguarding', label: 'Safeguarding'),
    (value: 'other', label: 'Other'),
  ];

  final _summaryController = TextEditingController();
  final _jobController = TextEditingController();

  late final AppApiClient _api;
  late final UserSession _session;
  late final StaffExtrasRepository _repository;

  List<({String id, String name})> _homes = const [];
  List<({String id, String name})> _clients = const [];
  final List<_PendingJob> _jobs = [];
  final List<({String id, String name})> _selectedClients = [];

  String? _residenceId;
  String _jobPriority = 'normal';
  String? _flagCategory;
  String? _residenceError;
  String? _summaryError;

  bool _loadingHomes = true;
  bool _loadingClients = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<AppApiClient>();
    _session = Get.find<UserSession>();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _loadHomes();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _loadHomes() async {
    final sessionId = _session.residenceId;
    final sessionName = _session.residenceName;
    final result = await _api.get(ApiEndpoints.residences, silent: true);
    if (!mounted) return;

    final homes = <({String id, String name})>[];
    result.when(
      success: (body) {
        for (final item in JsonCodec.unwrapList(body).whereType<Map>()) {
          final json = JsonCodec.asMap(item);
          final id = JsonCodec.string(json['id']);
          if (id == null || id.isEmpty) continue;
          homes.add((
            id: id,
            name: JsonCodec.stringOr(json['name'], 'Residence'),
          ));
        }
      },
      failure: (_) {},
    );

    if (homes.isEmpty && sessionId != null && sessionId.isNotEmpty) {
      homes.add((
        id: sessionId,
        name: (sessionName != null && sessionName.isNotEmpty)
            ? sessionName
            : 'My residence',
      ));
    }

    final selected = homes.any((h) => h.id == sessionId)
        ? sessionId
        : (homes.length == 1 ? homes.first.id : null);

    setState(() {
      _homes = homes;
      _residenceId = selected;
      _loadingHomes = false;
    });

    if (selected != null) {
      await _loadClients(selected);
    }
  }

  Future<void> _onResidenceChanged(String? residenceId) async {
    setState(() {
      _residenceId = residenceId;
      _residenceError = null;
      _clients = const [];
      _selectedClients.clear();
    });
    if (residenceId == null || residenceId.isEmpty) return;
    await _loadClients(residenceId);
  }

  Future<void> _loadClients(String residenceId) async {
    setState(() => _loadingClients = true);
    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        'residenceId': residenceId,
        'page': 1,
        'limit': 50,
      },
      silent: true,
    );
    if (!mounted) return;

    final clients = <({String id, String name})>[];
    result.when(
      success: (body) {
        for (final item in JsonCodec.unwrapList(body).whereType<Map>()) {
          final json = JsonCodec.asMap(item);
          final id = JsonCodec.string(json['id']);
          if (id == null || id.isEmpty) continue;
          final name = JsonCodec.stringOr(
            json['name'] ??
                [
                  JsonCodec.stringOr(json['firstName'], ''),
                  JsonCodec.stringOr(json['lastName'], ''),
                ].where((p) => p.isNotEmpty).join(' '),
            'Client',
          );
          clients.add((id: id, name: name));
        }
      },
      failure: (_) {},
    );

    setState(() {
      _clients = clients;
      _loadingClients = false;
    });
  }

  void _addJob() {
    final title = _jobController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _jobs.add(_PendingJob(title: title, priority: _jobPriority));
      _jobController.clear();
    });
  }

  void _addClient(String? clientId) {
    if (clientId == null) return;
    final match = _clients.where((c) => c.id == clientId);
    if (match.isEmpty) return;
    final client = match.first;
    if (_selectedClients.any((c) => c.id == client.id)) return;
    setState(() => _selectedClients.add(client));
  }

  Future<void> _save({required bool submit}) async {
    final residenceId = _residenceId;
    final summary = _summaryController.text.trim();
    setState(() {
      _residenceError =
          (residenceId == null || residenceId.isEmpty) ? 'Choose a residence' : null;
      _summaryError = summary.isEmpty ? 'Enter a summary' : null;
    });
    if (_residenceError != null || _summaryError != null) return;

    // Include the typed job even if the user forgot to press Add.
    final jobs = List<_PendingJob>.from(_jobs);
    final pendingTitle = _jobController.text.trim();
    if (pendingTitle.isNotEmpty) {
      jobs.add(_PendingJob(title: pendingTitle, priority: _jobPriority));
    }

    setState(() => _submitting = true);
    final result = await _repository.createHandover(
      residenceId: residenceId!,
      summary: summary,
      submit: submit,
      fromShiftId: null,
      toShiftId: null,
      pendingActions: [
        for (final job in jobs)
          {'title': job.title, 'priority': job.priority},
      ],
      clientUpdates: [
        for (final client in _selectedClients)
          {
            'clientId': client.id,
            'status': _flagCategory == null ? 'stable' : 'needs_attention',
          },
      ],
      flagForAttention: _flagCategory == null
          ? null
          : {'category': _flagCategory, 'note': ''},
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (_) {
        Get.back(result: true);
        Get.snackbar(
          submit ? 'Submitted' : 'Draft saved',
          submit ? 'Handover sent to the next shift.' : 'You can finish this later.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: submit
            ? 'Could not submit handover'
            : 'Could not save draft',
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    String? errorText,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: enabled ? AppColors.textMuted : AppColors.textFaint,
      ),
      errorText: errorText,
      filled: true,
      fillColor: enabled
          ? AppColors.surfaceWhite
          : AppColors.filterButtonBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.criticalRed),
      ),
    );
  }

  Widget _requiredLabel(String text, {bool enabled = true}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: enabled ? AppColors.textHeading : AppColors.textMuted,
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.criticalRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionalLabel(String text, {bool enabled = true}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: enabled ? AppColors.textHeading : AppColors.textMuted,
      ),
    );
  }

  Widget _helper(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: AppColors.textMuted,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _priorityPill(String value) {
    final selected = _jobPriority == value;
    final label = value[0].toUpperCase() + value.substring(1);
    return InkWell(
      onTap: _submitting ? null : () => setState(() => _jobPriority = value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE7F4F1)
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.secondaryTeal
                : AppColors.searchBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected
                ? AppColors.secondaryTealDark
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getResponsiveWidth(context, 440)
        .clamp(300.0, 480.0);
    final dialogHeight = (MediaQuery.sizeOf(context).height * 0.86)
        .clamp(420.0, 720.0);
    final hasResidence = _residenceId != null && _residenceId!.isNotEmpty;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(16, 20, 16, 20 + keyboardInset * 0.2),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: dialogHeight,
        ),
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: dialogHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.edit_note_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record handover',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: 16.5,
                                color: AppColors.textHeading,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'What the next shift needs to know before it starts.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w400,
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _submitting ? null : () => Get.back(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.searchBorder),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.dividerLight),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Residence'),
                        const SizedBox(height: 8),
                        if (_loadingHomes)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.secondaryTeal,
                                ),
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            key: ValueKey('residence-$_residenceId'),
                            initialValue: _residenceId,
                            isExpanded: true,
                            decoration: _fieldDecoration(
                              hint: 'Choose a residence',
                              errorText: _residenceError,
                            ),
                            hint: const Text(
                              'Choose a residence',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textMuted,
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.iconChevron,
                            ),
                            items: [
                              for (final home in _homes)
                                DropdownMenuItem(
                                  value: home.id,
                                  child: Text(
                                    home.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: _submitting
                                ? null
                                : (value) => _onResidenceChanged(value),
                          ),
                        _helper(
                          'You have no shifts of your own in the last day, so name the home.',
                        ),
                        const SizedBox(height: 16),
                        _optionalLabel(
                          'The shift you are handing over',
                          enabled: false,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: null,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            hint: 'Choose a residence above',
                            enabled: false,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.iconChevron,
                          ),
                          items: const [],
                          onChanged: null,
                        ),
                        _helper('Your own shifts from the last 24 hours.'),
                        const SizedBox(height: 16),
                        _optionalLabel(
                          'Handing over to',
                          enabled: false,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: null,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            hint: 'Choose a shift or a residence first',
                            enabled: false,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.iconChevron,
                          ),
                          items: const [],
                          onChanged: null,
                        ),
                        _helper(
                          'Without this it is announced to everyone in the house, and the outstanding jobs belong to nobody.',
                        ),
                        const SizedBox(height: 16),
                        _requiredLabel('Summary'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _summaryController,
                          enabled: !_submitting,
                          maxLines: 4,
                          minLines: 3,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textHeading,
                          ),
                          onChanged: (_) {
                            if (_summaryError != null) {
                              setState(() => _summaryError = null);
                            }
                          },
                          decoration: _fieldDecoration(
                            hint: 'How the shift went, what is outstanding...',
                            errorText: _summaryError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _optionalLabel('Outstanding jobs'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _jobController,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addJob(),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textHeading,
                          ),
                          decoration: _fieldDecoration(
                            hint: 'e.g. Monitor temperature',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final priority in _priorities)
                              _priorityPill(priority),
                            OutlinedButton.icon(
                              onPressed: _submitting ? null : _addJob,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text(
                                'Add',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textHeading,
                                side: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_jobs.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          for (final job in _jobs)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '• ${job.title}',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        color: AppColors.textBody,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.filterButtonBackground,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      job.priority,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _submitting
                                        ? null
                                        : () => setState(
                                              () => _jobs.remove(job),
                                            ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        _helper(
                          'Each becomes a task at that priority, assigned to the incoming shift if you name one.',
                        ),
                        const SizedBox(height: 16),
                        _optionalLabel('Client updates'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'clients-${_selectedClients.length}-${_clients.length}',
                          ),
                          initialValue: null,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            hint: hasResidence
                                ? (_loadingClients
                                    ? 'Loading clients…'
                                    : 'Choose a client')
                                : 'Choose a shift or residence first',
                            enabled: hasResidence && !_loadingClients,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.iconChevron,
                          ),
                          items: [
                            for (final client in _clients)
                              if (!_selectedClients
                                  .any((c) => c.id == client.id))
                                DropdownMenuItem(
                                  value: client.id,
                                  child: Text(
                                    client.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                ),
                          ],
                          onChanged: (!hasResidence ||
                                  _loadingClients ||
                                  _submitting)
                              ? null
                              : _addClient,
                        ),
                        if (_selectedClients.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final client in _selectedClients)
                                Chip(
                                  label: Text(
                                    client.name,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFFB4791C),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFFBF1E6),
                                  deleteIconColor: const Color(0xFFB4791C),
                                  onDeleted: _submitting
                                      ? null
                                      : () => setState(
                                            () => _selectedClients
                                                .removeWhere(
                                              (c) => c.id == client.id,
                                            ),
                                          ),
                                  side: BorderSide.none,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        _optionalLabel('Flag for attention'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          key: ValueKey('flag-$_flagCategory'),
                          initialValue: _flagCategory,
                          isExpanded: true,
                          decoration: _fieldDecoration(hint: 'Not flagged'),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.iconChevron,
                          ),
                          items: [
                            for (final option in _flagOptions)
                              DropdownMenuItem(
                                value: option.value,
                                child: Text(
                                  option.label,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.textHeading,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: _submitting
                              ? null
                              : (value) =>
                                  setState(() => _flagCategory = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.dividerLight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textHeading,
                            side: const BorderSide(
                              color: AppColors.searchBorder,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => _save(submit: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textHeading,
                            side: const BorderSide(
                              color: AppColors.searchBorder,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Save draft',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _submitting
                              ? null
                              : () => _save(submit: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            disabledBackgroundColor: AppColors.primaryNavy
                                .withValues(alpha: 0.55),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                              : const Text(
                                  'Submit handover',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
