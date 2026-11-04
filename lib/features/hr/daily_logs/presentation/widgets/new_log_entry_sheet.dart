import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../ai/domain/entities/ai_assist.dart';
import '../../../ai/presentation/widgets/ai_draft_sheet.dart';
import '../../../ai/presentation/widgets/ai_feature_sheets.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../recurring_checks/presentation/widgets/check_common.dart';
import '../../domain/entities/daily_log.dart';
import '../controllers/daily_logs_controller.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';
import 'entry_sheets.dart';
import 'tidy_my_note_sheet.dart';
import '../../../../../core/media/app_file_picker.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

typedef DailyLogFilePicker = Future<List<(String path, String name)>> Function();

Future<List<(String, String)>> _pickWithFilePicker() async {
  final picked = await AppFilePicker.pickFiles(
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

/// Web care-note slide-over: single panel (no stepped workflow).
Future<void> showNewLogEntrySheet(
  BuildContext context, {
  required DailyLogsController controller,
  DailyLogFilePicker? pickFiles,
}) =>
    showAppBottomSheet<void>(
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
        residenceId: controller.dayResidenceId ?? controller.residenceId.value,
        residenceName: controller.dayResidenceName.isNotEmpty
            ? controller.dayResidenceName
            : controller.residenceName,
        logDate: controller.logDate.value,
        pickFiles: pickFiles ?? _pickWithFilePicker,
      ),
    );

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
  late DateTime? _occurredAt =
      NewLogEntrySheet.defaultOccurredAt(widget.logDate);
  String _shift = '';
  String _logType = 'care_note';
  final _body = TextEditingController();
  bool _forNextShift = false;
  String _mood = '';
  String _sleep = '';
  String _hygiene = '';
  final _meals = TextEditingController();
  final _wellnessNotes = TextEditingController();
  final _activities = TextEditingController();
  bool _outing = false;
  final _outingNotes = TextEditingController();
  final _behaviorNotes = TextEditingController();
  final _appointmentNotes = TextEditingController();

  /// Web tri-state: true Done, false Not done, null Not said.
  bool? _wellness;
  bool? _bed;
  DateTime? _remindAt;
  final List<DailyLogUpload> _attachments = [];
  bool _uploading = false;
  String? _uploadError;
  bool _flag = false;
  String _flagCategory = '';
  final _flagNote = TextEditingController();
  bool? _aiEnabled;
  bool _moreOpen = false;

  Map<String, String> _errors = {};
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    aiDraftingEnabled().then((enabled) {
      if (mounted) setState(() => _aiEnabled = enabled);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _body,
      _meals,
      _wellnessNotes,
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

  Map<String, String> _validate() => {
        if (_body.text.trim().isEmpty) 'body': 'Write what happened',
        if (_outing && _outingNotes.text.trim().isEmpty)
          'outingNotes':
              'Say where they went — the switch on its own records nothing',
        if (_flag && _flagCategory.isEmpty)
          'flagCategory': 'Say what kind of concern this is',
        if (_flag && _flagNote.text.trim().isEmpty)
          'flagNote': 'Say what needs attention',
      };

  Map<String, dynamic> _requestBody() {
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final observations = <String, dynamic>{
      if (_mood.isNotEmpty) 'mood': _mood,
      if (_sleep.isNotEmpty) 'sleep': _sleep,
      if (_hygiene.isNotEmpty) 'hygiene': _hygiene,
      'meals': ?text(_meals),
      'wellness': ?text(_wellnessNotes),
      'activities': ?text(_activities),
      'outingNotes': ?text(_outingNotes),
      'behaviorNotes': ?text(_behaviorNotes),
      'appointmentNotes': ?text(_appointmentNotes),
    };
    final occurred =
        _occurredAt ?? NewLogEntrySheet.defaultOccurredAt(widget.logDate);
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
      // Nullable booleans — web default is "Not said" (null).
      'wellnessCheckCompleted': _wellness,
      'bedCheckCompleted': _bed,
      if (_remindAt case final r?) 'remindAt': r.toUtc().toIso8601String(),
      if (_attachments.isNotEmpty)
        'attachments': [
          for (final a in _attachments)
            {'fileUrl': a.fileUrl, 'fileType': ?a.fileType},
        ],
      if (_forNextShift) 'forNextShift': true,
      if (_flag && _flagCategory.isNotEmpty)
        'flagForAttention': {
          'category': _flagCategory,
          'note': ?text(_flagNote),
        },
    };
  }

  Future<void> _save() async {
    final errors = _validate();
    setState(() {
      _errors = errors;
      _formError = null;
      if (errors.containsKey('outingNotes') ||
          errors.containsKey('flagCategory') ||
          errors.containsKey('flagNote')) {
        _moreOpen = true;
      }
    });
    if (errors.isNotEmpty) return;
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

  Future<void> _tidyNote() async {
    final draft = await showTidyMyNoteSheet(
      context,
      clientId: widget.clientId,
      initialNotes: _body.text,
      logType: _logType,
      mood: _mood,
      sleep: _sleep,
      hygiene: _hygiene,
    );
    if (draft == null || !mounted) return;
    _applyAiDraft(draft);
  }

  void _applyAiDraft(AiDailyLogDraftEntry draft) {
    final obs = draft.observations;
    setState(() {
      _body.text = draft.body;
      if ((draft.logType ?? '').isNotEmpty) _logType = draft.logType!;
      if ((obs.mood ?? '').isNotEmpty) _mood = obs.mood!;
      if ((obs.sleep ?? '').isNotEmpty) _sleep = obs.sleep!;
      if ((obs.hygiene ?? '').isNotEmpty) _hygiene = obs.hygiene!;
      if ((obs.meals ?? '').isNotEmpty) _meals.text = obs.meals!;
      if ((obs.wellness ?? '').isNotEmpty) _wellnessNotes.text = obs.wellness!;
      if ((obs.activities ?? '').isNotEmpty) _activities.text = obs.activities!;
      if ((obs.behaviorNotes ?? '').isNotEmpty) {
        _behaviorNotes.text = obs.behaviorNotes!;
      }
      if ((obs.appointmentNotes ?? '').isNotEmpty) {
        _appointmentNotes.text = obs.appointmentNotes!;
      }
      if (draft.communityOuting != null) _outing = draft.communityOuting!;
      if ((draft.outingNotes ?? '').isNotEmpty && _outingNotes.text.isEmpty) {
        _outingNotes.text = draft.outingNotes!;
      }
      if (draft.wellnessCheckCompleted != null) {
        _wellness = draft.wellnessCheckCompleted;
      }
      if (draft.bedCheckCompleted != null) _bed = draft.bedCheckCompleted;
      if ((draft.shift ?? '').isNotEmpty && _shift.isEmpty) {
        _shift = draft.shift!;
      }
      if ((draft.time ?? '').isNotEmpty) {
        final stamp = DateTime.tryParse('${widget.logDate}T${draft.time}');
        if (stamp != null) _occurredAt = stamp;
      }
      if ((draft.remindAt ?? '').isNotEmpty && _remindAt == null) {
        _remindAt = DateTime.tryParse('${widget.logDate}T${draft.remindAt}') ??
            DateTime.tryParse(draft.remindAt!);
      }
      final flag = draft.flag;
      if (flag != null && flag.category.isNotEmpty) {
        _flag = true;
        _forNextShift = true;
        _flagCategory = flag.category;
        if (flag.note.isNotEmpty) _flagNote.text = flag.note;
      }
      _moreOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DailyLogSheet(
      key: const ValueKey('dl-new-entry'),
      icon: Icons.edit_note_rounded,
      title: 'Care note · ${widget.clientName}',
      description: widget.residenceName.isEmpty
          ? 'What happened on ${widget.logDate}.'
          : widget.residenceName,
      footer: [
        HandoverButton(
          key: const ValueKey('dl-new-cancel'),
          label: 'Cancel',
          compact: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        HandoverButton(
          key: const ValueKey('dl-new-save'),
          label: _saving ? 'Saving…' : 'Save note',
          filled: true,
          compact: true,
          onPressed: _saving ? null : _save,
        ),
      ],
      children: [
        if (_formError != null) DailyLogFormError(_formError!),
        if (_aiEnabled == true) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: AiAssistButton(
              buttonKey: const ValueKey('dl-tidy-my-note'),
              label: 'Tidy my note',
              onPressed: _tidyNote,
            ),
          ),
        ],
        _area(
          'dl-new-body',
          'What happened',
          _body,
          'e.g. Ate half of lunch. Said their tummy hurt — quiet for the afternoon.',
          required: true,
          error: _errors['body'],
        ),
        _kindChips(context),
        _whenAndShift(context),
        CheckSwitchTile(
          key: const ValueKey('dl-new-for-next-shift'),
          label: 'The next shift needs to know',
          description: 'Shows on Today and goes into the handover.',
          value: _forNextShift,
          onChanged: (v) => setState(() => _forNextShift = v),
        ),
        _flagBlock(context),
        _moreDetails(context),
      ],
    );
  }

  Widget _kindChips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kind',
          style: handoverText(context, 12.5, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in DailyLogLabels.logTypes)
              CheckToggleChip(
                key: ValueKey('dl-new-kind-$value'),
                label: label,
                selected: _logType == value,
                onTap: () => setState(() => _logType = value),
              ),
          ],
        ),
      ],
    );
  }

  Widget _whenAndShift(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final when = CheckPickerField(
      key: const ValueKey('dl-new-occurred'),
      label: 'When',
      value: DailyLogLabels.dateTime(_occurredAt),
      icon: Icons.calendar_month_rounded,
      onTap: () async {
        final picked = await pickDailyLogDateTime(context, _occurredAt);
        if (picked != null) setState(() => _occurredAt = picked);
      },
    );
    final shift = DailyLogSelect(
      key: const ValueKey('dl-new-shift'),
      label: 'Shift',
      value: DailyLogLabels.labelOf(DailyLogLabels.shifts, _shift),
      placeholder: 'Which shift wrote this?',
      onTap: () =>
          _select('Shift', DailyLogLabels.shifts, _shift, (v) => _shift = v),
    );
    if (!wide) {
      return Column(
        children: [
          when,
          const SizedBox(height: 16),
          shift,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: when),
        const SizedBox(width: 12),
        Expanded(child: shift),
      ],
    );
  }

  Widget _flagBlock(BuildContext context) {
    return Container(
      key: const ValueKey('dl-new-flag-block'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.urgentBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.urgentAmber.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckSwitchTile(
            key: const ValueKey('dl-new-flag'),
            label: 'Flag for a manager',
            description: 'Stays open in Review until somebody resolves it.',
            value: _flag,
            activeColor: AppColors.urgentAmber,
            onChanged: (v) => setState(() {
              _flag = v;
              // Web: flagging for a manager also marks it for the next shift.
              if (v) _forNextShift = true;
            }),
          ),
          if (_flag) ...[
            const SizedBox(height: 12),
            DailyLogSelect(
              key: const ValueKey('dl-new-flag-category'),
              label: 'Category',
              required: true,
              value: DailyLogLabels.labelOf(
                DailyLogLabels.flagCategories,
                _flagCategory,
              ),
              placeholder: 'What kind of concern is this?',
              error: _errors['flagCategory'],
              onTap: () => _select(
                'Category',
                DailyLogLabels.flagCategories,
                _flagCategory,
                (v) => _flagCategory = v,
              ),
            ),
            const SizedBox(height: 12),
            _area(
              'dl-new-flag-note',
              'What needs attention',
              _flagNote,
              'The line somebody reads on the board before deciding to act…',
              required: true,
              error: _errors['flagNote'],
            ),
          ],
        ],
      ),
    );
  }

  Widget _moreDetails(BuildContext context) {
    return Container(
      key: const ValueKey('dl-new-more'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const ValueKey('dl-new-more-toggle'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _moreOpen = !_moreOpen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More details',
                          style: handoverText(
                            context,
                            13.5,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mood, sleep, meals, the checks, a reminder, files.',
                          style: handoverText(
                            context,
                            12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _moreOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_moreOpen) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._moreFields(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _moreFields(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 560;
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

    return [
      pair(
        DailyLogSelect(
          key: const ValueKey('dl-new-mood'),
          label: 'Mood',
          value: DailyLogLabels.labelOf(DailyLogLabels.moods, _mood),
          placeholder: 'Select mood',
          onTap: () =>
              _select('Mood', DailyLogLabels.moods, _mood, (v) => _mood = v),
        ),
        DailyLogSelect(
          key: const ValueKey('dl-new-sleep'),
          label: 'Sleep',
          value: DailyLogLabels.labelOf(DailyLogLabels.sleeps, _sleep),
          placeholder: 'Select sleep quality',
          onTap: () =>
              _select('Sleep', DailyLogLabels.sleeps, _sleep, (v) => _sleep = v),
        ),
      ),
      const SizedBox(height: 14),
      pair(
        DailyLogSelect(
          key: const ValueKey('dl-new-hygiene'),
          label: 'Hygiene',
          value: DailyLogLabels.labelOf(DailyLogLabels.hygiene, _hygiene),
          placeholder: 'Select support given',
          onTap: () => _select(
            'Hygiene',
            DailyLogLabels.hygiene,
            _hygiene,
            (v) => _hygiene = v,
          ),
        ),
        CheckInput(
          key: const ValueKey('dl-new-meals'),
          label: 'Meals',
          controller: _meals,
          placeholder: 'e.g. Breakfast completed, lunch…',
        ),
      ),
      const SizedBox(height: 14),
      CheckInput(
        key: const ValueKey('dl-new-wellness-notes'),
        label: 'Wellness',
        controller: _wellnessNotes,
        placeholder:
            'How they seemed — e.g. No concerns, a bit off colour',
      ),
      const SizedBox(height: 14),
      _area(
        'dl-new-activities',
        'Activities',
        _activities,
        'Describe activities completed during the shift…',
      ),
      const SizedBox(height: 14),
      _area(
        'dl-new-behaviour',
        'Behaviour',
        _behaviorNotes,
        'Anything about how the resident presented…',
      ),
      const SizedBox(height: 14),
      _area(
        'dl-new-appointments',
        'Appointments',
        _appointmentNotes,
        'Appointments attended, booked, or missed…',
      ),
      const SizedBox(height: 14),
      CheckSwitchTile(
        key: const ValueKey('dl-new-outing'),
        label: 'Community outing',
        description: 'The resident went out of the home.',
        value: _outing,
        onChanged: (v) => setState(() => _outing = v),
      ),
      if (_outing) ...[
        const SizedBox(height: 12),
        _area(
          'dl-new-outing-notes',
          'Outing notes',
          _outingNotes,
          'Where they went, who went with them, how it went…',
          required: true,
          error: _errors['outingNotes'],
        ),
      ],
      const SizedBox(height: 16),
      Text(
        'Checks',
        style: handoverText(context, 13, weight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      _triStateCheck(
        key: 'dl-new-wellness',
        label: 'Wellness check',
        value: _wellness,
        onChanged: (v) => setState(() => _wellness = v),
      ),
      const SizedBox(height: 10),
      _triStateCheck(
        key: 'dl-new-bed',
        label: 'Bed check',
        value: _bed,
        onChanged: (v) => setState(() => _bed = v),
      ),
      const SizedBox(height: 14),
      CheckPickerField(
        key: const ValueKey('dl-new-remind'),
        label: 'Remind me at',
        value: DailyLogLabels.dateTime(_remindAt),
        icon: Icons.calendar_month_rounded,
        helper:
            "A time, not a task — 'check the dressing at 14:00'.",
        onTap: () async {
          final picked = await pickDailyLogDateTime(context, _remindAt);
          if (picked != null) setState(() => _remindAt = picked);
        },
        onClear: () => setState(() => _remindAt = null),
      ),
      const SizedBox(height: 14),
      _attachmentsField(context),
    ];
  }

  Widget _triStateCheck({
    required String key,
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    Widget chip(String text, bool? option) {
      final selected = value == option;
      return Expanded(
        child: InkWell(
          key: ValueKey('$key-${option ?? 'null'}'),
          onTap: () => onChanged(option),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.secondaryTeal.withValues(alpha: 0.1)
                  : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    selected ? AppColors.secondaryTeal : AppColors.searchBorder,
              ),
            ),
            child: Text(
              text,
              style: handoverText(
                context,
                12.5,
                weight: FontWeight.w600,
                color: selected
                    ? AppColors.secondaryTeal
                    : AppColors.textHeading,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: handoverText(context, 13),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              chip('Done', true),
              const SizedBox(width: 6),
              chip('Not done', false),
              const SizedBox(width: 6),
              chip('Not said', null),
            ],
          ),
        ),
      ],
    );
  }

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

  Widget _attachmentsField(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Files',
            style: handoverText(context, 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          InkWell(
            key: const ValueKey('dl-new-attach'),
            onTap: _uploading ? null : _addFiles,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.searchBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Click to upload or drag & drop',
                    textAlign: TextAlign.center,
                    style: handoverText(
                      context,
                      13,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'A photo, a letter, a chart — up to 25MB each',
                    textAlign: TextAlign.center,
                    style: handoverText(
                      context,
                      12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_uploading) ...[
            const SizedBox(height: 6),
            Text(
              'Uploading…',
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
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
                  const Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachments[i].fileName ??
                          _attachments[i].fileUrl.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(context, 13),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('dl-new-attach-remove-$i'),
                    tooltip:
                        'Remove ${_attachments[i].fileName ?? 'file'}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _attachments.removeAt(i)),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}
