import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../recurring_checks/presentation/widgets/check_common.dart';
import '../../domain/entities/daily_log.dart';
import '../controllers/daily_logs_controller.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';
import 'entry_sheets.dart';

typedef DailyLogFilePicker = Future<List<(String path, String name)>> Function();

Future<List<(String, String)>> _pickWithFilePicker() async {
  final picked = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: const [
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', //
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'txt',
    ],
  );
  return [
    for (final f in picked?.files ?? const <PlatformFile>[])
      if (f.path case final path? when path.isNotEmpty) (path, f.name),
  ];
}

/// Web "New Log Entry": Context, Care Details and Notes & Checklist.
Future<void> showNewLogEntrySheet(
  BuildContext context, {
  required DailyLogsController controller,
  DailyLogFilePicker? pickFiles,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NewLogEntrySheet(
        controller: controller,
        clientId: controller.clientId.value,
        clientName: controller.clientName,
        residenceId: controller.residenceId.value,
        residenceName: controller.residenceName,
        logDate: controller.logDate.value,
        pickFiles: pickFiles ?? _pickWithFilePicker,
      ),
    );

enum _Step { context, careDetails, notesChecklist }

const _steps = [
  (_Step.context, 'Context', 'Who this is about, and when', Icons.home_outlined),
  (_Step.careDetails, 'Care Details', 'What happened, and how they were', Icons.favorite_border_rounded),
  (_Step.notesChecklist, 'Notes & Checklist', 'Checks, attachments and flags', Icons.check_box_outlined),
];

const _fieldStep = {
  'body': _Step.careDetails,
  'outingNotes': _Step.careDetails,
  'flagCategory': _Step.notesChecklist,
  'flagNote': _Step.notesChecklist,
};

class NewLogEntrySheet extends StatefulWidget {
  final DailyLogsController controller;
  final String clientId;
  final String clientName;
  final String residenceId;
  final String residenceName;
  final String logDate;
  final DailyLogFilePicker pickFiles;

  const NewLogEntrySheet({
    super.key,
    required this.controller,
    required this.clientId,
    required this.clientName,
    required this.residenceId,
    required this.residenceName,
    required this.logDate,
    required this.pickFiles,
  });

  /// Now for today, otherwise midday on [logDate].
  static DateTime defaultOccurredAt(String logDate, {DateTime? now}) {
    final n = now ?? DateTime.now();
    if (logDate == DailyLogsController.dayKey(n)) return n;
    final d = DateTime.tryParse(logDate) ?? n;
    return DateTime(d.year, d.month, d.day, 12);
  }

  @override
  State<NewLogEntrySheet> createState() => _NewLogEntrySheetState();
}

class _NewLogEntrySheetState extends State<NewLogEntrySheet> {
  _Step _step = _Step.context;

  late DateTime? _occurredAt = NewLogEntrySheet.defaultOccurredAt(widget.logDate);
  String _shift = '';
  String _logType = '';
  final _body = TextEditingController();
  String _mood = '';
  String _sleep = '';
  String _hygiene = '';
  final _meals = TextEditingController();
  final _activities = TextEditingController();
  bool _outing = false;
  final _outingNotes = TextEditingController();
  final _behaviorNotes = TextEditingController();
  final _appointmentNotes = TextEditingController();
  bool _wellness = false;
  bool _bed = false;
  DateTime? _remindAt;
  final List<DailyLogUpload> _attachments = [];
  bool _uploading = false;
  String? _uploadError;
  bool _flag = false;
  String _flagCategory = '';
  final _flagNote = TextEditingController();

  Map<String, String> _errors = {};
  String? _formError;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _body,
      _meals,
      _activities,
      _outingNotes,
      _behaviorNotes,
      _appointmentNotes,
      _flagNote,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _complete(_Step step) => switch (step) {
        _Step.context => _occurredAt != null && _shift.isNotEmpty,
        _Step.careDetails => _body.text.isNotEmpty,
        _Step.notesChecklist => _behaviorNotes.text.isNotEmpty && _wellness && _bed,
      };

  Map<String, String> _validate() => {
        if (_body.text.trim().isEmpty) 'body': 'Write what happened',
        if (_outing && _outingNotes.text.trim().isEmpty)
          'outingNotes': 'Say where they went — the switch on its own records nothing',
        if (_flag && _flagCategory.isEmpty) 'flagCategory': 'Say what kind of concern this is',
        if (_flag && _flagNote.text.trim().isEmpty) 'flagNote': 'Say what needs attention',
      };

  Map<String, dynamic> _requestBody() {
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final observations = <String, dynamic>{
      if (_mood.isNotEmpty) 'mood': _mood,
      if (_sleep.isNotEmpty) 'sleep': _sleep,
      if (_hygiene.isNotEmpty) 'hygiene': _hygiene,
      'meals': ?text(_meals),
      'activities': ?text(_activities),
      'outingNotes': ?text(_outingNotes),
      'behaviorNotes': ?text(_behaviorNotes),
      'appointmentNotes': ?text(_appointmentNotes),
    };
    final occurred = _occurredAt ?? NewLogEntrySheet.defaultOccurredAt(widget.logDate);
    return {
      'clientId': widget.clientId,
      'residenceId': widget.residenceId,
      'logDate': widget.logDate,
      'body': _body.text.trim(),
      'occurredAt': occurred.toUtc().toIso8601String(),
      if (_shift.isNotEmpty) 'shift': _shift,
      if (_logType.isNotEmpty) 'logType': _logType,
      if (observations.isNotEmpty || _outing)
        'observations': {...observations, 'communityOuting': _outing},
      'wellnessCheckCompleted': _wellness,
      'bedCheckCompleted': _bed,
      if (_remindAt case final r?) 'remindAt': r.toUtc().toIso8601String(),
      if (_attachments.isNotEmpty)
        'attachments': [
          for (final a in _attachments) {'fileUrl': a.fileUrl, 'fileType': ?a.fileType},
        ],
      if (_flag && _flagCategory.isNotEmpty)
        'flagForAttention': {'category': _flagCategory, 'note': ?text(_flagNote)},
    };
  }

  Future<void> _save() async {
    final errors = _validate();
    setState(() {
      _errors = errors;
      _formError = null;
    });
    if (errors.isNotEmpty) {
      final owners = errors.keys.map((k) => _fieldStep[k]).toSet();
      setState(() => _step = _Step.values.firstWhere(owners.contains));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.createEntry(_requestBody());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _formError = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addFiles() async {
    final files = await widget.pickFiles();
    if (files.isEmpty || !mounted) return;
    setState(() {
      _uploadError = null;
      _uploading = true;
    });
    try {
      final uploaded = await Future.wait([
        for (final (path, name) in files) widget.controller.upload(path, name),
      ]);
      if (mounted) setState(() => _attachments.addAll(uploaded));
    } catch (e) {
      if (mounted) setState(() => _uploadError = '$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _select(
    String title,
    List<(String, String)> options,
    String current,
    ValueChanged<String> set,
  ) async {
    final picked = await pickDailyLogOption(context, title, options, current);
    if (picked != null) setState(() => set(picked));
  }

  @override
  Widget build(BuildContext context) {
    final index = _step.index;
    final last = index == _steps.length - 1;
    return DailyLogSheet(
      key: const ValueKey('dl-new-entry'),
      icon: Icons.home_outlined,
      title: 'New Log Entry',
      description: 'Care documentation for ${widget.clientName} on ${widget.logDate}.',
      footerLeading: Text.rich(
        const TextSpan(
          children: [
            TextSpan(text: '*', style: TextStyle(color: AppColors.criticalRed)),
            TextSpan(text: ' Required fields'),
          ],
        ),
        style: handoverText(context, 12, color: AppColors.textMuted),
      ),
      footer: [
        HandoverButton(
          key: const ValueKey('dl-new-cancel'),
          label: 'Cancel',
          compact: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (index > 0)
          HandoverButton(
            key: const ValueKey('dl-new-back'),
            label: 'Back',
            compact: true,
            onPressed: () => setState(() => _step = _Step.values[index - 1]),
          ),
        if (!last)
          HandoverButton(
            key: const ValueKey('dl-new-next'),
            label: 'Next',
            filled: true,
            compact: true,
            onPressed: () => setState(() => _step = _Step.values[index + 1]),
          )
        else
          HandoverButton(
            key: const ValueKey('dl-new-save'),
            label: _saving ? 'Saving…' : 'Save Entry',
            filled: true,
            compact: true,
            onPressed: _saving ? null : _save,
          ),
      ],
      children: [
        _workflow(context),
        if (_formError != null) DailyLogFormError(_formError!),
        ...switch (_step) {
          _Step.context => _contextStep(context),
          _Step.careDetails => _careStep(context),
          _Step.notesChecklist => _notesStep(context),
        },
        _summary(context),
      ],
    );
  }

  Widget _workflow(BuildContext context) {
    final done = _steps.where((s) => _complete(s.$1)).length;
    final percent = (done / _steps.length * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DAILY LOG WORKFLOW',
          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        for (final (step, label, description, icon) in _steps)
          _StepTile(
            key: ValueKey('dl-step-${step.name}'),
            label: label,
            description: description,
            icon: icon,
            active: step == _step,
            completed: _complete(step),
            onTap: () => setState(() => _step = step),
          ),
        const SizedBox(height: 8),
        Container(
          key: const ValueKey('dl-completion'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'COMPLETION',
                style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Step $done of ${_steps.length}',
                      style: handoverText(context, 13, weight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$percent% complete',
                    style: handoverText(context, 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: done / _steps.length,
                  minHeight: 6,
                  color: AppColors.secondaryTeal,
                  backgroundColor: AppColors.filterButtonBackground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heading(BuildContext context, String title, String description) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: handoverText(context, 16, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(description, style: handoverText(context, 13, color: AppColors.textMuted)),
        ],
      );

  Widget _readOnly(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckFieldLabel(label),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(value.isEmpty ? '—' : value, style: handoverText(context, 13)),
          ),
        ],
      );

  List<Widget> _contextStep(BuildContext context) => [
        _heading(
          context,
          'Context',
          'The resident and day this entry belongs to, and when it happened.',
        ),
        _readOnly(context, 'Residence', widget.residenceName),
        _readOnly(context, 'Resident', widget.clientName),
        _readOnly(context, 'Log date', widget.logDate),
        CheckPickerField(
          key: const ValueKey('dl-new-occurred'),
          label: 'Occurred at',
          value: DailyLogLabels.dateTime(_occurredAt),
          icon: Icons.schedule_rounded,
          helper: 'Defaults to now for today, and midday for a day being filled in.',
          onTap: () async {
            final picked = await pickDailyLogDateTime(context, _occurredAt);
            if (picked != null) setState(() => _occurredAt = picked);
          },
        ),
        DailyLogSelect(
          key: const ValueKey('dl-new-shift'),
          label: 'Shift',
          value: DailyLogLabels.labelOf(DailyLogLabels.shifts, _shift),
          placeholder: 'Which shift wrote this?',
          onTap: () => _select('Shift', DailyLogLabels.shifts, _shift, (v) => _shift = v),
        ),
        DailyLogSelect(
          key: const ValueKey('dl-new-log-type'),
          label: 'Log type',
          value: DailyLogLabels.labelOf(DailyLogLabels.logTypes, _logType),
          placeholder: 'What kind of note is this?',
          onTap: () => _select('Log type', DailyLogLabels.logTypes, _logType, (v) => _logType = v),
        ),
      ];

  Widget _area(
    String key,
    String label,
    TextEditingController controller,
    String placeholder, {
    bool required = false,
    String? error,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HandoverTextArea(
            key: ValueKey(key),
            label: label,
            required: required,
            controller: controller,
            placeholder: placeholder,
            onChanged: (_) => setState(() {}),
          ),
          if (error != null) DailyLogFieldError(error),
        ],
      );

  List<Widget> _careStep(BuildContext context) => [
        _heading(
          context,
          'Care Details',
          'Record what happened and how the resident was through the shift.',
        ),
        _area(
          'dl-new-body',
          'What happened',
          _body,
          'e.g. Ate a full breakfast and joined the morning music session.',
          required: true,
          error: _errors['body'],
        ),
        DailyLogSelect(
          key: const ValueKey('dl-new-mood'),
          label: 'Mood',
          value: DailyLogLabels.labelOf(DailyLogLabels.moods, _mood),
          placeholder: 'Select mood',
          onTap: () => _select('Mood', DailyLogLabels.moods, _mood, (v) => _mood = v),
        ),
        DailyLogSelect(
          key: const ValueKey('dl-new-sleep'),
          label: 'Sleep',
          value: DailyLogLabels.labelOf(DailyLogLabels.sleeps, _sleep),
          placeholder: 'Select sleep quality',
          onTap: () => _select('Sleep', DailyLogLabels.sleeps, _sleep, (v) => _sleep = v),
        ),
        DailyLogSelect(
          key: const ValueKey('dl-new-hygiene'),
          label: 'Hygiene',
          value: DailyLogLabels.labelOf(DailyLogLabels.hygiene, _hygiene),
          placeholder: 'Select support given',
          onTap: () => _select('Hygiene', DailyLogLabels.hygiene, _hygiene, (v) => _hygiene = v),
        ),
        CheckInput(
          key: const ValueKey('dl-new-meals'),
          label: 'Meals',
          controller: _meals,
          placeholder: 'e.g. Breakfast completed, lunch partial',
        ),
        _area(
          'dl-new-activities',
          'Activities',
          _activities,
          'Describe activities completed during the shift…',
        ),
        CheckSwitchTile(
          key: const ValueKey('dl-new-outing'),
          label: 'Community outing',
          description: 'The resident went out of the home today.',
          value: _outing,
          onChanged: (v) => setState(() => _outing = v),
        ),
        if (_outing)
          _area(
            'dl-new-outing-notes',
            'Outing notes',
            _outingNotes,
            'Where they went, who went with them, how it went…',
            required: true,
            error: _errors['outingNotes'],
          ),
      ];

  Widget _checkbox(String key, String label, bool value, ValueChanged<bool> set) => InkWell(
        key: ValueKey(key),
        onTap: () => setState(() => set(!value)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              activeColor: AppColors.secondaryTeal,
              onChanged: (v) => setState(() => set(v ?? false)),
            ),
            Text(label, style: handoverText(context, 13)),
          ],
        ),
      );

  List<Widget> _notesStep(BuildContext context) => [
        _heading(
          context,
          'Notes & Checklist',
          'Observations, the checks this shift completed, and anything to pick up later.',
        ),
        _area(
          'dl-new-behaviour',
          'Behaviour notes',
          _behaviorNotes,
          'Anything about how the resident presented…',
        ),
        _area(
          'dl-new-appointments',
          'Appointment notes',
          _appointmentNotes,
          'Appointments attended, booked, or missed…',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CheckFieldLabel('Shift checks'),
            Wrap(
              children: [
                _checkbox('dl-new-wellness', 'Wellness check completed', _wellness, (v) => _wellness = v),
                _checkbox('dl-new-bed', 'Bed check completed', _bed, (v) => _bed = v),
              ],
            ),
          ],
        ),
        CheckPickerField(
          key: const ValueKey('dl-new-remind'),
          label: 'Remind me at',
          value: DailyLogLabels.dateTime(_remindAt),
          icon: Icons.alarm_rounded,
          helper: 'A time, not a task — “check the dressing at 14:00”. '
              'Work that needs an owner belongs in Tasks.',
          onTap: () async {
            final picked = await pickDailyLogDateTime(context, _remindAt);
            if (picked != null) setState(() => _remindAt = picked);
          },
          onClear: () => setState(() => _remindAt = null),
        ),
        _attachmentsField(context),
        CheckSwitchTile(
          key: const ValueKey('dl-new-flag'),
          label: 'Flag for attention',
          description: 'Raises this on the Priority Notes board until somebody resolves it.',
          value: _flag,
          activeColor: AppColors.urgentAmber,
          onChanged: (v) => setState(() => _flag = v),
        ),
        if (_flag) ...[
          DailyLogSelect(
            key: const ValueKey('dl-new-flag-category'),
            label: 'Category',
            required: true,
            value: DailyLogLabels.labelOf(DailyLogLabels.flagCategories, _flagCategory),
            placeholder: 'What kind of concern is this?',
            error: _errors['flagCategory'],
            onTap: () => _select(
              'Category',
              DailyLogLabels.flagCategories,
              _flagCategory,
              (v) => _flagCategory = v,
            ),
          ),
          _area(
            'dl-new-flag-note',
            'What needs attention',
            _flagNote,
            'The line somebody reads on the board before deciding to act…',
            required: true,
            error: _errors['flagNote'],
          ),
        ],
      ];

  Widget _attachmentsField(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CheckFieldLabel('Attachments'),
          const SizedBox(height: 6),
          InkWell(
            key: const ValueKey('dl-new-attach'),
            onTap: _uploading ? null : _addFiles,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.upload_file_rounded, color: AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    'A photo, a letter, a chart. Image, PDF or document · up to 15MB each',
                    textAlign: TextAlign.center,
                    style: handoverText(context, 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (_uploading) ...[
            const SizedBox(height: 6),
            Text('Uploading…', style: handoverText(context, 12, color: AppColors.textMuted)),
          ],
          if (_uploadError != null) DailyLogFieldError(_uploadError!),
          for (var i = 0; i < _attachments.length; i++) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachments[i].fileName ?? _attachments[i].fileUrl.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(context, 13),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('dl-new-attach-remove-$i'),
                    tooltip: 'Remove ${_attachments[i].fileName ?? 'file'}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _attachments.removeAt(i)),
                    icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _summary(BuildContext context) {
    final checks = [if (_wellness) 'Wellness', if (_bed) 'Bed'].join(' · ');
    final category = DailyLogLabels.labelOf(DailyLogLabels.flagCategories, _flagCategory);
    return Container(
      key: const ValueKey('dl-entry-summary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ENTRY SUMMARY',
            style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          DailyLogDetail('Residence', widget.residenceName),
          const SizedBox(height: 10),
          DailyLogDetail('Resident', widget.clientName),
          const SizedBox(height: 10),
          DailyLogDetail('Log date', widget.logDate),
          const SizedBox(height: 10),
          DailyLogDetail('Shift', DailyLogLabels.labelOf(DailyLogLabels.shifts, _shift)),
          const SizedBox(height: 10),
          DailyLogDetail('Checks', checks.isEmpty ? 'None recorded' : checks),
          const SizedBox(height: 10),
          Text(
            'FLAG',
            style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: _flag
                ? DailyLogPill(
                    (category.isEmpty ? 'Category needed' : category).toUpperCase(),
                    tone: DailyLogTone.danger,
                  )
                : const DailyLogPill('NONE'),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool active;
  final bool completed;
  final VoidCallback onTap;

  const _StepTile({
    super.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = active
        ? (AppColors.primaryNavy, AppColors.surfaceWhite)
        : completed
            ? (const Color(0xFFE9F5EE), const Color(0xFF2E8C58))
            : (const Color(0xFFEEF1F5), const Color(0xFF6B7C93));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, size: 16, color: fg),
                ),
                if (completed && !active)
                  const Positioned(
                    top: -5,
                    right: -2,
                    child: CircleAvatar(
                      radius: 6.5,
                      backgroundColor: Color(0xFF3FA66D),
                      child: Icon(Icons.check_rounded, size: 9, color: AppColors.surfaceWhite),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: handoverText(
                      context,
                      13,
                      weight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? AppColors.primaryNavy : AppColors.textHeading,
                    ),
                  ),
                  Text(description, style: handoverText(context, 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
