import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/manual_entry_options.dart';

abstract final class AttendanceMapper {
  static AttendanceRecordPage recordPageFrom(
    dynamic body, {
    required int page,
    required int limit,
  }) {
    final records = <AttendanceRecord>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final record = recordFrom(JsonCodec.asMap(item));
      if (record != null) records.add(record);
    }
    final meta = JsonCodec.metaOf(body) ?? const {};
    final total = JsonCodec.integerOr(meta['total'], records.length);
    final resolvedLimit = JsonCodec.integerOr(meta['limit'], limit);
    return AttendanceRecordPage(
      records: records,
      page: JsonCodec.integerOr(meta['page'], page),
      limit: resolvedLimit,
      total: total,
      totalPages: JsonCodec.integerOr(
        meta['totalPages'],
        resolvedLimit <= 0 ? 0 : (total / resolvedLimit).ceil(),
      ),
    );
  }

  static AttendanceRecord? recordFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final staff = JsonCodec.mapAt(json, 'staff') ?? const {};
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final shift = JsonCodec.mapAt(json, 'shift') ?? const {};
    final checkIn = JsonCodec.mapAt(json, 'checkIn') ?? const {};
    final staffName = JsonCodec.stringOr(staff['name'], 'Unknown staff');

    return AttendanceRecord(
      id: id,
      staffId: JsonCodec.stringOr(json['staffId'] ?? staff['id'], ''),
      staffName: staffName,
      staffInitials: JsonCodec.string(staff['initials']) ??
          IsoDateRange.initials(staffName),
      staffRole: JsonCodec.string(staff['role']),
      residenceId: JsonCodec.stringOr(json['residenceId'] ?? residence['id'], ''),
      residenceName: JsonCodec.stringOr(residence['name'], ''),
      shiftId: JsonCodec.string(json['shiftId']),
      shiftStartsAt: JsonCodec.dateTime(shift['startsAt']),
      shiftEndsAt: JsonCodec.dateTime(shift['endsAt']),
      checkInAt: JsonCodec.dateTime(json['checkInAt']),
      checkOutAt: JsonCodec.dateTime(json['checkOutAt']),
      breakMinutes: JsonCodec.integerOr(json['breakMinutes'], 0),
      workedMinutes: JsonCodec.integer(json['workedMinutes']),
      status: JsonCodec.stringOr(json['status'], 'present'),
      isManual: JsonCodec.boolean(json['isManual']) ?? false,
      checkIn: AttendanceCheckpoint(
        geofenceStatus:
            JsonCodec.stringOr(checkIn['geofenceStatus'], 'not_provided'),
        distanceMeters: JsonCodec.integer(checkIn['distanceMeters']),
        accuracyMeters: JsonCodec.integer(checkIn['accuracyMeters']),
        selfieUrl: JsonCodec.string(checkIn['selfieUrl']),
      ),
      reasonCategory: JsonCodec.string(json['reasonCategory']),
      originalCheckInAt: JsonCodec.dateTime(json['originalCheckInAt']),
      originalCheckOutAt: JsonCodec.dateTime(json['originalCheckOutAt']),
      evidence: [
        for (final item in JsonCodec.listAt(json, 'evidence'))
          if (item is Map && JsonCodec.string(item['fileUrl']) != null)
            AttendanceEvidence(
              fileUrl: JsonCodec.string(item['fileUrl'])!,
              fileType: JsonCodec.string(item['fileType']),
            ),
      ],
      adminNote: JsonCodec.string(json['adminNote']),
      lateMinutes: JsonCodec.integer(json['lateMinutes']),
      earlyDepartureMinutes: JsonCodec.integer(json['earlyDepartureMinutes']),
      earlyDepartureReason: JsonCodec.string(json['earlyDepartureReason']),
      notes: JsonCodec.string(json['notes']),
    );
  }

  static AttendanceSummary summaryFrom(dynamic body) {
    final data = JsonCodec.unwrapMap(body);
    final byStatus = JsonCodec.mapAt(data, 'byStatus') ?? const {};
    final lateness = JsonCodec.mapAt(data, 'lateness') ?? const {};
    return AttendanceSummary(
      present: JsonCodec.integerOr(byStatus['present'], 0),
      late: JsonCodec.integerOr(byStatus['late'], 0),
      missed: JsonCodec.integerOr(byStatus['missed'], 0),
      pendingApproval: JsonCodec.integerOr(data['openClaims'], 0),
      averageLateMinutes: JsonCodec.integer(lateness['averageMinutes']),
      lateStaffCount: JsonCodec.integerOr(lateness['staff'], 0),
    );
  }

  static OpenAttendance? openAttendanceFrom(dynamic body) {
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      if (JsonCodec.string(json['checkInAt']) == null) continue;
      if (JsonCodec.string(json['checkOutAt']) != null) continue;
      final id = JsonCodec.string(json['id']);
      final residenceId = JsonCodec.string(json['residenceId']);
      if (id == null || residenceId == null) continue;
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      return OpenAttendance(
        id: id,
        residenceId: residenceId,
        residenceName: JsonCodec.string(residence['name']),
      );
    }
    return null;
  }

  /// The current shift (clock-in opens 15 minutes early), else the next one.
  static AttendanceShiftWindow? shiftWindowFrom(dynamic body, DateTime now) {
    final windows = <AttendanceShiftWindow>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      if (JsonCodec.string(json['status']) == 'cancelled') continue;
      final id = JsonCodec.string(json['id']);
      final startsAt = JsonCodec.dateTime(json['startsAt']);
      final endsAt = JsonCodec.dateTime(json['endsAt']);
      if (id == null || startsAt == null || endsAt == null) continue;
      final opensAt = startsAt.subtract(const Duration(minutes: 15));
      windows.add(
        AttendanceShiftWindow(
          shiftId: id,
          residenceId: JsonCodec.string(json['residenceId']),
          residenceName: JsonCodec.string(json['residenceName']),
          startsAt: startsAt,
          endsAt: endsAt,
          isCurrent: !opensAt.isAfter(now) && !endsAt.isBefore(now),
        ),
      );
    }
    for (final window in windows) {
      if (window.isCurrent) return window;
    }
    final upcoming = windows.where((w) => w.startsAt.isAfter(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Rostered Shift options, labelled `dd/MM/yyyy HH:mm – dd/MM/yyyy HH:mm`.
  static List<ManualEntryShiftOption> rosteredShiftsFrom(dynamic body) {
    final options = <ManualEntryShiftOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final id = JsonCodec.string(json['id']);
      final startsAt = JsonCodec.dateTime(json['startsAt']);
      final endsAt = JsonCodec.dateTime(json['endsAt']);
      if (id == null || startsAt == null || endsAt == null) continue;
      options.add(
        ManualEntryShiftOption(
          id: id,
          label: '${formatDateTime(startsAt)} – ${formatDateTime(endsAt)}',
          startsAt: startsAt,
          endsAt: endsAt,
        ),
      );
    }
    return options;
  }

  /// `dd/MM/yyyy HH:mm` in device local time.
  static String formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static List<ManualEntryResidenceOption> residencesFrom(dynamic body) {
    final options = <ManualEntryResidenceOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final name = JsonCodec.string(
            json['name'] ??
                json['label'] ??
                json['title'] ??
                json['residenceName'] ??
                json['displayName'],
          ) ??
          '';
      if (name.isEmpty) continue;
      options.add(
        ManualEntryResidenceOption(
          id: JsonCodec.stringOr(
            json['id'] ?? json['residenceId'] ?? name,
            name,
          ),
      name: name,
        ),
      );
    }
    return options;
  }

  static List<ManualEntryStaffOption> staffFrom(dynamic body) {
    final options = <ManualEntryStaffOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final user = JsonCodec.mapAt(json, 'user') ??
          JsonCodec.mapAt(json, 'profile') ??
          json;
      final category = JsonCodec.mapAt(json, 'category') ??
          JsonCodec.mapAt(json, 'staffCategory') ??
          JsonCodec.mapAt(user, 'category') ??
          const {};
      final name = JsonCodec.string(
            user['preferredName'] ??
                user['fullName'] ??
                user['displayName'] ??
                user['name'] ??
                [
                  user['firstName'] ?? json['firstName'],
                  user['lastName'] ?? json['lastName'],
                ]
                    .where((p) => p != null && p.toString().trim().isNotEmpty)
                    .join(' '),
          ) ??
          '';
      if (name.isEmpty) continue;

      final role = JsonCodec.string(
        category['name'] ??
            json['categoryName'] ??
            json['role'] ??
            json['jobTitle'] ??
            user['role'],
      );
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final location = JsonCodec.string(
        json['residenceName'] ?? residence['name'] ?? json['location'],
      );
      final detail = [
        if (role != null && role.isNotEmpty) role,
        if (location != null && location.isNotEmpty) location,
      ].join(' · ');

      options.add(
        ManualEntryStaffOption(
          id: JsonCodec.stringOr(
            json['id'] ?? json['staffId'] ?? user['id'] ?? name,
            name,
          ),
          name: name,
          detail: detail.isEmpty ? 'Staff' : detail,
          initials: IsoDateRange.initials(name),
        ),
      );
    }
    return options;
  }

  /// Shifts from `GET /shifts`, optionally filtered to those assigned to [staffId].
  static List<ManualEntryShiftOption> shiftsForStaff(
    dynamic body, {
    String? staffId,
  }) {
    final options = <ManualEntryShiftOption>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final id = JsonCodec.string(json['id'] ?? json['shiftId']);
      if (id == null || id.isEmpty) continue;

      if (staffId != null && staffId.isNotEmpty) {
        final assigned = json['staff'];
        var matched = false;
        if (assigned is List) {
          for (final person in assigned) {
            if (person is! Map) continue;
            final personMap = JsonCodec.asMap(person);
            final personId = JsonCodec.string(
              personMap['id'] ?? personMap['staffId'],
            );
            if (personId == staffId) {
              matched = true;
              break;
            }
          }
        }
        if (!matched) continue;
      }

      final startsAt = JsonCodec.dateTime(
            json['startsAt'] ?? json['startAt'] ?? json['start'],
          ) ??
          DateTime.now();
      final endsAt = JsonCodec.dateTime(
            json['endsAt'] ?? json['endAt'] ?? json['end'],
          ) ??
          startsAt.add(const Duration(hours: 8));
      final title = JsonCodec.string(
            json['title'] ?? json['name'] ?? json['shiftType'],
          ) ??
          'Shift';
      final startLabel = _formatShiftClock(startsAt);
      final endLabel = _formatShiftClock(endsAt);
      options.add(
        ManualEntryShiftOption(
          id: id,
          label: '$title · $startLabel – $endLabel',
          startsAt: startsAt,
          endsAt: endsAt,
        ),
      );
    }
    options.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return options;
  }

  static String _formatShiftClock(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
