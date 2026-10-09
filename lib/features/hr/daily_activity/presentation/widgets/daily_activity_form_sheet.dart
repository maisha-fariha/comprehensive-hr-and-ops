import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_activity.dart';
import '../controllers/daily_activity_controller.dart';
import '../daily_activity_labels.dart';
import 'daily_activity_common.dart';
import 'daily_activity_person_picker.dart';
import '../../../../../core/media/app_file_picker.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Picks one document; returns the file and its size in bytes.
typedef DailyActivityFilePicker = Future<(DailyActivityLocalFile, int)?> Function();

const _maxUploadBytes = 10 * 1024 * 1024;

Future<(DailyActivityLocalFile, int)?> _pickWithFilePicker() async {
  final picked = await AppFilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
  );
  final file = picked?.files.singleOrNull;
  final path = file?.path;
  if (file == null || path == null) return null;
  return (DailyActivityLocalFile(path: path, name: file.name), file.size);
}

/// Web "Add Daily Activity" / "Edit Daily Activity". Resolves to true on save.
Future<bool?> showDailyActivityFormSheet(
  BuildContext context, {
  required DailyActivityController controller,
  DailyActivity? editing,
  DailyActivityFilePicker? pickFile,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => DailyActivityFormSheet(
      controller: controller,
      editing: editing,
      pickFile: pickFile,
    ),
  );
}

class DailyActivityFormSheet extends StatefulWidget {
  final DailyActivityController controller;
  final DailyActivity? editing;
  final DailyActivityFilePicker? pickFile;

  const DailyActivityFormSheet({
    super.key,
    required this.controller,
    this.editing,
    this.pickFile,
  });

  @override
  State<DailyActivityFormSheet> createState() => _DailyActivityFormSheetState();
}

class _DailyActivityFormSheetState extends State<DailyActivityFormSheet> {
  final _description = TextEditingController();
  final _notes = TextEditingController();
  String? _clientId;
  String _type = 'care_activity';
  String _status = 'completed';
  String? _staffId;
  late DateTime _date;
  TimeOfDay? _time;
  DailyActivityLocalFile? _file;
  String? _fileError;
  Map<String, String> _errors = const {};
  String? _banner;
  bool _saving = false;
  late final String _initial;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.editing;
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    if (a != null) {
      _clientId = a.clientId;
      _type = a.activityType;
      _status = a.status.isEmpty ? 'completed' : a.status;
      _description.text = a.description ?? '';
      _notes.text = a.notes ?? '';
      _staffId = a.recordedByStaffId;
      _date = DateTime.tryParse(a.activityDate) ?? _date;
      final at = a.occurredAt?.toLocal();
      if (at != null) _time = TimeOfDay(hour: at.hour, minute: at.minute);
    }
    _initial = _snapshot;
  }

  @override
  void dispose() {
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  String get _snapshot => [
        _clientId,
        _type,
        _status,
        _description.text,
        _notes.text,
        _staffId,
        DailyActivityLabels.ymd(_date),
        _time?.hour,
        _time?.minute,
        _file?.path,
      ].join('|');

  bool get _dirty => _snapshot != _initial;

  Future<void> _requestClose() async {
    if (!_dirty) {
      Navigator.of(context).pop(false);
      return;
    }
    final discard = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Discard unsaved changes?',
          style: handoverText(dialogContext, 16, weight: FontWeight.w600),
        ),
        content: Text(
          "You have unsaved edits on this form. If you leave now, they'll be lost.",
          style: handoverText(dialogContext, 13, color: AppColors.textMuted),
        ),
        actions: [
          HandoverButton(
            label: 'Keep editing',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          DailyActivityDangerButton(
            key: const ValueKey('daily-activity-discard'),
            label: 'Discard',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  Future<void> _pickFile() async {
    final picked = await (widget.pickFile ?? _pickWithFilePicker)();
    if (picked == null || !mounted) return;
    final (file, size) = picked;
    setState(() {
      if (size > _maxUploadBytes) {
        _fileError = '"${file.name}" exceeds the 10MB limit';
        return;
      }
      _fileError = null;
      _file = file;
    });
  }

  Future<void> _submit() async {
    final errors = <String, String>{
      if (_clientId == null || _clientId!.isEmpty) 'client': 'Select a resident',
      if (_type.isEmpty) 'type': 'Activity type is required',
      if (_status.isEmpty) 'status': 'Say how it went',
      if (_description.text.trim().isEmpty) 'description': 'Say what happened',
    };
    setState(() {
      _errors = errors;
      _banner = null;
    });
    if (errors.isNotEmpty) return;

    final t = _time;
    final draft = DailyActivityDraft(
      clientId: _clientId!,
      activityDate: DailyActivityLabels.ymd(_date),
      activityType: _type,
      status: _status,
      description: _description.text,
      notes: _notes.text,
      occurredAt: t == null
          ? null
          : DateTime(_date.year, _date.month, _date.day, t.hour, t.minute),
      recordedByStaffId: _staffId,
    );
    setState(() => _saving = true);
    final error = await widget.controller.save(
      draft,
      file: _file,
      editing: widget.editing,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _banner = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    const gap = SizedBox(height: 18);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.94,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 14,
                    ),
                    children: [
                      if (_banner != null) ...[
                        Container(
                          key: const ValueKey('daily-activity-form-error'),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.criticalBackgroundSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.criticalRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: AppColors.criticalRed,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _banner!,
                                  style: handoverText(
                                    context,
                                    12.5,
                                    color: AppColors.criticalRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        gap,
                      ],
                      DailyActivityPersonPicker(
                        key: const ValueKey('daily-activity-form-resident'),
                        label: 'Select Resident',
                        required: true,
                        options: c.clients,
                        value: _clientId,
                        error: _errors['client'],
                        onSelect: (o) => setState(() => _clientId = o?.id),
                      ),
                      gap,
                      _select(
                        context,
                        key: 'daily-activity-form-type',
                        label: 'Activity Type',
                        placeholder: 'Select activity type',
                        options: DailyActivityLabels.types,
                        value: _type,
                        error: _errors['type'],
                        onChanged: (v) => _type = v,
                      ),
                      gap,
                      _select(
                        context,
                        key: 'daily-activity-form-status',
                        label: 'How it went',
                        placeholder: 'Select',
                        options: DailyActivityLabels.statuses,
                        value: _status,
                        helper: 'A refusal or a partial is the one somebody reads',
                        error: _errors['status'],
                        onChanged: (v) => _status = v,
                      ),
                      gap,
                      _area(
                        context,
                        key: 'daily-activity-form-description',
                        label: 'Activity Description',
                        required: true,
                        controller: _description,
                        placeholder:
                            'Describe the activity performed or observation recorded...',
                        error: _errors['description'],
                      ),
                      gap,
                      _area(
                        context,
                        key: 'daily-activity-form-notes',
                        label: 'Additional Notes (Optional)',
                        controller: _notes,
                        placeholder: 'Add additional observations or comments...',
                      ),
                      gap,
                      _upload(context),
                      gap,
                      DailyActivityPersonPicker(
                        key: const ValueKey('daily-activity-form-staff'),
                        label: 'Recorded by',
                        options: c.staff,
                        value: _staffId,
                        onSelect: (o) => setState(() => _staffId = o?.id),
                      ),
                      gap,
                      _dateField(context),
                      gap,
                      _timeField(context),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              size: 20,
              color: AppColors.surfaceWhite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit Daily Activity' : 'Add Daily Activity',
                  style: handoverText(context, 16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Separate from the daily log — this is what they did, not how care went.',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : _requestClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        children: [
          HandoverButton(
            key: const ValueKey('daily-activity-form-cancel'),
            label: 'Cancel',
            onPressed: _saving ? null : _requestClose,
          ),
          HandoverButton(
            key: const ValueKey('daily-activity-form-save'),
            label: _saving
                ? 'Saving…'
                : _isEdit
                    ? 'Save Changes'
                    : 'Save Activity',
            filled: true,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String label, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
            ],
          ),
          style: handoverText(context, 13, weight: FontWeight.w500),
        ),
      );

  Widget _hint(BuildContext context, String? helper, String? error) {
    final text = error ?? helper;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        text,
        style: handoverText(
          context,
          12,
          color: error == null ? AppColors.textMuted : AppColors.criticalRed,
        ),
      ),
    );
  }

  Widget _box(
    BuildContext context, {
    required Key key,
    required String text,
    required bool empty,
    required IconData icon,
    required VoidCallback onTap,
    String? error,
    Widget? trailing,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: error == null ? AppColors.searchBorder : AppColors.criticalRed,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: handoverText(
                  context,
                  13.5,
                  color: empty ? AppColors.textMuted : AppColors.textHeading,
                ),
              ),
            ),
            ?trailing,
            Icon(icon, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _select(
    BuildContext context, {
    required String key,
    required String label,
    required String placeholder,
    required List<(String, String)> options,
    required String value,
    required ValueChanged<String> onChanged,
    String? helper,
    String? error,
  }) {
    final current = options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull ??
        (value.isEmpty ? null : DailyActivityLabels.humanise(value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, label, required: true),
        _box(
          context,
          key: ValueKey(key),
          text: current ?? placeholder,
          empty: current == null,
          icon: Icons.keyboard_arrow_down_rounded,
          error: error,
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: label,
              options: options,
              selected: value,
            );
            if (picked != null) setState(() => onChanged(picked));
          },
        ),
        _hint(context, helper, error),
      ],
    );
  }

  Widget _area(
    BuildContext context, {
    required String key,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool required = false,
    String? error,
  }) {
    final border = error == null ? AppColors.searchBorder : AppColors.criticalRed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, label, required: required),
        TextField(
          key: ValueKey(key),
          controller: controller,
          minLines: 3,
          maxLines: 7,
          onChanged: (_) => setState(() {}),
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        _hint(context, null, error),
      ],
    );
  }

  Widget _upload(BuildContext context) {
    final file = _file;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Upload Document (Optional)'),
        InkWell(
          key: const ValueKey('daily-activity-form-upload'),
          onTap: _saving ? null : _pickFile,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _fileError == null ? AppColors.searchBorder : AppColors.criticalRed,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.quickActionCreateShiftBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.upload_file_outlined,
                    size: 20,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Click to upload ',
                    children: [
                      TextSpan(
                        text: 'or drag & drop',
                        style: handoverText(context, 14, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: handoverText(context, 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, DOC, JPG or PNG · up to 15MB',
                  textAlign: TextAlign.center,
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        if (file != null)
          Container(
            key: const ValueKey('daily-activity-form-file'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: handoverText(context, 13),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove file',
                  visualDensity: VisualDensity.compact,
                  onPressed: _saving ? null : () => setState(() => _file = null),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        _hint(context, null, _fileError),
      ],
    );
  }

  Widget _dateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Date', required: true),
        _box(
          context,
          key: const ValueKey('daily-activity-form-date'),
          text: WebFormat.date(_date),
          empty: false,
          icon: Icons.calendar_today_outlined,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
      ],
    );
  }

  Widget _timeField(BuildContext context) {
    final t = _time;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(context, 'Time'),
        _box(
          context,
          key: const ValueKey('daily-activity-form-time'),
          text: t == null
              ? '--:--'
              : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          empty: t == null,
          icon: Icons.access_time_rounded,
          trailing: t == null
              ? null
              : IconButton(
                  tooltip: 'Clear time',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 20),
                  onPressed: () => setState(() => _time = null),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _time ?? TimeOfDay.now(),
            );
            if (picked != null) setState(() => _time = picked);
          },
        ),
        _hint(context, 'Optional — without it the record is placed to the day', null),
      ],
    );
  }
}
