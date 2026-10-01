import 'package:flutter/foundation.dart';

import 'hr_training.dart';

@immutable
class TrainingCourseStats {
  final int assigned;
  final int completed;
  final int inProgress;
  final int overdue;
  final int certificatesIssued;

  const TrainingCourseStats({
    this.assigned = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.overdue = 0,
    this.certificatesIssued = 0,
  });

  int get percentComplete =>
      assigned > 0 ? (completed / assigned * 100).round() : 0;
}

@immutable
class TrainingStaffProgress {
  final String id;
  final String staffName;
  final String initials;
  final String role;
  final String residence;

  /// "Completed", "In Progress", "Overdue" or "Not Started".
  final String status;
  final int? quizScore;
  final bool certificateIssued;
  final DateTime? dueAt;
  final DateTime? completedAt;

  const TrainingStaffProgress({
    required this.id,
    required this.staffName,
    required this.initials,
    required this.role,
    required this.residence,
    required this.status,
    this.quizScore,
    this.certificateIssued = false,
    this.dueAt,
    this.completedAt,
  });
}

@immutable
class TrainingContentItem {
  final String id;

  /// "Video", "PDF" or "Document".
  final String type;
  final String title;
  final String url;

  const TrainingContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.url,
  });
}

@immutable
class TrainingHistoryItem {
  final String id;

  /// "Published", "Assigned", "Completed" or "Updated".
  final String action;
  final String title;
  final String description;
  final String? actor;
  final DateTime? timestamp;

  const TrainingHistoryItem({
    required this.id,
    required this.action,
    required this.title,
    required this.description,
    this.actor,
    this.timestamp,
  });
}

String trainingHumanise(String? value) {
  if (value == null || value.isEmpty) return '—';
  final text = value.replaceAll(RegExp(r'[_-]+'), ' ');
  return text[0].toUpperCase() + text.substring(1);
}

String trainingInitials(String name) => name
    .split(' ')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0])
    .take(2)
    .join()
    .toUpperCase();

/// Port of the web `toCourseView`: everything the detail page and the course
/// cards read is derived here from the raw API records.
@immutable
class TrainingCourseView {
  final TrainingCourse course;
  final String code;
  final String category;

  /// "Course", "Document" or "Video".
  final String type;

  /// "Active" or "Archived".
  final String status;
  final bool mandatory;
  final bool required;

  /// "No Expiry", "1 Year", "2 Years" or "Custom".
  final String expiryPeriod;
  final int? customDurationMonths;
  final TrainingCourseStats stats;
  final List<TrainingContentItem> content;
  final bool quizEnabled;
  final List<TrainingQuestion> questions;
  final List<TrainingStaffProgress> staffProgress;
  final List<TrainingHistoryItem> history;

  /// "Overdue", "Completed" or "Pending".
  final String cardBadge;

  const TrainingCourseView._({
    required this.course,
    required this.code,
    required this.category,
    required this.type,
    required this.status,
    required this.mandatory,
    required this.required,
    required this.expiryPeriod,
    required this.customDurationMonths,
    required this.stats,
    required this.content,
    required this.quizEnabled,
    required this.questions,
    required this.staffProgress,
    required this.history,
    required this.cardBadge,
  });

  String get id => course.id;
  String get title => course.title;
  String get description => course.description ?? '';

  static String codeFor(String id) =>
      'TRN-${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}';

  factory TrainingCourseView.from(
    TrainingCourse course, {
    List<TrainingAssignment>? assignments,
    List<TrainingAttempt> attempts = const [],
    List<TrainingCertificate> certificates = const [],
    List<TrainingQuestion> questions = const [],
    List<TrainingHistoryItem> history = const [],
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final rows = assignments ?? course.assignments;
    final stats = TrainingCourseStats(
      assigned: rows.length,
      completed: rows.where((a) => a.status == 'completed').length,
      inProgress: rows.where((a) => a.status == 'in_progress').length,
      overdue: rows.where((a) => a.isOverdueAt(at)).length,
      certificatesIssued:
          certificates.where((c) => c.reviewStatus == 'approved').length,
    );

    final best = <String, int>{};
    for (final attempt in attempts) {
      final current = best[attempt.staffId];
      if (current == null || attempt.score > current) {
        best[attempt.staffId] = attempt.score;
      }
    }
    final certified = {
      for (final c in certificates)
        if (c.reviewStatus != 'rejected') c.staffId,
    };

    final validity = course.validityMonths;
    final material = course.materialUrl;
    return TrainingCourseView._(
      course: course,
      code: codeFor(course.id),
      category: course.category ?? 'Uncategorised',
      type: switch (course.materialType) {
        'video' => 'Video',
        'document' => 'Document',
        _ => 'Course',
      },
      status: course.isArchived ? 'Archived' : 'Active',
      mandatory: rows.any((a) => a.mandatory),
      required: course.certificateRequired,
      expiryPeriod: switch (validity) {
        null => 'No Expiry',
        12 => '1 Year',
        24 => '2 Years',
        _ => 'Custom',
      },
      customDurationMonths:
          validity != null && validity != 12 && validity != 24 ? validity : null,
      stats: stats,
      content: material == null || material.isEmpty
          ? const []
          : [
              TrainingContentItem(
                id: '${course.id}-material',
                type: switch (course.materialType) {
                  'video' => 'Video',
                  'document' => 'PDF',
                  _ => 'Document',
                },
                title: course.title,
                url: material,
              ),
            ],
      quizEnabled: questions.isNotEmpty || course.passingScore != null,
      questions: questions,
      staffProgress: [
        for (final a in rows)
          () {
            final staff = a.staff;
            final name = staff == null ? 'Staff no longer on file' : staff.name;
            return TrainingStaffProgress(
              id: a.id,
              staffName: name,
              initials: trainingInitials(name),
              role: staff?.categoryName ?? '—',
              residence: staff?.residenceName ?? '—',
              status: a.status == 'completed'
                  ? 'Completed'
                  : a.status == 'in_progress'
                      ? 'In Progress'
                      : a.dueAt != null && a.dueAt!.isBefore(at)
                          ? 'Overdue'
                          : 'Not Started',
              quizScore: best[a.staffId],
              certificateIssued: certified.contains(a.staffId),
              dueAt: a.dueAt,
              completedAt: a.completedAt,
            );
          }(),
      ],
      history: history,
      cardBadge: stats.overdue > 0
          ? 'Overdue'
          : stats.assigned == stats.completed && stats.assigned > 0
              ? 'Completed'
              : 'Pending',
    );
  }

  /// Port of the web `toHistory` over audit-log rows.
  static List<TrainingHistoryItem> historyFrom(List<TrainingAuditEntry> rows) => [
        for (final row in rows)
          () {
            final action = row.action ?? '';
            return TrainingHistoryItem(
              id: row.id,
              action: action.endsWith('create')
                  ? 'Published'
                  : action.contains('assignment')
                      ? 'Assigned'
                      : action.contains('attempt') || action.contains('complete')
                          ? 'Completed'
                          : 'Updated',
              title: trainingHumanise(action.replaceAll('.', ' ')),
              description: row.outcome == 'success'
                  ? ''
                  : 'Outcome: ${row.outcome ?? 'unknown'}',
              actor: row.actorName,
              timestamp: row.createdAt,
            );
          }(),
      ];
}
