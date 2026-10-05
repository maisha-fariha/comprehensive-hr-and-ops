import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/entities/training_course_view.dart';
import '../../domain/entities/training_form.dart';
import '../training_labels.dart';
import 'training_common.dart';

/// The body of one wizard step. [values] is edited in place and
/// [onChanged] lets the page rebuild its summary and progress.
class TrainingFormStep extends StatefulWidget {
  final String step;
  final TrainingFormValues values;
  final Map<String, String> errors;
  final List<TrainingStaffOption> staff;
  final List<TrainingOption> categories;
  final List<TrainingOption> residences;
  final int reach;
  final Future<TrainingMaterialFile?> Function() pickFile;
  final VoidCallback onChanged;

  const TrainingFormStep({
    super.key,
    required this.step,
    required this.values,
    required this.errors,
    required this.staff,
    required this.categories,
    required this.residences,
    required this.reach,
    required this.pickFile,
    required this.onChanged,
  });

  @override
  State<TrainingFormStep> createState() => _TrainingFormStepState();
}

class _TrainingFormStepState extends State<TrainingFormStep> {
  late final TrainingFormValues _v = widget.values;
  late final _title = TextEditingController(text: _v.title);
  late final _description = TextEditingController(text: _v.description);
  late final _customDuration =
      TextEditingController(text: _v.customDurationValue?.toString() ?? '');
  late final _materialUrl = TextEditingController(text: _v.materialUrl);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _customDuration.dispose();
    _materialUrl.dispose();
    super.dispose();
  }

  void _set(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final children = switch (widget.step) {
      'trainingInformation' => _information(context),
      'contentUpload' => _content(context),
      'quizSetup' => _quiz(context),
      'assignmentRules' => _assignment(context),
      _ => _review(context),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 18),
          child,
        ],
      ],
    );
  }

  Widget _section(String title, String description) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: handoverText(context, 15, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(description, style: handoverText(context, 12.5, color: AppColors.textMuted)),
        ],
      );

  Widget _select({
    required String label,
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    String placeholder = '',
    bool required = false,
    String? error,
    Key? key,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HandoverSelect(
          key: key,
          label: label,
          required: required,
          value: value,
          placeholder: placeholder,
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: label,
              options: [
                for (final o in {...options, if (value.isNotEmpty) value}) (o, o),
              ],
              selected: value,
            );
            if (picked != null) onChanged(picked);
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error, style: handoverText(context, 12, color: AppColors.criticalRed)),
        ],
      ],
    );
  }

  List<Widget> _information(BuildContext context) => [
        _section('Training Information', 'Basic details that identify this training module.'),
        TrainingTextField(
          key: const ValueKey('training-form-title'),
          label: 'Training Title',
          required: true,
          controller: _title,
          placeholder: 'e.g. Medication Administration Competency 2026',
          error: widget.errors['title'],
          onChanged: (v) => _set(() => _v.title = v),
        ),
        _select(
          key: const ValueKey('training-form-category'),
          label: 'Category',
          required: true,
          placeholder: 'Select category',
          options: TrainingLabels.categories,
          value: _v.category,
          error: widget.errors['category'],
          onChanged: (v) => _set(() => _v.category = v),
        ),
        TrainingChoiceCards(
          label: 'Training Type',
          required: true,
          columns: 3,
          options: [for (final t in TrainingLabels.types) (t, '')],
          value: _v.type,
          onChanged: (v) => _set(() => _v.type = v),
        ),
        TrainingTextField(
          key: const ValueKey('training-form-description'),
          label: 'Description',
          controller: _description,
          minLines: 3,
          maxLength: 500,
          helper: 'Optional \u00b7 max 500 chars \u00b7 ${_v.description.length} / 500',
          onChanged: (v) => _set(() => _v.description = v),
        ),
        TrainingChoiceCards(
          label: 'Expiry / Renewal Period',
          required: true,
          options: TrainingLabels.expiryPeriods,
          value: _v.expiryPeriod,
          onChanged: (v) => _set(() => _v.expiryPeriod = v),
        ),
        if (_v.expiryPeriod == 'Custom')
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TrainingTextField(
                  key: const ValueKey('training-form-custom-duration'),
                  label: 'Custom Duration',
                  controller: _customDuration,
                  numeric: true,
                  placeholder: '18',
                  error: widget.errors['customDurationValue'],
                  onChanged: (v) => _set(() => _v.customDurationValue = int.tryParse(v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _select(
                  label: 'Unit',
                  options: TrainingLabels.durationUnits,
                  value: _v.customDurationUnit,
                  onChanged: (v) => _set(() => _v.customDurationUnit = v),
                ),
              ),
            ],
          ),
      ];

  List<Widget> _content(BuildContext context) {
    final file = _v.materialFile;
    return [
      _section(
        'Course Material',
        'Upload the video or document staff will work through, or link to where it already lives.',
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TrainingLabel('Upload material'),
          const SizedBox(height: 6),
          InkWell(
            key: const ValueKey('training-form-upload'),
            onTap: () async {
              final picked = await widget.pickFile();
              if (picked != null) _set(() => _v.materialFile = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.searchBorder),
                color: AppColors.scaffoldBackground,
              ),
              child: Column(
                children: [
                  const Icon(Icons.upload_file_outlined, color: AppColors.secondaryTeal),
                  const SizedBox(height: 6),
                  Text(
                    'Video, PDF or document \u00b7 up to 15 MB',
                    textAlign: TextAlign.center,
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (file != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 18, color: AppColors.secondaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(context, 13, weight: FontWeight.w500),
                    ),
                  ),
                  Semantics(
                    label: 'Remove',
                    button: true,
                    child: GestureDetector(
                      onTap: () => _set(() => _v.materialFile = null),
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      TrainingTextField(
        key: const ValueKey('training-form-material-url'),
        label: '\u2026or link to it',
        controller: _materialUrl,
        placeholder: 'https://\u2026',
        helper: 'Used when nothing is uploaded \u2014 an intranet page, a supplier\u2019s course',
        onChanged: (v) => _set(() => _v.materialUrl = v),
      ),
    ];
  }

  List<Widget> _quiz(BuildContext context) => [
        _section('Quiz Setup', 'Add a knowledge check staff must pass to complete this training.'),
        TrainingSwitchRow(
          key: const ValueKey('training-form-quiz-enabled'),
          label: 'Enable Quiz',
          description: 'Require staff to pass an assessment',
          value: _v.quizEnabled,
          onChanged: (v) => _set(() => _v.quizEnabled = v),
        ),
        if (_v.quizEnabled) ...[
          if (widget.errors['questions'] != null) TrainingInlineError(widget.errors['questions']!),
          for (final (i, q) in _v.questions.indexed)
            _QuestionEditor(
              key: ValueKey('training-form-question-${q.id}'),
              number: i + 1,
              question: q,
              onRemove: () => _set(() => _v.questions.removeAt(i)),
              onChanged: () => _set(() {}),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: HandoverButton(
              key: const ValueKey('training-form-add-question'),
              label: 'Add Question',
              icon: Icons.add_rounded,
              foreground: AppColors.secondaryTeal,
              onPressed: () => _set(() {
                final n = _v.questions.length + 1;
                _v.questions.add(
                  TrainingFormQuestion(id: 'q-${DateTime.now().microsecondsSinceEpoch}-$n'),
                );
              }),
            ),
          ),
          TrainingStepper(
            key: const ValueKey('training-form-passing-score'),
            label: 'Passing Score (%)',
            value: _v.passingScore,
            min: 0,
            max: 100,
            suffix: '%',
            onChanged: (v) => _set(() => _v.passingScore = v),
          ),
          TrainingStepper(
            key: const ValueKey('training-form-attempts'),
            label: 'Attempts Allowed',
            value: _v.attemptsAllowed,
            min: 1,
            max: 10,
            suffix: 'attempts',
            onChanged: (v) => _set(() => _v.attemptsAllowed = v),
          ),
        ],
      ];

  List<Widget> _assignment(BuildContext context) => [
        _section('Assignment Rules', 'Choose who must take this training and set deadlines.'),
        TrainingChoiceCards(
          label: 'Assign To',
          required: true,
          options: TrainingLabels.assignTo,
          value: _v.assignTo,
          onChanged: (v) => _set(() => _v.assignTo = v),
        ),
        if (_v.assignTo == 'Specific Roles')
          TrainingMultiPicker(
            label: 'Roles',
            helper: 'The staff categories this tenant uses',
            placeholder: 'Add role\u2026',
            error: widget.errors['roles'],
            options: [for (final c in widget.categories) (c.id, c.label)],
            value: _v.roles,
            onChanged: (v) => _set(() => _v.roles = v),
          ),
        if (_v.assignTo == 'Specific Residence')
          TrainingMultiPicker(
            label: 'Residences',
            placeholder: 'Add residence\u2026',
            error: widget.errors['residences'],
            options: [for (final r in widget.residences) (r.id, r.label)],
            value: _v.residences,
            onChanged: (v) => _set(() => _v.residences = v),
          ),
        if (_v.assignTo == 'Individual Staff')
          TrainingStaffPicker(
            staff: widget.staff,
            value: _v.staffIds,
            error: widget.errors['staffIds'],
            onChanged: (v) => _set(() => _v.staffIds = v),
          ),
        Text(
          'Estimated reach: ${widget.reach} staff members',
          key: const ValueKey('training-form-reach'),
          style: handoverText(context, 12.5, weight: FontWeight.w600, color: AppColors.secondaryTeal),
        ),
        TrainingSwitchRow(
          label: 'Mandatory Training',
          description: 'Staff cannot dismiss this assignment',
          value: _v.mandatory,
          onChanged: (v) => _set(() => _v.mandatory = v),
        ),
        TrainingDateField(
          key: const ValueKey('training-form-due'),
          label: 'Due Date',
          value: _v.dueDate,
          helper: 'When it has to be done by. Leave blank for no deadline.',
          onChanged: (v) => _set(() => _v.dueDate = v),
        ),
      ];

  List<Widget> _review(BuildContext context) {
    Widget card(String title, List<(String, String)> rows, {bool success = false}) =>
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: handoverText(context, 13, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: handoverText(context, 12, color: AppColors.textMuted)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: handoverText(context, 12.5, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
    final file = _v.materialFile;
    return [
      _section('Review & Publish', 'Confirm every section before publishing this training to staff.'),
      card('Training Information', [
        ('Title', _v.title.isEmpty ? '—' : _v.title),
        ('Category', _v.category.isEmpty ? '—' : _v.category),
        ('Type', _v.type),
      ]),
      card('Course Material', [
        ('Material', file != null ? file.name : (_v.materialUrl.isNotEmpty ? 'Linked' : 'None')),
      ]),
      card(
        'Quiz Details',
        _v.quizEnabled
            ? [
                ('Questions', '${_v.questions.length}'),
                ('Passing Score', '${_v.passingScore}%'),
                ('Attempts', '${_v.attemptsAllowed}'),
              ]
            : [('Quiz', 'Disabled')],
      ),
      card('Assigned Users', [
        ('Assign To', '${_v.assignTo} \u00b7 ${widget.reach} staff'),
        ('Mandatory', _v.mandatory ? 'Yes' : 'No'),
        ('Due Date', TrainingLabels.date(_v.dueDate)),
      ]),
      card('Expiry Rules', [
        ('Renewal Period', _v.expiryPeriod),
        (
          'Certificate required',
          _v.certificateRequired ? 'Yes \u2014 completion waits on approval' : 'No',
        ),
      ]),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.activeBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What happens after publishing',
              style: handoverText(context, 13, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final line in TrainingLabels.afterPublishing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.activeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(child: Text(line, style: handoverText(context, 12.5))),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _QuestionEditor extends StatefulWidget {
  final int number;
  final TrainingFormQuestion question;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _QuestionEditor({
    super.key,
    required this.number,
    required this.question,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  TrainingFormQuestion get _q => widget.question;
  late final _prompt = TextEditingController(text: _q.question);
  late List<TextEditingController> _options = _controllers();

  List<TextEditingController> _controllers() =>
      [for (final o in _q.options) TextEditingController(text: o)];

  @override
  void dispose() {
    _prompt.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetOptions() {
    for (final c in _options) {
      c.dispose();
    }
    _options = _controllers();
  }

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final trueFalse = _q.type == 'True / False';
    final answers = _q.options.where((o) => o.isNotEmpty).toSet().toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${widget.number}',
                  style: handoverText(context, 13, weight: FontWeight.w700),
                ),
              ),
              Semantics(
                label: 'Remove question ${widget.number}',
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          TrainingTextField(
            label: 'Question',
            controller: _prompt,
            placeholder: 'Enter the question',
            onChanged: (v) => _update(() => _q.question = v),
          ),
          const SizedBox(height: 12),
          HandoverSelect(
            label: 'Question Type',
            value: _q.type,
            placeholder: '',
            onTap: () async {
              final picked = await pickHandoverOption(
                context,
                title: 'Question Type',
                options: [for (final t in TrainingLabels.formQuestionTypes) (t, t)],
                selected: _q.type,
              );
              if (picked == null || picked == _q.type) return;
              _update(() {
                _q.type = picked;
                _q.options = picked == 'True / False' ? ['True', 'False'] : ['', ''];
                _q.correctAnswer = '';
                _resetOptions();
              });
            },
          ),
          const SizedBox(height: 12),
          const TrainingLabel('Answer Options'),
          const SizedBox(height: 6),
          for (final (i, controller) in _options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !trueFalse,
                      onChanged: (v) => _update(() => _q.options[i] = v),
                      style: handoverText(context, 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Option ${String.fromCharCode(65 + i)}',
                        hintStyle: handoverText(context, 13, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: AppColors.searchBorder),
                        ),
                      ),
                    ),
                  ),
                  if (!trueFalse && _options.length > 2)
                    Semantics(
                      label: 'Remove option',
                      button: true,
                      excludeSemantics: true,
                      child: IconButton(
                        onPressed: () => _update(() {
                          _q.options.removeAt(i);
                          _options.removeAt(i).dispose();
                        }),
                        icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          if (!trueFalse)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _update(() {
                  _q.options.add('');
                  _options.add(TextEditingController());
                }),
                icon: const Icon(Icons.add_rounded, size: 14, color: AppColors.secondaryTeal),
                label: Text(
                  'Add Option',
                  style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.secondaryTeal),
                ),
              ),
            ),
          const SizedBox(height: 8),
          HandoverSelect(
            label: 'Correct Answer',
            value: answers.contains(_q.correctAnswer) ? _q.correctAnswer : null,
            placeholder: 'Select correct answer',
            onTap: answers.isEmpty
                ? null
                : () async {
                    final picked = await pickHandoverOption(
                      context,
                      title: 'Correct Answer',
                      options: [for (final a in answers) (a, a)],
                      selected: _q.correctAnswer,
                    );
                    if (picked != null) _update(() => _q.correctAnswer = picked);
                  },
          ),
        ],
      ),
    );
  }
}

/// Web "Assign to Staff": picked people as chips, and an "Add staff…" search
/// listing everyone not yet picked.
class TrainingStaffPicker extends StatefulWidget {
  final List<TrainingStaffOption> staff;
  final List<String> value;
  final String? error;
  final ValueChanged<List<String>> onChanged;

  const TrainingStaffPicker({
    super.key,
    required this.staff,
    required this.value,
    required this.onChanged,
    this.error,
  });

  @override
  State<TrainingStaffPicker> createState() => _TrainingStaffPickerState();
}

class _TrainingStaffPickerState extends State<TrainingStaffPicker> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) setState(() => _open = true);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  Widget _avatar(String name, double size) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.quickActionCreateShiftBg,
          shape: BoxShape.circle,
        ),
        child: Text(
          trainingInitials(name),
          style: handoverText(context, 10, weight: FontWeight.w700, color: AppColors.secondaryTeal),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final picked = widget.staff.where((s) => widget.value.contains(s.id)).toList();
    final q = _query.text.trim().toLowerCase();
    final matches = widget.staff
        .where((s) => !widget.value.contains(s.id) && s.name.toLowerCase().contains(q))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TrainingLabel('Assign to Staff'),
        const SizedBox(height: 6),
        if (picked.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in picked)
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _avatar(s.name, 24),
                      const SizedBox(width: 6),
                      Text(s.name, style: handoverText(context, 12, weight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Semantics(
                        label: 'Remove ${s.name}',
                        button: true,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => widget.onChanged(
                            widget.value.where((id) => id != s.id).toList(),
                          ),
                          child: const Icon(Icons.close_rounded, size: 13, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          key: const ValueKey('training-staff-search'),
          controller: _query,
          focusNode: _focus,
          onChanged: (_) => setState(() => _open = true),
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Add staff\u2026',
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(
                color: widget.error != null ? AppColors.criticalRed : AppColors.searchBorder,
              ),
            ),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No matches found',
                      textAlign: TextAlign.center,
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(6),
                    children: [
                      for (final s in matches)
                        InkWell(
                          key: ValueKey('training-staff-option-${s.id}'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            widget.onChanged([...widget.value, s.id]);
                            _query.clear();
                            _focus.unfocus();
                            setState(() => _open = false);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                _avatar(s.name, 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          style: handoverText(context, 12.5, weight: FontWeight.w600)),
                                      Text(s.role,
                                          style: handoverText(context, 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.add_rounded, size: 14, color: AppColors.secondaryTeal),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        if (widget.error != null) ...[
          const SizedBox(height: 5),
          Text(widget.error!, style: handoverText(context, 12, color: AppColors.criticalRed)),
        ],
      ],
    );
  }
}
