import '../../../../../../core/network/iso_date_range.dart';
import '../../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_training.dart';

abstract final class StaffTrainingMapper {
  static StaffTrainingSummary summaryFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return const StaffTrainingSummary();
    final summary = JsonCodec.mapAt(meta, 'summary') ?? meta;
    return StaffTrainingSummary(
      assignments: JsonCodec.integerOr(
        summary['assignments'] ?? summary['total'],
        0,
      ),
      completed: JsonCodec.integerOr(summary['completed'], 0),
      outstanding: JsonCodec.integerOr(summary['outstanding'], 0),
      overdue: JsonCodec.integerOr(summary['overdue'], 0),
      mandatoryOutstanding: JsonCodec.integerOr(
        summary['mandatoryOutstanding'],
        0,
      ),
    );
  }

  static StaffTrainingCourse courseFromJson(
    Map<String, dynamic> json, {
    bool includeAssignments = false,
  }) {
    final assignments = includeAssignments
        ? JsonCodec.listAt(json, 'assignments')
            .whereType<Map>()
            .map((raw) => assignmentFromJson(JsonCodec.asMap(raw)))
            .toList()
        : const <StaffTrainingAssignment>[];

    return StaffTrainingCourse(
      id: JsonCodec.stringOr(json['id'], ''),
      title: JsonCodec.stringOr(json['title'] ?? json['name'], 'Course'),
      description: JsonCodec.stringOr(json['description'], ''),
      materialUrl: JsonCodec.string(json['materialUrl']),
      materialType: JsonCodec.string(json['materialType']),
      isActive: JsonCodec.boolean(json['isActive']) ?? true,
      category: JsonCodec.string(json['category']),
      validityMonths: JsonCodec.integer(json['validityMonths']),
      passingScore: JsonCodec.integer(json['passingScore']),
      certificateRequired:
          JsonCodec.boolean(json['certificateRequired']) ?? false,
      attemptsAllowed: JsonCodec.integer(json['attemptsAllowed']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      deletedAt: JsonCodec.dateTime(json['deletedAt']),
      assignments: assignments,
    );
  }

  static StaffTrainingAssignment assignmentFromJson(Map<String, dynamic> json) {
    final course = JsonCodec.mapAt(json, 'course') ?? const {};
    final staff = JsonCodec.mapAt(json, 'staff') ??
        JsonCodec.mapAt(json, 'assignee') ??
        const {};
    final fromStaff = staff.isEmpty
        ? null
        : IsoDateRange.personName(staff);
    final staffName = (fromStaff != null &&
            fromStaff.isNotEmpty &&
            fromStaff != 'Unknown')
        ? fromStaff
        : JsonCodec.stringOr(
            json['staffName'] ?? staff['name'] ?? staff['email'],
            fromStaff ?? 'Staff',
          );

    return StaffTrainingAssignment(
      id: JsonCodec.stringOr(json['id'], ''),
      courseId: JsonCodec.stringOr(
        json['courseId'] ?? course['id'],
        '',
      ),
      staffId: JsonCodec.string(json['staffId'] ?? staff['id']),
      staffName: staffName,
      status: JsonCodec.stringOr(json['status'], ''),
      mandatory: JsonCodec.boolean(json['mandatory']) ?? false,
      dueAt: JsonCodec.dateTime(json['dueAt']),
      completedAt: JsonCodec.dateTime(json['completedAt']),
      startedAt: JsonCodec.dateTime(json['startedAt']),
      courseTitle: JsonCodec.string(
        course['title'] ?? json['courseName'] ?? json['courseTitle'],
      ),
    );
  }

  static StaffTrainingCertificate certificateFromJson(
    Map<String, dynamic> json,
  ) {
    final course = JsonCodec.mapAt(json, 'course') ?? const {};
    final staff = JsonCodec.mapAt(json, 'staff') ?? const {};
    final fromStaff = staff.isEmpty ? null : IsoDateRange.personName(staff);
    final staffName = (fromStaff != null &&
            fromStaff.isNotEmpty &&
            fromStaff != 'Unknown')
        ? fromStaff
        : JsonCodec.stringOr(
            json['staffName'] ?? staff['name'],
            fromStaff ?? 'Staff',
          );

    return StaffTrainingCertificate(
      id: JsonCodec.stringOr(json['id'], ''),
      courseId: JsonCodec.stringOr(
        json['courseId'] ?? course['id'],
        '',
      ),
      courseName: JsonCodec.stringOr(
        course['title'] ?? json['courseName'] ?? json['title'] ?? json['name'],
        'Course',
      ),
      staffName: staffName,
      status: JsonCodec.stringOr(json['status'], ''),
      issuedAt: JsonCodec.dateTime(json['issuedAt'] ?? json['createdAt']),
      expiresAt: JsonCodec.dateTime(json['expiresAt']),
    );
  }

  const StaffTrainingMapper._();
}
