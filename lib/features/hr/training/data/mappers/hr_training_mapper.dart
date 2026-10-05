import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/hr_training.dart';

class HrTrainingMapper {
  const HrTrainingMapper._();

  static Iterable<Map<String, dynamic>> _rows(dynamic body) =>
      JsonCodec.unwrapList(body).whereType<Map>().map(JsonCodec.asMap);

  static TrainingPage<T> _page<T>(
    dynamic body,
    T? Function(Map<String, dynamic>) map, {
    bool withSummary = false,
  }) {
    final items = [for (final row in _rows(body)) ?map(row)];
    final meta = JsonCodec.metaOf(body);
    final total = JsonCodec.integer(meta?['total']) ?? items.length;
    final summary = meta == null ? null : JsonCodec.mapAt(meta, 'summary');
    return TrainingPage<T>(
      items: items,
      total: total,
      totalPages: JsonCodec.integer(meta?['totalPages']) ?? 1,
      summary: withSummary && summary != null
          ? TrainingSummary(
              assignments: JsonCodec.integerOr(summary['assignments'], 0),
              completed: JsonCodec.integerOr(summary['completed'], 0),
              outstanding: JsonCodec.integerOr(summary['outstanding'], 0),
              overdue: JsonCodec.integerOr(summary['overdue'], 0),
              mandatoryOutstanding:
                  JsonCodec.integerOr(summary['mandatoryOutstanding'], 0),
            )
          : null,
    );
  }

  static TrainingStaffRef? _staffRef(dynamic raw) {
    if (raw is! Map) return null;
    final json = JsonCodec.asMap(raw);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final residences = JsonCodec.listAt(json, 'staffResidences').whereType<Map>();
    final firstResidence = residences.isEmpty
        ? null
        : JsonCodec.mapAt(JsonCodec.asMap(residences.first), 'residence');
    return TrainingStaffRef(
      id: id,
      firstName: JsonCodec.string(json['firstName']),
      lastName: JsonCodec.string(json['lastName']),
      categoryName: JsonCodec.string(JsonCodec.mapAt(json, 'category')?['name']),
      residenceName: JsonCodec.string(firstResidence?['name']),
    );
  }

  static TrainingCourse? courseFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final title = JsonCodec.string(json['title']);
    if (id == null || title == null) return null;
    return TrainingCourse(
      id: id,
      title: title,
      description: JsonCodec.string(json['description']),
      materialUrl: JsonCodec.string(json['materialUrl']),
      materialType: JsonCodec.string(json['materialType']),
      category: JsonCodec.string(json['category']),
      validityMonths: JsonCodec.integer(json['validityMonths']),
      passingScore: JsonCodec.integer(json['passingScore']),
      attemptsAllowed: JsonCodec.integer(json['attemptsAllowed']),
      certificateRequired: JsonCodec.boolean(json['certificateRequired']) ?? false,
      isActive: JsonCodec.boolean(json['isActive']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      assignments: [
        for (final raw in JsonCodec.listAt(json, 'assignments').whereType<Map>())
          ?assignmentFrom(JsonCodec.asMap(raw)),
      ],
    );
  }

  static TrainingAssignment? assignmentFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final courseId = JsonCodec.string(json['courseId']);
    final staffId = JsonCodec.string(json['staffId']);
    if (id == null || courseId == null || staffId == null) return null;
    return TrainingAssignment(
      id: id,
      courseId: courseId,
      staffId: staffId,
      staff: _staffRef(json['staff']),
      status: JsonCodec.stringOr(json['status'], 'assigned'),
      completedAt: JsonCodec.dateTime(json['completedAt']),
      dueAt: JsonCodec.dateTime(json['dueAt']),
      mandatory: JsonCodec.boolean(json['mandatory']) ?? false,
      createdAt: JsonCodec.dateTime(json['createdAt']),
    );
  }

  static TrainingQuestion? questionFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final prompt = JsonCodec.string(json['prompt']);
    if (id == null || prompt == null) return null;
    final rawOptions = json['options'] is List
        ? json['options'] as List
        : JsonCodec.listAt(json, 'optionsJson');
    final options = [for (final o in rawOptions) o?.toString() ?? ''];
    final rawCorrect = json['correct'] is List
        ? json['correct'] as List
        : JsonCodec.listAt(json, 'correctJson');
    final correct = <int>[
      for (final c in rawCorrect)
        if (c is num) c.toInt() else if (options.indexOf('$c') case final i when i >= 0) i,
    ];
    return TrainingQuestion(
      id: id,
      prompt: prompt,
      type: JsonCodec.stringOr(json['type'], 'single_choice'),
      options: options,
      position: JsonCodec.integer(json['position']),
      correct: correct,
    );
  }

  static List<TrainingQuestion> questionsFrom(dynamic body) {
    final data = JsonCodec.unwrap(body);
    final list = data is List
        ? data
        : data is Map
            ? JsonCodec.listAt(JsonCodec.asMap(data), 'questions')
            : const [];
    return [
      for (final raw in list.whereType<Map>()) ?questionFrom(JsonCodec.asMap(raw)),
    ];
  }

  static TrainingQuiz quizFrom(dynamic body, String courseId) {
    final json = JsonCodec.unwrapMap(body);
    return TrainingQuiz(
      courseId: JsonCodec.stringOr(json['courseId'], courseId),
      passingScore: JsonCodec.integer(json['passingScore']),
      attemptsAllowed: JsonCodec.integer(json['attemptsAllowed']),
      questions: questionsFrom(json),
    );
  }

  static TrainingAttempt? attemptFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final courseId = JsonCodec.string(json['courseId']);
    final staffId = JsonCodec.string(json['staffId']);
    if (id == null || courseId == null || staffId == null) return null;
    return TrainingAttempt(
      id: id,
      courseId: courseId,
      staffId: staffId,
      score: JsonCodec.integerOr(json['score'], 0),
      passed: JsonCodec.boolean(json['passed']) ?? false,
      attemptNo: JsonCodec.integer(json['attemptNo']),
      submittedAt: JsonCodec.dateTime(json['submittedAt']),
    );
  }

  static TrainingCertificate? certificateFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final courseId = JsonCodec.string(json['courseId']);
    final staffId = JsonCodec.string(json['staffId']);
    if (id == null || courseId == null || staffId == null) return null;
    final staff = JsonCodec.mapAt(json, 'staff');
    return TrainingCertificate(
      id: id,
      courseId: courseId,
      staffId: staffId,
      staffFirstName: JsonCodec.string(staff?['firstName']),
      staffLastName: JsonCodec.string(staff?['lastName']),
      issuedAt: JsonCodec.dateTime(json['issuedAt']),
      expiresAt: JsonCodec.dateTime(json['expiresAt']),
      reviewStatus: JsonCodec.string(json['reviewStatus']),
      expiryStatus: JsonCodec.string(json['expiryStatus']),
      certificateNumber: JsonCodec.string(json['certificateNumber']),
      provider: JsonCodec.string(json['provider']),
      fileUrl: JsonCodec.string(json['fileUrl']),
      reviewNotes: JsonCodec.string(json['reviewNotes']),
    );
  }

  static TrainingAuditEntry? auditFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return TrainingAuditEntry(
      id: id,
      action: JsonCodec.string(json['action']),
      outcome: JsonCodec.string(json['outcome']),
      actorName: JsonCodec.string(json['actorName']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
    );
  }

  static TrainingPage<TrainingCourse> coursesFrom(dynamic body) =>
      _page(body, courseFrom);

  static TrainingPage<TrainingAssignment> assignmentsFrom(dynamic body) =>
      _page(body, assignmentFrom, withSummary: true);

  static List<TrainingAssignment> assignmentListFrom(dynamic body) =>
      [for (final row in _rows(body)) ?assignmentFrom(row)];

  static TrainingPage<TrainingAttempt> attemptsFrom(dynamic body) =>
      _page(body, attemptFrom);

  static TrainingPage<TrainingCertificate> certificatesFrom(dynamic body) =>
      _page(body, certificateFrom);

  static List<TrainingAuditEntry> auditLogsFrom(dynamic body) =>
      [for (final row in _rows(body)) ?auditFrom(row)];

  static TrainingAttemptResult? attemptResultFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final attempt = JsonCodec.mapAt(json, 'attempt');
    final parsed = attempt == null ? null : attemptFrom(attempt);
    if (parsed == null) return null;
    return TrainingAttemptResult(
      attempt: parsed,
      certificateIssued: json['certificate'] is Map,
    );
  }

  static List<TrainingStaffOption> staffFrom(dynamic body) => [
        for (final row in _rows(body))
          if (JsonCodec.string(row['id']) case final id?)
            () {
              final residences =
                  JsonCodec.listAt(row, 'residences').whereType<Map>().toList();
              return TrainingStaffOption(
                id: id,
                name: [row['firstName'], row['lastName']]
                    .map((p) => JsonCodec.string(p) ?? '')
                    .where((p) => p.isNotEmpty)
                    .join(' '),
                categoryId: JsonCodec.string(row['categoryId']),
                categoryName:
                    JsonCodec.string(JsonCodec.mapAt(row, 'category')?['name']),
                residenceIds: [
                  for (final r in residences) ?JsonCodec.string(r['id']),
                ],
                firstResidenceName: residences.isEmpty
                    ? null
                    : JsonCodec.string(residences.first['name']),
              );
            }(),
      ];

  static List<TrainingOption> optionsFrom(dynamic body, {bool activeOnly = false}) => [
        for (final row in _rows(body))
          if (JsonCodec.string(row['id']) case final id?)
            if (!activeOnly || JsonCodec.boolean(row['isActive']) != false)
              TrainingOption(id: id, label: JsonCodec.stringOr(row['name'], id)),
      ];

  static String? uploadUrlFrom(dynamic body) =>
      JsonCodec.string(JsonCodec.unwrapMap(body)['fileUrl']);
}
