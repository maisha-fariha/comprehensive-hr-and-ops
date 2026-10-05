import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/entities/training_course_view.dart';
import '../../domain/entities/training_form.dart';
import '../controllers/hr_training_course_controller.dart';
import '../training_labels.dart';
import 'training_common.dart';

Widget _rowCard({required Key key, required List<Widget> children}) => Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: HandoverPanel(
          key: key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );

List<Widget> _pagedBody<T>(
  HrTrainingCourseController c,
  TrainingPagedList<T> list, {
  required String errorTitle,
  required String emptyTitle,
  required String emptyMessage,
  required Widget Function(T row) row,
}) {
  if (list.loading.value && list.rows.isEmpty) {
    return [
      for (var i = 0; i < 2; i++)
        Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.filterButtonBackground,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
    ];
  }
  if (list.rows.isEmpty) {
    final error = list.error.value;
    return [
      TrainingEmptyState(
        title: error != null ? errorTitle : emptyTitle,
        message: error ?? emptyMessage,
      ),
    ];
  }
  return [
    for (final r in list.rows) row(r),
    AttendancePagination(
      page: list.page.value,
      limit: list.limit.value,
      total: list.total.value,
      totalPages: list.totalPages.value,
      limitOptions: HrTrainingCourseController.pageSizes,
      onPage: (p) => c.setTabPage(list, p),
      onLimit: (l) => c.setTabLimit(list, l),
    ),
  ];
}

// --------------------------------------------------------------- Assignments

TrainingTone _assignmentTone(String status) => switch (status) {
      'assigned' => TrainingTone.warning,
      'in_progress' => TrainingTone.info,
      'completed' => TrainingTone.success,
      _ => TrainingTone.neutral,
    };

class TrainingAssignmentsTab extends StatelessWidget {
  final HrTrainingCourseController controller;

  const TrainingAssignmentsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final certificateRequired = c.course.value?.certificateRequired ?? false;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.canManage) ...[
            Align(
              alignment: Alignment.centerRight,
              child: HandoverButton(
                key: const ValueKey('training-assign-staff'),
                label: 'Assign staff',
                icon: Icons.person_add_alt_1_outlined,
                filled: true,
                onPressed: () => showTrainingSheet<void>(
                  context,
                  builder: (_) => TrainingAssignSheet(controller: c),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
          ..._pagedBody(
            c,
            c.assignmentsTab,
            errorTitle: 'Assignments could not be loaded',
            emptyTitle: 'Nobody assigned',
            emptyMessage: 'Assign staff and the course appears on their record.',
            row: (a) => _assignmentRow(context, c, a, certificateRequired),
          ),
        ],
      );
    });
  }

  Widget _assignmentRow(
    BuildContext context,
    HrTrainingCourseController c,
    TrainingAssignment a,
    bool certificateRequired,
  ) {
    final overdue = a.isOverdueAt(DateTime.now());
    final busy = c.busyId.value == a.id;
    Widget? action;
    if (c.canManage && a.status != 'completed') {
      if (certificateRequired) {
        action = a.status == 'pending_review'
            ? Text('Waiting for HR', style: handoverText(context, 12, color: AppColors.textMuted))
            : HandoverButton(
                key: ValueKey('training-submit-certificate-${a.id}'),
                label: a.status == 'rejected' ? 'Re-submit certificate' : 'Submit certificate',
                filled: true,
                compact: true,
                onPressed: () => showTrainingSheet<void>(
                  context,
                  builder: (_) => TrainingSubmitCertificateSheet(controller: c, assignmentId: a.id),
                ),
              );
      } else {
        action = HandoverButton(
          key: ValueKey('training-advance-${a.id}'),
          label: a.status == 'assigned' ? 'Start' : 'Mark complete',
          filled: true,
          compact: true,
          onPressed: busy ? null : () => c.advance(a),
        );
      }
    }
    return _rowCard(
      key: ValueKey('training-assignment-${a.id}'),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                c.staffName(a.staffId),
                style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
              ),
            ),
            TrainingPill(label: trainingHumanise(a.status), tone: _assignmentTone(a.status), dot: true),
          ],
        ),
        TrainingField.text(
          label: 'Due',
          value: '${TrainingLabels.date(a.dueAt)}${overdue ? ' \u00b7 overdue' : ''}',
          color: overdue ? AppColors.criticalRed : AppColors.textHeading,
        ),
        TrainingField(
          label: 'Mandatory',
          child: a.mandatory
              ? const TrainingPill(label: 'Required', tone: TrainingTone.danger)
              : Text('Optional', style: handoverText(context, 13, color: AppColors.infoBlue)),
        ),
        TrainingField.text(label: 'Completed', value: TrainingLabels.date(a.completedAt)),
        if (action != null) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      ],
    );
  }
}

class TrainingAssignSheet extends StatefulWidget {
  final HrTrainingCourseController controller;

  const TrainingAssignSheet({super.key, required this.controller});

  @override
  State<TrainingAssignSheet> createState() => _TrainingAssignSheetState();
}

class _TrainingAssignSheetState extends State<TrainingAssignSheet> {
  List<String> _staff = [];
  DateTime? _due;
  bool _mandatory = true;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _saving = _staff.isNotEmpty;
    });
    final error = await widget.controller.assign(
      staffIds: _staff,
      mandatory: _mandatory,
      dueAt: _due,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrainingSheetFrame(
      title: 'Assign staff',
      description: 'One call for the whole group, so a half-assigned cohort cannot happen.',
      icon: Icons.person_add_alt_1_outlined,
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('training-assign-submit'),
          label: _saving ? 'Assigning…' : 'Assign',
          filled: true,
          onPressed: _saving ? null : _submit,
        ),
      ],
      children: [
        if (_error != null) ...[
          TrainingInlineError(_error!, key: const ValueKey('training-assign-error')),
          const SizedBox(height: 14),
        ],
        Obx(
          () => TrainingMultiPicker(
            label: 'Staff',
            helper: 'Anyone already assigned is left as they are',
            options: [for (final s in widget.controller.staffOptions) (s.id, s.name)],
            value: _staff,
            onChanged: (v) => setState(() => _staff = v),
          ),
        ),
        const SizedBox(height: 14),
        TrainingDateField(
          key: const ValueKey('training-assign-due'),
          label: 'Due',
          withTime: true,
          value: _due,
          onChanged: (v) => setState(() => _due = v),
        ),
        const SizedBox(height: 10),
        TrainingSwitchRow(
          label: 'Mandatory',
          value: _mandatory,
          onChanged: (v) => setState(() => _mandatory = v),
        ),
      ],
    );
  }
}

class TrainingSubmitCertificateSheet extends StatefulWidget {
  final HrTrainingCourseController controller;
  final String assignmentId;

  const TrainingSubmitCertificateSheet({
    super.key,
    required this.controller,
    required this.assignmentId,
  });

  @override
  State<TrainingSubmitCertificateSheet> createState() => _TrainingSubmitCertificateSheetState();
}

class _TrainingSubmitCertificateSheetState extends State<TrainingSubmitCertificateSheet> {
  final _number = TextEditingController();
  final _provider = TextEditingController();
  final _scan = TextEditingController();
  DateTime? _completed;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _provider.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _error = null;
      _sending = true;
    });
    final error = await widget.controller.submitCertificate(
      widget.assignmentId,
      certificateNumber: _number.text,
      provider: _provider.text,
      fileUrl: _scan.text,
      completedOn: _completed,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrainingSheetFrame(
      title: 'Submit the certificate',
      description: 'Training passed somewhere else. What gets checked is the card \u2014 its '
          'number, who issued it, and when it was earned. Somebody in HR looks before it '
          'counts as done.',
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('training-certificate-send'),
          label: _sending ? 'Sending…' : 'Send for review',
          filled: true,
          onPressed: _sending ? null : _send,
        ),
      ],
      children: [
        TrainingTextField(label: 'Certificate number', controller: _number, placeholder: 'FA-2026-8891'),
        const SizedBox(height: 12),
        TrainingTextField(label: 'Issued by', controller: _provider, placeholder: 'St John Ambulance'),
        const SizedBox(height: 12),
        TrainingDateField(
          label: 'Date completed',
          value: _completed,
          helper: 'When the training was done, not today',
          onChanged: (v) => setState(() => _completed = v),
        ),
        const SizedBox(height: 12),
        TrainingTextField(label: 'Scan or photo', controller: _scan, placeholder: 'https://\u2026'),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: handoverText(context, 12.5, color: AppColors.criticalRed)),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------- Certificates

class TrainingCertificatesTab extends StatelessWidget {
  final HrTrainingCourseController controller;

  const TrainingCertificatesTab({super.key, required this.controller});

  static String _date(DateTime? value) => TrainingLabels.date(value, fallback: 'No expiry');

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _pagedBody(
          c,
          c.certificatesTab,
          errorTitle: 'Certificates could not be loaded',
          emptyTitle: 'None issued yet',
          emptyMessage: 'Passing the quiz issues one; a course passed elsewhere is submitted '
              'with its card and approved here.',
          row: (cert) => _row(context, c, cert),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, HrTrainingCourseController c, TrainingCertificate cert) {
    final review = cert.reviewStatus ?? 'approved';
    final busy = c.busyId.value == cert.id;
    return _rowCard(
      key: ValueKey('training-certificate-${cert.id}'),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cert.staffName.isEmpty ? '—' : cert.staffName,
                style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
              ),
            ),
            TrainingPill(
              label: switch (cert.expiryStatus) {
                'expiring' => 'Expiring',
                'expired' => 'Expired',
                _ => 'Valid',
              },
              tone: switch (cert.expiryStatus) {
                'valid' => TrainingTone.success,
                'expiring' => TrainingTone.warning,
                'expired' => TrainingTone.danger,
                _ => TrainingTone.neutral,
              },
              dot: true,
            ),
          ],
        ),
        TrainingField.text(label: 'Issued', value: _date(cert.issuedAt)),
        TrainingField.text(label: 'Expires', value: _date(cert.expiresAt)),
        TrainingField(
          label: 'Evidence',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cert.certificateNumber ?? 'No number recorded', style: handoverText(context, 13)),
              Text(cert.provider ?? 'Passed here', style: handoverText(context, 12, color: AppColors.infoBlue)),
            ],
          ),
        ),
        TrainingField(
          label: 'Accepted',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrainingPill(
                label: review == 'submitted'
                    ? 'Waiting'
                    : review == 'rejected'
                        ? 'Sent back'
                        : 'Approved',
                tone: switch (review) {
                  'approved' => TrainingTone.success,
                  'submitted' => TrainingTone.warning,
                  'rejected' => TrainingTone.danger,
                  _ => TrainingTone.neutral,
                },
              ),
              if (review == 'rejected' && cert.reviewNotes != null)
                Text(cert.reviewNotes!, style: handoverText(context, 12, color: AppColors.infoBlue)),
            ],
          ),
        ),
        if (c.canManage && cert.reviewStatus == 'submitted') ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              HandoverButton(
                key: ValueKey('training-certificate-reject-${cert.id}'),
                label: 'Send back',
                compact: true,
                onPressed: () => showTrainingSheet<void>(
                  context,
                  builder: (_) => TrainingSendBackSheet(controller: c, certificateId: cert.id),
                ),
              ),
              const SizedBox(width: 8),
              HandoverButton(
                key: ValueKey('training-certificate-approve-${cert.id}'),
                label: 'Approve',
                filled: true,
                compact: true,
                onPressed: busy ? null : () => c.approveCertificate(cert),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class TrainingSendBackSheet extends StatefulWidget {
  final HrTrainingCourseController controller;
  final String certificateId;

  const TrainingSendBackSheet({
    super.key,
    required this.controller,
    required this.certificateId,
  });

  @override
  State<TrainingSendBackSheet> createState() => _TrainingSendBackSheetState();
}

class _TrainingSendBackSheetState extends State<TrainingSendBackSheet> {
  final _notes = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _error = null;
      _sending = true;
    });
    final error = await widget.controller.rejectCertificate(widget.certificateId, _notes.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = _notes.text.trim().isEmpty;
    return TrainingSheetFrame(
      title: 'Send the certificate back',
      description: 'Say what is wrong with it. The person gets the reason, so a refusal they '
          'cannot act on is not a dead end.',
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('training-send-back-submit'),
          label: 'Send back',
          filled: true,
          onPressed: empty || _sending ? null : _send,
        ),
      ],
      children: [
        HandoverTextArea(
          key: const ValueKey('training-send-back-notes'),
          label: 'What needs fixing',
          required: true,
          controller: _notes,
          minLines: 3,
          placeholder: 'The card is cut off \u2014 please re-scan it showing the expiry date.',
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: handoverText(context, 12.5, color: AppColors.criticalRed)),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------ Sittings

class TrainingSittingsTab extends StatelessWidget {
  final HrTrainingCourseController controller;

  const TrainingSittingsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final quiz = c.quiz.value;
      final canSit = (quiz?.questions.isNotEmpty ?? false) && quiz?.passingScore != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.canManage) ...[
            if (!canSit) ...[
              Text(
                'This course has no quiz to sit \u2014 it needs questions and a pass mark.',
                textAlign: TextAlign.right,
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: HandoverButton(
                key: const ValueKey('training-record-sitting'),
                label: 'Record a sitting',
                icon: Icons.fact_check_outlined,
                filled: true,
                onPressed: canSit
                    ? () => showTrainingSheet<void>(
                          context,
                          builder: (_) => TrainingRecordSittingSheet(controller: c),
                        )
                    : null,
              ),
            ),
            const SizedBox(height: 15),
          ],
          ..._pagedBody(
            c,
            c.sittingsTab,
            errorTitle: 'Sittings could not be loaded',
            emptyTitle: 'No sittings yet',
            emptyMessage: 'Every sitting is marked on the server and listed here.',
            row: (a) => _rowCard(
              key: ValueKey('training-sitting-${a.id}'),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.staffName(a.staffId),
                        style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                    ),
                    TrainingPill(
                      label: a.passed ? 'Passed' : 'Failed',
                      tone: a.passed ? TrainingTone.success : TrainingTone.danger,
                      dot: true,
                    ),
                  ],
                ),
                TrainingField.text(label: 'Score', value: '${a.score}%'),
                TrainingField.text(
                  label: 'Attempt',
                  value: '${a.attemptNo ?? '—'}'
                      '${(quiz?.attemptsAllowed ?? 0) > 0 ? ' of ${quiz!.attemptsAllowed}' : ''}',
                ),
                TrainingField.text(label: 'Submitted', value: TrainingLabels.dateTime(a.submittedAt)),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class TrainingRecordSittingSheet extends StatefulWidget {
  final HrTrainingCourseController controller;

  const TrainingRecordSittingSheet({super.key, required this.controller});

  @override
  State<TrainingRecordSittingSheet> createState() => _TrainingRecordSittingSheetState();
}

class _TrainingRecordSittingSheetState extends State<TrainingRecordSittingSheet> {
  String? _staffId;
  final Map<String, List<int>> _selected = {};
  bool _marking = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _marking = _staffId != null;
    });
    final error = await widget.controller.submitAttempt(staffId: _staffId, selected: _selected);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _marking = false;
        _error = error;
      });
    }
  }

  void _toggle(TrainingQuestion q, int index) {
    final single = q.type != 'multi_choice';
    final current = _selected[q.id] ?? const <int>[];
    setState(() {
      _selected[q.id] = current.contains(index)
          ? current.where((i) => i != index).toList()
          : single
              ? [index]
              : [...current, index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final quiz = c.quiz.value;
    final questions = quiz?.questions ?? const <TrainingQuestion>[];
    final staffLabel = c.staffOptions.firstWhereOrNull((s) => s.id == _staffId)?.name;
    return TrainingSheetFrame(
      title: 'Record a sitting',
      description: 'Marked by the API. Pass mark ${quiz?.passingScore ?? '—'}%.',
      icon: Icons.fact_check_outlined,
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('training-sitting-submit'),
          label: _marking ? 'Marking…' : 'Submit for marking',
          filled: true,
          onPressed: _marking ? null : _submit,
        ),
      ],
      children: [
        if (_error != null) ...[
          TrainingInlineError(_error!, key: const ValueKey('training-sitting-error')),
          const SizedBox(height: 14),
        ],
        HandoverSelect(
          key: const ValueKey('training-sitting-staff'),
          label: 'Who sat it',
          required: true,
          value: staffLabel,
          placeholder: 'Which staff member',
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: 'Who sat it',
              options: [for (final s in c.staffOptions) (s.id, s.name)],
              selected: _staffId,
            );
            if (picked != null) setState(() => _staffId = picked);
          },
        ),
        for (final (i, q) in questions.indexed) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ${q.prompt}', style: handoverText(context, 14, weight: FontWeight.w600)),
                for (final (j, option) in q.options.indexed)
                  CheckboxListTile(
                    key: ValueKey('training-sitting-answer-${q.id}-$j'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.secondaryTeal,
                    value: (_selected[q.id] ?? const <int>[]).contains(j),
                    onChanged: (_) => _toggle(q, j),
                    title: Text(option, style: handoverText(context, 13.5)),
                  ),
                if (q.type == 'multi_choice')
                  Text(
                    'All correct answers must be ticked \u2014 partial credit is not given.',
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------- Quiz

class TrainingQuizTab extends StatefulWidget {
  final HrTrainingCourseController controller;

  const TrainingQuizTab({super.key, required this.controller});

  @override
  State<TrainingQuizTab> createState() => _TrainingQuizTabState();
}

class _TrainingQuizTabState extends State<TrainingQuizTab> {
  List<TrainingQuizDraft>? _drafts;
  int _generation = 0;
  bool _saving = false;
  String? _error;

  HrTrainingCourseController get _c => widget.controller;

  void _start(List<TrainingQuestion> questions) => setState(() {
        _error = null;
        _generation++;
        _drafts = questions.isEmpty
            ? [TrainingQuizDraft()]
            : [
                for (final q in questions)
                  TrainingQuizDraft(prompt: q.prompt, type: q.type, options: [...q.options]),
              ];
      });

  Future<void> _save() async {
    final drafts = _drafts;
    if (drafts == null) return;
    setState(() {
      _error = null;
      _saving = TrainingQuizDraft.validate(drafts) == null;
    });
    final error = await _c.saveQuiz(drafts);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
      if (error == null) _drafts = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final quiz = _c.quiz.value;
      final questions = quiz?.questions ?? const <TrainingQuestion>[];
      return _drafts == null ? _view(context, quiz, questions) : _editor(context, questions);
    });
  }

  Widget _view(BuildContext context, TrainingQuiz? quiz, List<TrainingQuestion> questions) {
    final n = questions.length;
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz', style: handoverText(context, 15, weight: FontWeight.w600)),
                    Text(
                      n > 0
                          ? '$n question${n == 1 ? '' : 's'}'
                              '${(quiz?.passingScore ?? 0) > 0 ? ' \u00b7 pass at ${quiz!.passingScore}%' : ''}'
                          : 'No questions yet.',
                      style: handoverText(context, 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (_c.canManage)
                HandoverButton(
                  key: const ValueKey('training-quiz-write'),
                  label: n > 0 ? 'Rewrite quiz' : 'Write quiz',
                  filled: true,
                  compact: true,
                  onPressed: () => _start(questions),
                ),
            ],
          ),
          for (final (i, q) in questions.indexed)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ${q.prompt}', style: handoverText(context, 14, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  for (final option in q.options)
                    Text('\u00b7 $option', style: handoverText(context, 13, color: AppColors.textMuted)),
                ],
              ),
            ),
          if (n > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Correct answers are not shown: the API never returns the answer key, so nothing '
              'here can leak it \u2014 including to whoever wrote it.',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _editor(BuildContext context, List<TrainingQuestion> existing) {
    final drafts = _drafts!;
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  existing.isNotEmpty ? 'Rewrite quiz' : 'Write quiz',
                  style: handoverText(context, 15, weight: FontWeight.w600),
                ),
              ),
              HandoverButton(
                label: 'Cancel',
                compact: true,
                onPressed: () => setState(() => _drafts = null),
              ),
              const SizedBox(width: 8),
              HandoverButton(
                key: const ValueKey('training-quiz-save'),
                label: _saving ? 'Saving…' : 'Save quiz',
                filled: true,
                compact: true,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
          if (existing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.urgentBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Saving replaces the whole quiz. The answer key cannot be read back from the API, '
                'so every correct answer has to be marked again \u2014 and past attempts keep the '
                'score they were marked with.',
                style: handoverText(context, 13, color: AppColors.urgentAmber),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            TrainingInlineError(_error!, key: const ValueKey('training-quiz-error')),
          ],
          for (final (i, draft) in drafts.indexed)
            _DraftEditor(
              key: ValueKey('training-quiz-draft-$_generation-${identityHashCode(draft)}'),
              number: i + 1,
              draft: draft,
              onRemove: () => setState(() => drafts.removeAt(i)),
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: HandoverButton(
              key: const ValueKey('training-quiz-add-question'),
              label: 'Add question',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: () => setState(() => drafts.add(TrainingQuizDraft())),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftEditor extends StatefulWidget {
  final int number;
  final TrainingQuizDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _DraftEditor({
    super.key,
    required this.number,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<_DraftEditor> {
  TrainingQuizDraft get _d => widget.draft;
  late final _prompt = TextEditingController(text: _d.prompt);
  late final List<TextEditingController> _options = [
    for (final o in _d.options) TextEditingController(text: o),
  ];

  @override
  void dispose() {
    _prompt.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  void _toggleCorrect(int index) => _update(() {
        final single = _d.type != 'multi_choice';
        _d.correct = _d.correct.contains(index)
            ? _d.correct.where((c) => c != index).toList()
            : single
                ? [index]
                : [..._d.correct, index];
      });

  @override
  Widget build(BuildContext context) {
    final typeLabel = TrainingLabels.quizQuestionTypes
        .firstWhere((t) => t.$1 == _d.type, orElse: () => TrainingLabels.quizQuestionTypes.first)
        .$2;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
                  style: handoverText(context, 13, weight: FontWeight.w600, color: AppColors.infoBlue),
                ),
              ),
              Semantics(
                label: 'Remove question ${widget.number}',
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.criticalRed),
                ),
              ),
            ],
          ),
          TrainingTextField(
            key: ValueKey('training-quiz-prompt-${widget.number}'),
            label: 'Prompt',
            controller: _prompt,
            onChanged: (v) => _update(() => _d.prompt = v),
          ),
          const SizedBox(height: 12),
          HandoverSelect(
            label: 'Type',
            value: typeLabel,
            placeholder: '',
            onTap: () async {
              final picked = await pickHandoverOption(
                context,
                title: 'Type',
                options: TrainingLabels.quizQuestionTypes,
                selected: _d.type,
              );
              if (picked == null) return;
              _update(() {
                _d.type = picked;
                if (picked != 'multi_choice') _d.correct = _d.correct.take(1).toList();
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Options \u2014 tick the correct one',
            style: handoverText(context, 13, weight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          for (final (i, controller) in _options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Semantics(
                    label: 'Option ${i + 1} is correct',
                    child: Checkbox(
                      key: ValueKey('training-quiz-correct-${widget.number}-$i'),
                      value: _d.correct.contains(i),
                      activeColor: AppColors.secondaryTeal,
                      onChanged: (_) => _toggleCorrect(i),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      key: ValueKey('training-quiz-option-${widget.number}-$i'),
                      controller: controller,
                      onChanged: (v) => _update(() => _d.options[i] = v),
                      style: handoverText(context, 13.5),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Option ${i + 1}',
                        hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  if (_options.length > 2)
                    Semantics(
                      label: 'Remove option ${i + 1}',
                      button: true,
                      excludeSemantics: true,
                      child: IconButton(
                        onPressed: () => _update(() {
                          _d.options.removeAt(i);
                          _options.removeAt(i).dispose();
                          _d.correct = [
                            for (final c in _d.correct)
                              if (c != i) c > i ? c - 1 : c,
                          ];
                        }),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: HandoverButton(
              label: 'Add option',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: () => _update(() {
                _d.options.add('');
                _options.add(TextEditingController());
              }),
            ),
          ),
        ],
      ),
    );
  }
}
