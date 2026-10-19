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

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _load();
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
          _loading = false;
        });
      },
      failure: (err) => setState(() {
        _error = err.message;
        _loading = false;
      }),
    );
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

  @override
  Widget build(BuildContext context) {
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final q in _questions) ...[
                      Text(
                        JsonCodec.stringOr(q['prompt'], 'Question'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        JsonCodec.unwrapList(q['options']).length,
                        (index) {
                          final id = JsonCodec.stringOr(q['id'], '');
                          final option = q['options'][index].toString();
                          final selected = _selectedIndex[id] == index;
                          return ListTile(
                            leading: Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? AppColors.secondaryTeal
                                  : AppColors.textMuted,
                            ),
                            title: Text(option),
                            onTap: () =>
                                setState(() => _selectedIndex[id] = index),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed: _questions.isEmpty || _submitting
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
                          : const Text('Submit quiz'),
                    ),
                  ],
                ),
    );
  }
}
