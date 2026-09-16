import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import 'staff_training_certificates_page.dart';

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
  String? _error;
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
    final result = await _repository.submitQuizAttempt(
      courseId: widget.courseId,
      answers: answers,
    );
    result.when(
      success: (body) {
        final passed = JsonCodec.boolean(body['passed']) ?? true;
        Get.snackbar(
          passed ? 'Quiz submitted' : 'Attempt recorded',
          passed
              ? 'Great work — check Certificates.'
              : 'Review the material and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        if (passed) {
          Get.to(() => const StaffTrainingCertificatesPage());
        }
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not submit quiz',
      ),
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
                      onPressed: _questions.isEmpty ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                      ),
                      child: const Text('Submit quiz'),
                    ),
                  ],
                ),
    );
  }
}
