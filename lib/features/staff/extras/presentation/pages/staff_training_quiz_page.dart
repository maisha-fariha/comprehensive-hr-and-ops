import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import 'staff_training_certificates_page.dart';

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;

  const _ResultStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class StaffTrainingQuizPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const StaffTrainingQuizPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<StaffTrainingQuizPage> createState() => _StaffTrainingQuizPageState();
}

class _StaffTrainingQuizPageState extends State<StaffTrainingQuizPage> {
  late final StaffExtrasRepository _repository;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int? _passingScore;
  int? _attemptsAllowed;
  List<Map<String, dynamic>> _questions = const [];
  final Map<String, int> _selectedIndex = {};

  /// Index into [_questions], or `-1` for the web Examination Review step.
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _load();
  }

  bool get _onReview => _step < 0;

  int get _answeredCount {
    var n = 0;
    for (final q in _questions) {
      final id = JsonCodec.string(q['id']);
      if (id != null && _selectedIndex.containsKey(id)) n++;
    }
    return n;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getCourseQuiz(widget.courseId);
    if (!mounted) return;
    result.when(
      success: (json) {
        final raw = JsonCodec.unwrapList(json['questions']);
        final questions = raw.whereType<Map>().map(JsonCodec.asMap).toList();
        setState(() {
          _questions = questions;
          _passingScore = JsonCodec.integer(json['passingScore']);
          _attemptsAllowed = JsonCodec.integer(json['attemptsAllowed']);
          _step = questions.isEmpty ? -1 : 0;
          _loading = false;
        });
      },
      failure: (err) => setState(() {
        _error = err.message;
        _loading = false;
      }),
    );
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _step = index);
  }

  void _openReview() => setState(() => _step = -1);

  void _previous() {
    if (_onReview) {
      if (_questions.isNotEmpty) _goToQuestion(_questions.length - 1);
      return;
    }
    if (_step > 0) _goToQuestion(_step - 1);
  }

  Future<void> _submit() async {
    final answers = <Map<String, dynamic>>[];
    for (final q in _questions) {
      final id = JsonCodec.string(q['id']);
      if (id == null) continue;
      final selected = _selectedIndex[id];
      if (selected == null) {
        Get.snackbar(
          'Incomplete',
          'Answer every question.',
          snackPosition: SnackPosition.BOTTOM,
        );
        // Jump to first unanswered so Review → Edit stays useful.
        final idx = _questions.indexWhere((row) {
          final qid = JsonCodec.string(row['id']);
          return qid != null && !_selectedIndex.containsKey(qid);
        });
        if (idx >= 0) _goToQuestion(idx);
        return;
      }
      answers.add({
        'questionId': id,
        'selected': [selected],
      });
    }
    setState(() => _submitting = true);
    final result = await _repository.submitQuizAttempt(
      courseId: widget.courseId,
      answers: answers,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (body) => _showResult(body),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not submit quiz',
      ),
    );
  }

  /// Web result modal: score, pass mark, attempt, and status.
  Future<void> _showResult(Map<String, dynamic> body) async {
    final nested = body['attempt'];
    final attempt = nested is Map ? JsonCodec.asMap(nested) : body;
    final score = JsonCodec.integer(attempt['score'] ?? body['score']);
    final passed =
        JsonCodec.boolean(attempt['passed'] ?? body['passed']) ?? false;
    final attemptNo = JsonCodec.integer(
      attempt['attemptNo'] ?? body['attemptNo'],
    );
    final passMark = JsonCodec.integer(
      attempt['passingScore'] ?? body['passingScore'] ?? _passingScore,
    );
    final allowed = JsonCodec.integer(
      attempt['attemptsAllowed'] ?? body['attemptsAllowed'] ?? _attemptsAllowed,
    );
    final scoreLabel = score == null ? '—' : '$score%';
    final passLabel = passMark == null ? '—' : '$passMark%';
    final attemptLabel = attemptNo == null
        ? '—'
        : allowed == null
            ? '$attemptNo'
            : '$attemptNo of $allowed';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.85;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Interactive Quiz Examination',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Examination results and marking feedback.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    passed ? 'Assessment Passed' : 'Assessment Not Passed',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: passed
                          ? AppColors.secondaryTeal
                          : AppColors.criticalRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You scored $scoreLabel. The required pass mark is $passLabel.',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ResultStat(label: 'Your score', value: scoreLabel),
                  _ResultStat(label: 'Pass mark', value: passLabel),
                  _ResultStat(label: 'Attempt', value: attemptLabel),
                  _ResultStat(
                    label: 'Status',
                    value: passed ? 'Passed' : 'Failed',
                  ),
                  const SizedBox(height: 8),
                  if (!passed)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                        ),
                        child: const Text('Retake Quiz'),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _questionTitle(Map<String, dynamic> q, int index) {
    final prompt = JsonCodec.stringOr(q['prompt'], 'Question');
    if (prompt.trim().isEmpty) return 'Question ${index + 1}';
    return prompt;
  }

  @override
  Widget build(BuildContext context) {
    final passLabel = _passingScore == null ? '—' : '$_passingScore%';
    final total = _questions.length;
    final answered = _answeredCount;
    final progress = total == 0 ? 0.0 : answered / total;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.courseTitle),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        actions: [
          IconButton(
            tooltip: 'Certificates',
            onPressed: () =>
                Get.to(() => const StaffTrainingCertificatesPage()),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        children: [
                          const Text(
                            'Interactive Quiz Examination',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.textHeading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pass requirement: $passLabel. Marked on the server upon submission.',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                _onReview
                                    ? 'Review'
                                    : 'Question ${_step + 1} of $total',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$answered of $total answered '
                                '(${total == 0 ? 0 : (progress * 100).round()}%)',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.cardBorder,
                              color: AppColors.secondaryTeal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < total; i++)
                                _NavChip(
                                  label: '${i + 1}',
                                  selected: !_onReview && _step == i,
                                  answered: () {
                                    final id = JsonCodec.string(
                                      _questions[i]['id'],
                                    );
                                    return id != null &&
                                        _selectedIndex.containsKey(id);
                                  }(),
                                  onTap: () => _goToQuestion(i),
                                ),
                              _NavChip(
                                key: const Key('quiz-review'),
                                label: 'Review',
                                selected: _onReview,
                                answered: answered == total && total > 0,
                                onTap: _openReview,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_onReview)
                            _ReviewPanel(
                              questions: _questions,
                              selectedIndex: _selectedIndex,
                              titleFor: _questionTitle,
                              onEdit: _goToQuestion,
                            )
                          else if (total > 0)
                            _QuestionPanel(
                              question: _questions[_step],
                              selected: () {
                                final id = JsonCodec.string(
                                  _questions[_step]['id'],
                                );
                                return id == null
                                    ? null
                                    : _selectedIndex[id];
                              }(),
                              onSelect: (index) {
                                final id = JsonCodec.string(
                                  _questions[_step]['id'],
                                );
                                if (id == null) return;
                                setState(() => _selectedIndex[id] = index);
                              },
                            ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: (_onReview && total == 0) ||
                                      (!_onReview && _step == 0)
                                  ? null
                                  : _previous,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Previous'),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              key: const Key('quiz-submit'),
                              onPressed: total == 0 || _submitting
                                  ? null
                                  : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.secondaryTeal,
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
                                  : const Text('Submit Quiz'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool answered;
  final VoidCallback onTap;

  const _NavChip({
    super.key,
    required this.label,
    required this.selected,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.secondaryTeal
        : answered
            ? AppColors.secondaryTeal.withValues(alpha: 0.12)
            : AppColors.surfaceWhite;
    final fg = selected
        ? Colors.white
        : answered
            ? AppColors.secondaryTeal
            : AppColors.textHeading;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.secondaryTeal : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  final Map<String, dynamic> question;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _QuestionPanel({
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = JsonCodec.unwrapList(question['options']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          JsonCodec.stringOr(question['prompt'], 'Question'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < options.length; index++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              selected == index
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected == index
                  ? AppColors.secondaryTeal
                  : AppColors.textMuted,
            ),
            title: Text(options[index].toString()),
            onTap: () => onSelect(index),
          ),
      ],
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Map<String, int> selectedIndex;
  final String Function(Map<String, dynamic> q, int index) titleFor;
  final ValueChanged<int> onEdit;

  const _ReviewPanel({
    required this.questions,
    required this.selectedIndex,
    required this.titleFor,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final answered = questions.where((q) {
      final id = JsonCodec.string(q['id']);
      return id != null && selectedIndex.containsKey(id);
    }).length;
    final allDone = answered == questions.length && questions.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Examination Review',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Text(
                allDone
                    ? 'All questions answered'
                    : '$answered of ${questions.length} answered',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: allDone
                      ? AppColors.secondaryTeal
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < questions.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            Builder(
              builder: (context) {
                final q = questions[i];
                final id = JsonCodec.string(q['id']);
                final sel = id == null ? null : selectedIndex[id];
                final status = sel == null
                    ? 'Not answered'
                    : '${sel + 1} selected';
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${i + 1} ${titleFor(q, i)}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: AppColors.textHeading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: sel == null
                                  ? AppColors.criticalRed
                                  : AppColors.secondaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onEdit(i),
                      child: const Text('Edit'),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
