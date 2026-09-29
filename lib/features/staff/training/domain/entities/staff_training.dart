import 'package:flutter/foundation.dart';

@immutable
class StaffTrainingSummary {
  final int assignments;
  final int completed;
  final int outstanding;
  final int overdue;
  final int mandatoryOutstanding;

  const StaffTrainingSummary({
    this.assignments = 0,
    this.completed = 0,
    this.outstanding = 0,
    this.overdue = 0,
    this.mandatoryOutstanding = 0,
  });
}

@immutable
class StaffTrainingCourse {
  final String id;
  final String title;
  final String description;
  final String? materialUrl;
  final String? materialType;
  final bool isActive;
  final String? category;
  final int? validityMonths;
  final int? passingScore;
  final bool certificateRequired;
  final int? attemptsAllowed;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final List<StaffTrainingAssignment> assignments;

  const StaffTrainingCourse({
    required this.id,
    required this.title,
    this.description = '',
    this.materialUrl,
    this.materialType,
    this.isActive = true,
    this.category,
    this.validityMonths,
    this.passingScore,
    this.certificateRequired = false,
    this.attemptsAllowed,
    this.createdAt,
    this.deletedAt,
    this.assignments = const [],
  });

  bool get isArchived => deletedAt != null;

  String get shortCode {
    final compact = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final slice = compact.length <= 8
        ? compact
        : compact.substring(0, 8);
    return 'TRN-${slice.toUpperCase()}';
  }

  String get statusLabel {
    if (isArchived) return 'Archived';
    return isActive ? 'Active' : 'Completed';
  }

  String get materialLabel {
    final type = materialType?.trim();
    if (type != null && type.isNotEmpty) return type;
    if (materialUrl != null && materialUrl!.isNotEmpty) return 'Link';
    return '—';
  }

  String get quizLabel =>
      passingScore != null || (attemptsAllowed != null && attemptsAllowed! > 0)
          ? 'Yes'
          : '—';

  String get certificateLabel =>
      certificateRequired ? 'Required' : 'Not required';

  String get createdLabel {
    final at = createdAt;
    if (at == null) return '—';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  StaffTrainingCourseMetrics get metrics {
    final all = assignments;
    var completed = 0;
    var inProgress = 0;
    var overdue = 0;
    for (final a in all) {
      if (a.isCompleted) {
        completed++;
      } else if (a.isOverdue) {
        overdue++;
      } else if (a.isInProgress) {
        inProgress++;
      }
    }
    return StaffTrainingCourseMetrics(
      assigned: all.length,
      completed: completed,
      inProgress: inProgress,
      overdue: overdue,
    );
  }
}

@immutable
class StaffTrainingCourseMetrics {
  final int assigned;
  final int completed;
  final int inProgress;
  final int overdue;
  final int certificatesIssued;

  const StaffTrainingCourseMetrics({
    this.assigned = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.overdue = 0,
    this.certificatesIssued = 0,
  });

  StaffTrainingCourseMetrics copyWith({int? certificatesIssued}) {
    return StaffTrainingCourseMetrics(
      assigned: assigned,
      completed: completed,
      inProgress: inProgress,
      overdue: overdue,
      certificatesIssued: certificatesIssued ?? this.certificatesIssued,
    );
  }
}

@immutable
class StaffTrainingAssignment {
  final String id;
  final String courseId;
  final String? staffId;
  final String staffName;
  final String status;
  final bool mandatory;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime? startedAt;
  final String? courseTitle;

  const StaffTrainingAssignment({
    required this.id,
    this.courseId = '',
    this.staffId,
    this.staffName = '',
    this.status = '',
    this.mandatory = false,
    this.dueAt,
    this.completedAt,
    this.startedAt,
    this.courseTitle,
  });

  String get statusNormalized => status.trim().toLowerCase().replaceAll(' ', '_');

  bool get isCompleted =>
      completedAt != null ||
      statusNormalized == 'completed' ||
      statusNormalized == 'complete' ||
      statusNormalized == 'passed';

  bool get isInProgress =>
      !isCompleted &&
      (statusNormalized == 'in_progress' ||
          statusNormalized == 'in-progress' ||
          statusNormalized == 'started' ||
          startedAt != null);

  bool get isOverdue {
    if (isCompleted) return false;
    if (statusNormalized == 'overdue') return true;
    final due = dueAt;
    if (due == null) return false;
    return due.toLocal().isBefore(DateTime.now());
  }

  String get statusLabel {
    if (status.trim().isEmpty) {
      if (isCompleted) return 'Completed';
      if (isOverdue) return 'Overdue';
      if (isInProgress) return 'In progress';
      return 'Assigned';
    }
    final raw = status.trim();
    if (raw.contains('_') || raw.contains('-')) {
      return raw
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .split(' ')
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
          .join(' ');
    }
    return raw;
  }

  String get dueLabel {
    final due = dueAt;
    if (due == null) return '';
    final local = due.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  String get completedLabel {
    final at = completedAt;
    if (at == null) return '';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }
}

@immutable
class StaffTrainingCertificate {
  final String id;
  final String courseId;
  final String courseName;
  final String staffName;
  final String status;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  const StaffTrainingCertificate({
    required this.id,
    this.courseId = '',
    this.courseName = '',
    this.staffName = '',
    this.status = '',
    this.issuedAt,
    this.expiresAt,
  });

  String get issuedLabel {
    final at = issuedAt;
    if (at == null) return '—';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  String get expiresLabel {
    final at = expiresAt;
    if (at == null) return 'No expiry';
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }
}

@immutable
class StaffTrainingCoursesPage {
  final List<StaffTrainingCourse> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const StaffTrainingCoursesPage({
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });
}

@immutable
class StaffTrainingAssignmentsPage {
  final List<StaffTrainingAssignment> items;
  final StaffTrainingSummary summary;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const StaffTrainingAssignmentsPage({
    this.items = const [],
    this.summary = const StaffTrainingSummary(),
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });
}

@immutable
class StaffTrainingCertificatesPageResult {
  final List<StaffTrainingCertificate> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const StaffTrainingCertificatesPageResult({
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });
}
