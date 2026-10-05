import 'package:flutter/foundation.dart';

@immutable
class TrainingStaffRef {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? categoryName;
  final String? residenceName;

  const TrainingStaffRef({
    required this.id,
    this.firstName,
    this.lastName,
    this.categoryName,
    this.residenceName,
  });

  String get name => [firstName, lastName]
      .whereType<String>()
      .where((p) => p.isNotEmpty)
      .join(' ')
      .trim();
}

@immutable
class TrainingAssignment {
  final String id;
  final String courseId;
  final String staffId;
  final TrainingStaffRef? staff;
  final String status;
  final DateTime? completedAt;
  final DateTime? dueAt;
  final bool mandatory;
  final DateTime? createdAt;

  const TrainingAssignment({
    required this.id,
    required this.courseId,
    required this.staffId,
    this.staff,
    this.status = 'assigned',
    this.completedAt,
    this.dueAt,
    this.mandatory = false,
    this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  bool isOverdueAt(DateTime now) =>
      !isCompleted && dueAt != null && dueAt!.isBefore(now);
}

@immutable
class TrainingCourse {
  final String id;
  final String title;
  final String? description;
  final String? materialUrl;
  final String? materialType;
  final String? category;
  final int? validityMonths;
  final int? passingScore;
  final int? attemptsAllowed;
  final bool certificateRequired;

  /// `null` counts as active, like the web (`isActive === false` is archived).
  final bool? isActive;
  final DateTime? createdAt;
  final List<TrainingAssignment> assignments;

  const TrainingCourse({
    required this.id,
    required this.title,
    this.description,
    this.materialUrl,
    this.materialType,
    this.category,
    this.validityMonths,
    this.passingScore,
    this.attemptsAllowed,
    this.certificateRequired = false,
    this.isActive,
    this.createdAt,
    this.assignments = const [],
  });

  bool get isArchived => isActive == false;
}

@immutable
class TrainingSummary {
  final int assignments;
  final int completed;
  final int outstanding;
  final int overdue;
  final int mandatoryOutstanding;

  const TrainingSummary({
    this.assignments = 0,
    this.completed = 0,
    this.outstanding = 0,
    this.overdue = 0,
    this.mandatoryOutstanding = 0,
  });
}

@immutable
class TrainingPage<T> {
  final List<T> items;
  final int total;
  final int totalPages;
  final TrainingSummary? summary;

  const TrainingPage({
    this.items = const [],
    this.total = 0,
    this.totalPages = 1,
    this.summary,
  });
}

@immutable
class TrainingQuestion {
  final String id;
  final String prompt;

  /// `single_choice`, `multi_choice` or `true_false`.
  final String type;
  final List<String> options;
  final int? position;

  /// Indexes into [options]. Only the authored-questions read carries them.
  final List<int> correct;

  const TrainingQuestion({
    required this.id,
    required this.prompt,
    required this.type,
    required this.options,
    this.position,
    this.correct = const [],
  });
}

@immutable
class TrainingQuiz {
  final String courseId;
  final int? passingScore;
  final int? attemptsAllowed;
  final List<TrainingQuestion> questions;

  const TrainingQuiz({
    required this.courseId,
    this.passingScore,
    this.attemptsAllowed,
    this.questions = const [],
  });
}

@immutable
class TrainingAttempt {
  final String id;
  final String courseId;
  final String staffId;
  final int score;
  final bool passed;
  final int? attemptNo;
  final DateTime? submittedAt;

  const TrainingAttempt({
    required this.id,
    required this.courseId,
    required this.staffId,
    required this.score,
    required this.passed,
    this.attemptNo,
    this.submittedAt,
  });
}

@immutable
class TrainingAttemptResult {
  final TrainingAttempt attempt;
  final bool certificateIssued;

  const TrainingAttemptResult({
    required this.attempt,
    required this.certificateIssued,
  });
}

@immutable
class TrainingCertificate {
  final String id;
  final String courseId;
  final String staffId;
  final String? staffFirstName;
  final String? staffLastName;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  /// `approved`, `submitted` or `rejected`.
  final String? reviewStatus;

  /// `valid`, `expiring` or `expired`.
  final String? expiryStatus;
  final String? certificateNumber;
  final String? provider;
  final String? fileUrl;
  final String? reviewNotes;

  const TrainingCertificate({
    required this.id,
    required this.courseId,
    required this.staffId,
    this.staffFirstName,
    this.staffLastName,
    this.issuedAt,
    this.expiresAt,
    this.reviewStatus,
    this.expiryStatus,
    this.certificateNumber,
    this.provider,
    this.fileUrl,
    this.reviewNotes,
  });

  String get staffName => [staffFirstName, staffLastName]
      .whereType<String>()
      .where((p) => p.isNotEmpty)
      .join(' ');
}

@immutable
class TrainingAuditEntry {
  final String id;
  final String? action;
  final String? outcome;
  final String? actorName;
  final DateTime? createdAt;

  const TrainingAuditEntry({
    required this.id,
    this.action,
    this.outcome,
    this.actorName,
    this.createdAt,
  });
}

@immutable
class TrainingStaffOption {
  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final List<String> residenceIds;
  final String? firstResidenceName;

  const TrainingStaffOption({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.residenceIds = const [],
    this.firstResidenceName,
  });

  /// "Category · Residence", or "Staff" when neither is on file.
  String get role {
    final parts = [categoryName, firstResidenceName]
        .whereType<String>()
        .where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Staff' : parts.join(' · ');
  }
}

@immutable
class TrainingOption {
  final String id;
  final String label;

  const TrainingOption({required this.id, required this.label});
}
