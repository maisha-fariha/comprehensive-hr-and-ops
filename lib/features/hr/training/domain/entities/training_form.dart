import 'dart:math' as math;

import 'hr_training.dart';
import 'training_course_view.dart';

class TrainingFormQuestion {
  final String id;
  String question;

  /// "Multiple Choice" or "True / False".
  String type;
  List<String> options;
  String correctAnswer;

  TrainingFormQuestion({
    required this.id,
    this.question = '',
    this.type = 'Multiple Choice',
    List<String>? options,
    this.correctAnswer = '',
  }) : options = options ?? ['', ''];

  TrainingFormQuestion copy() => TrainingFormQuestion(
        id: id,
        question: question,
        type: type,
        options: [...options],
        correctAnswer: correctAnswer,
      );
}

/// A question being written on the course page's Quiz tab.
class TrainingQuizDraft {
  String prompt;

  /// `single_choice`, `multi_choice` or `true_false`.
  String type;
  List<String> options;
  List<int> correct;

  TrainingQuizDraft({
    this.prompt = '',
    this.type = 'single_choice',
    List<String>? options,
    List<int>? correct,
  })  : options = options ?? ['', ''],
        correct = correct ?? [];

  /// The web quiz editor's checks, in its order; null when the quiz can save.
  static String? validate(List<TrainingQuizDraft> drafts) {
    for (final (i, q) in drafts.indexed) {
      final n = i + 1;
      if (q.prompt.trim().isEmpty) return 'Question $n has no prompt.';
      if (q.options.map((o) => o.trim()).where((o) => o.isNotEmpty).length < 2) {
        return 'Question $n needs at least two options.';
      }
      if (q.correct.isEmpty) return 'Question $n has no correct answer marked.';
      if (q.type != 'multi_choice' && q.correct.length > 1) {
        return 'Question $n allows only one correct answer — change its type or unmark one.';
      }
    }
    return null;
  }

  static Map<String, dynamic> body(List<TrainingQuizDraft> drafts) => {
        'questions': [
          for (final (i, q) in drafts.indexed)
            {
              'prompt': q.prompt.trim(),
              'type': q.type,
              'options': [
                for (final o in q.options)
                  if (o.trim().isNotEmpty) o.trim(),
              ],
              'correct': q.correct,
              'position': i,
            },
        ],
      };
}

class TrainingMaterialFile {
  final String path;
  final String name;
  final int size;

  const TrainingMaterialFile({
    required this.path,
    required this.name,
    required this.size,
  });
}

/// The web `trainingFormSchema` values for the "Create New Training" /
/// "Edit Training" wizard.
class TrainingFormValues {
  String title;
  String category;

  /// "Course", "Document" or "Video".
  String type;
  String description;

  /// "No Expiry", "1 Year", "2 Years" or "Custom".
  String expiryPeriod;
  int? customDurationValue;

  /// "Months" or "Years".
  String customDurationUnit;
  bool certificateRequired;
  TrainingMaterialFile? materialFile;
  String materialUrl;
  bool quizEnabled;
  List<TrainingFormQuestion> questions;
  int passingScore;
  int attemptsAllowed;

  /// "All Staff", "Specific Roles", "Specific Residence" or "Individual Staff".
  String assignTo;
  List<String> roles;
  List<String> residences;
  List<String> staffIds;
  bool mandatory;
  DateTime? dueDate;

  TrainingFormValues({
    this.title = '',
    this.category = '',
    this.type = 'Course',
    this.description = '',
    this.expiryPeriod = '1 Year',
    this.customDurationValue,
    this.customDurationUnit = 'Months',
    this.certificateRequired = false,
    this.materialFile,
    this.materialUrl = '',
    this.quizEnabled = true,
    List<TrainingFormQuestion>? questions,
    this.passingScore = 80,
    this.attemptsAllowed = 3,
    this.assignTo = 'Individual Staff',
    List<String>? roles,
    List<String>? residences,
    List<String>? staffIds,
    this.mandatory = true,
    this.dueDate,
  })  : questions = questions ?? [],
        roles = roles ?? [],
        residences = residences ?? [],
        staffIds = staffIds ?? [];

  /// Web `trainingToFormValues`.
  factory TrainingFormValues.fromView(TrainingCourseView view) {
    final course = view.course;
    return TrainingFormValues(
      title: course.title,
      category: view.category == 'Uncategorised' ? '' : view.category,
      type: view.type,
      description: view.description,
      expiryPeriod: view.expiryPeriod,
      customDurationValue: view.customDurationMonths,
      certificateRequired: view.required,
      materialUrl: view.content.isEmpty ? '' : view.content.first.url,
      quizEnabled: view.quizEnabled,
      questions: [
        for (final q in view.questions)
          TrainingFormQuestion(
            id: q.id,
            question: q.prompt,
            type: q.type == 'true_false' ? 'True / False' : 'Multiple Choice',
            options: [...q.options],
            correctAnswer: () {
              final index = q.correct.isEmpty ? 0 : q.correct.first;
              return index >= 0 && index < q.options.length ? q.options[index] : '';
            }(),
          ),
      ],
      passingScore: (course.passingScore ?? 0) == 0 ? 80 : course.passingScore!,
      attemptsAllowed:
          (course.attemptsAllowed ?? 0) == 0 ? 3 : course.attemptsAllowed!,
      mandatory: view.mandatory,
    );
  }

  int? get validityMonths => switch (expiryPeriod) {
        'No Expiry' => null,
        '1 Year' => 12,
        '2 Years' => 24,
        _ => customDurationUnit == 'Years'
            ? 12 * (customDurationValue ?? 0)
            : (customDurationValue ?? 0),
      };

  String get materialType => switch (type) {
        'Video' => 'video',
        'Document' => 'document',
        _ => 'link',
      };

  /// Web `toCourseBody`. Creating drops the null entries; editing sends them
  /// so a cleared field is cleared on the server too.
  Map<String, dynamic> toCourseBody({String? uploadedUrl, bool create = false}) {
    final description = this.description.trim();
    final category = this.category.trim();
    final link = materialUrl.trim();
    final body = <String, dynamic>{
      'title': title.trim(),
      'description': description.isEmpty ? null : description,
      'category': category.isEmpty ? null : category,
      'materialType': materialType,
      'materialUrl': uploadedUrl ?? (link.isEmpty ? null : link),
      'certificateRequired': certificateRequired,
      'passingScore': quizEnabled ? passingScore : null,
      'attemptsAllowed': quizEnabled ? attemptsAllowed : null,
      'validityMonths': validityMonths,
    };
    if (create) body.removeWhere((_, value) => value == null);
    return body;
  }

  /// Web `toQuestionsBody`.
  Map<String, dynamic> toQuestionsBody() => {
        'questions': [
          for (final (i, q) in questions.indexed)
            {
              'prompt': q.question,
              'type': q.type == 'True / False' ? 'true_false' : 'single_choice',
              'options': q.options,
              'correct': [math.max(0, q.options.indexOf(q.correctAnswer))],
              'position': i,
            },
        ],
      };

  /// Web `resolveStaffIds`: who the assignment rules reach in the directory.
  List<String> resolveStaffIds(List<TrainingStaffOption> staff) =>
      switch (assignTo) {
        'All Staff' => [for (final s in staff) s.id],
        'Specific Roles' => [
            for (final s in staff)
              if (s.categoryId != null && roles.contains(s.categoryId)) s.id,
          ],
        'Specific Residence' => [
            for (final s in staff)
              if (s.residenceIds.any(residences.contains)) s.id,
          ],
        _ => [...staffIds],
      };

  /// Web zod schema plus its `superRefine`, keyed by field.
  Map<String, String> validate() {
    final errors = <String, String>{};
    if (title.trim().isEmpty) errors['title'] = 'Training title is required';
    if (category.trim().isEmpty) errors['category'] = 'Category is required';
    if (expiryPeriod == 'Custom' && (customDurationValue ?? 0) == 0) {
      errors['customDurationValue'] = 'Say how long it stays valid';
    }
    if (quizEnabled) {
      for (final (i, q) in questions.indexed) {
        if (q.question.trim().isEmpty) {
          errors['questions'] = 'Question ${i + 1} has no prompt.';
          break;
        }
      }
    }
    if (assignTo == 'Specific Roles' && roles.isEmpty) {
      errors['roles'] = 'Pick at least one role';
    }
    if (assignTo == 'Specific Residence' && residences.isEmpty) {
      errors['residences'] = 'Pick at least one residence';
    }
    if (assignTo == 'Individual Staff' && staffIds.isEmpty) {
      errors['staffIds'] = 'Pick at least one person';
    }
    return errors;
  }
}
