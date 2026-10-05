import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_attendance_history_item.dart';
import '../../domain/entities/staff_attendance_metrics.dart';
import '../../domain/entities/staff_attendance_overview.dart';

abstract final class StaffAttendanceMapper {
  static StaffAttendanceOverview compose({
    required dynamic todayAttendanceBody,
    required dynamic historyBody,
    required dynamic shiftsBody,
    required dynamic residenceBody,
    String? sessionResidenceId,
    dynamic summaryBody,
  }) {
    final todayRecords = JsonCodec.unwrapList(todayAttendanceBody);
    final historyRecords = JsonCodec.unwrapList(historyBody);

    final open =
        _findOpenRecord(todayRecords) ?? _findOpenRecord(historyRecords);

    final shifts = JsonCodec.unwrapList(shiftsBody);
    final now = DateTime.now();
    Map<String, dynamic> shift = const {};
    var hasRosteredShiftNow = false;
    for (final raw in shifts) {
      if (raw is! Map) continue;
      final candidate = JsonCodec.asMap(raw);
      final start = JsonCodec.dateTime(
        candidate['startAt'] ??
            candidate['startsAt'] ??
            candidate['startTime'],
      );
      final end = JsonCodec.dateTime(
        candidate['endAt'] ?? candidate['endsAt'] ?? candidate['endTime'],
      );
      if (start != null && end != null) {
        if (!now.isBefore(start) && !now.isAfter(end)) {
          shift = candidate;
          hasRosteredShiftNow = true;
          break;
        }
        if (shift.isEmpty && end.isAfter(now)) {
          shift = candidate;
        }
      } else if (shift.isEmpty) {
        shift = candidate;
      }
    }
    if (shift.isEmpty && shifts.isNotEmpty && shifts.first is Map) {
      shift = JsonCodec.asMap(shifts.first as Map);
    }

    final residence = JsonCodec.unwrapMap(residenceBody);

    final checkIn = JsonCodec.dateTime(
      open?['checkInAt'] ?? open?['clockInAt'] ?? open?['checkIn'],
    );
    // Only a live clock-in (check-in without check-out) counts as on-shift.
    final onShift = checkIn != null;
    final onBreak =
        JsonCodec.boolean(open?['onBreak']) ??
        (JsonCodec.dateTime(open?['breakStartedAt']) != null);
    final breakStartedAt = JsonCodec.dateTime(open?['breakStartedAt']);

    final checkInMeta = JsonCodec.mapAt(open ?? const {}, 'checkIn') ?? {};
    final geofenceStatus = JsonCodec.string(
      open?['checkInGeofenceStatus'] ??
          checkInMeta['geofenceStatus'] ??
          open?['geofenceStatus'],
    );
    final within = geofenceStatus == null
        ? true
        : geofenceStatus.toLowerCase().contains('inside') ||
              geofenceStatus.toLowerCase().contains('within') ||
              geofenceStatus.toLowerCase() == 'ok' ||
              geofenceStatus.toLowerCase() == 'inside';

    final accuracyMeters = JsonCodec.number(
      open?['checkInAccuracyMeters'] ??
          checkInMeta['accuracyMeters'] ??
          open?['accuracyMeters'],
    );
    final distanceMeters = JsonCodec.number(
      open?['checkInDistanceMeters'] ??
          checkInMeta['distanceMeters'] ??
          open?['distanceMeters'],
    );

    final start = JsonCodec.dateTime(
      shift['startAt'] ?? shift['startsAt'] ?? shift['startTime'],
    );
    final end = JsonCodec.dateTime(
      shift['endAt'] ?? shift['endsAt'] ?? shift['endTime'],
    );

    final selfieUrl = JsonCodec.string(
      open?['selfieUrl'] ??
          checkInMeta['selfieUrl'] ??
          open?['checkInSelfieUrl'] ??
          open?['checkInSelfie'],
    );

    final residenceId =
        JsonCodec.string(
          residence['id'] ??
              open?['residenceId'] ??
              shift['residenceId'] ??
              JsonCodec.mapAt(shift, 'residence')?['id'] ??
              JsonCodec.mapAt(open ?? const {}, 'residence')?['id'],
        ) ??
        sessionResidenceId;

    final locationName = JsonCodec.stringOr(
      residence['name'] ??
          shift['residenceName'] ??
          JsonCodec.mapAt(shift, 'residence')?['name'] ??
          JsonCodec.mapAt(open ?? const {}, 'residence')?['name'],
      'Residence',
    );

    final geofenceMap = JsonCodec.mapAt(residence, 'geofence') ?? {};
    final radiusMeters = JsonCodec.number(
      geofenceMap['radiusMeters'] ??
          geofenceMap['radius'] ??
          residence['geofenceRadiusMeters'] ??
          residence['radiusMeters'],
    );
    final address = JsonCodec.stringOr(
      residence['address'] ??
          geofenceMap['address'] ??
          residence['formattedAddress'] ??
          geofenceMap['formattedAddress'],
      locationName,
    );
    final geofenceAddress = [
      address,
      if (radiusMeters != null) '${radiusMeters.round()} m radius',
      if (distanceMeters != null)
        '${_metersToFeet(distanceMeters).round()} ft from center',
    ].join(' · ');

    final accuracyLabel = accuracyMeters == null
        ? null
        : 'Accuracy ${_metersToFeet(accuracyMeters).round()} ft';
    final geofenceStatusLabel = [
      within ? 'Within Geofence' : 'Outside Geofence',
      if (accuracyLabel != null) accuracyLabel,
    ].join(' · ');

    final historySource = historyRecords.isNotEmpty
        ? historyRecords
        : todayRecords;

    return StaffAttendanceOverview(
      isOnShift: onShift,
      shiftStartedLabel: checkIn == null
          ? 'Not clocked in'
          : 'Started at ${IsoDateRange.timeLabel(checkIn.toLocal())}',
      shiftLocationName: locationName,
      shiftTimeRange: IsoDateRange.rangeLabel(start, end).isEmpty
          ? JsonCodec.stringOr(shift['timeRange'], 'No shift assigned')
          : IsoDateRange.rangeLabel(start, end),
      elapsedTimeLabel: checkIn == null
          ? '00:00:00'
          : IsoDateRange.elapsedHms(checkIn),
      checkInAt: checkIn?.toLocal(),
      isWithinGeofence: within,
      geofenceStatusLabel: geofenceStatusLabel,
      geofenceAddress: geofenceAddress,
      isSelfieVerified: selfieUrl != null && selfieUrl.isNotEmpty,
      selfieVerifiedLabel: selfieUrl == null || selfieUrl.isEmpty
          ? 'Selfie not captured'
          : checkIn == null
          ? 'Verified'
          : 'Verified · ${IsoDateRange.timeLabel(checkIn.toLocal())}',
      selfieUrl: selfieUrl,
      isOnBreak: onBreak,
      breakStatusLabel: onBreak
          ? (breakStartedAt == null
                ? 'On break'
                : 'On break · since ${IsoDateRange.timeLabel(breakStartedAt.toLocal())}')
          : 'Not on break',
      shiftId: JsonCodec.string(
        shift['id'] ??
            open?['shiftId'] ??
            JsonCodec.mapAt(open ?? {}, 'shift')?['id'],
      ),
      residenceId: residenceId,
      hasRosteredShiftNow: hasRosteredShiftNow,
      metrics: metricsFrom(summaryBody, historySource),
      history: [
        for (final item in historySource)
          if (item is Map) _historyRow(JsonCodec.asMap(item)),
      ],
    );
  }

  static StaffAttendanceMetrics metricsFrom(
    dynamic summaryBody,
    List<dynamic> historyFallback,
  ) {
    final summary = summaryBody == null
        ? null
        : JsonCodec.unwrapMap(summaryBody);
    final byStatus = summary == null
        ? null
        : (JsonCodec.mapAt(summary, 'byStatus') ?? summary);

    if (byStatus != null) {
      final pendingFromStatus = JsonCodec.integerOr(
        byStatus['pending_approval'] ?? byStatus['pendingApproval'],
        0,
      );
      final openClaims = JsonCodec.integerOr(summary?['openClaims'], 0);
      return StaffAttendanceMetrics(
        present: JsonCodec.integerOr(
          byStatus['present'] ?? byStatus['onTime'] ?? byStatus['on_time'],
          0,
        ),
        late: JsonCodec.integerOr(byStatus['late'], 0),
        missed: JsonCodec.integerOr(byStatus['missed'], 0),
        pendingApproval: pendingFromStatus > 0 ? pendingFromStatus : openClaims,
      );
    }

    var present = 0;
    var late = 0;
    var missed = 0;
    var pending = 0;
    for (final raw in historyFallback) {
      if (raw is! Map) continue;
      final status = JsonCodec.stringOr(
        JsonCodec.asMap(raw)['status'],
        '',
      ).toLowerCase();
      switch (status) {
        case 'present':
        case 'on_time':
        case 'ontime':
        case 'completed':
          present++;
        case 'late':
          late++;
        case 'missed':
          missed++;
        case 'pending_approval':
        case 'pending':
          pending++;
      }
    }
    return StaffAttendanceMetrics(
      present: present,
      late: late,
      missed: missed,
      pendingApproval: pending,
    );
  }

  /// Live open punch: has check-in, no check-out (web `useMyOpenAttendance`).
  /// `checkIn` / `checkOut` are geofence metadata objects, not timestamps.
  static Map<String, dynamic>? _findOpenRecord(List<dynamic> records) {
    for (final item in records) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final checkIn = JsonCodec.dateTime(json['checkInAt'] ?? json['clockInAt']);
      if (checkIn == null) continue;
      final checkOut = JsonCodec.dateTime(
        json['checkOutAt'] ?? json['clockOutAt'],
      );
      if (checkOut == null) return json;
    }
    return null;
  }

  static double _metersToFeet(num meters) => meters * 3.28084;

  static StaffAttendanceHistoryItem _historyRow(Map<String, dynamic> json) {
    final checkIn = JsonCodec.dateTime(
      json['checkInAt'] ?? json['clockInAt'] ?? json['checkIn'],
    );
    final checkOut = JsonCodec.dateTime(
      json['checkOutAt'] ?? json['clockOutAt'] ?? json['checkOut'],
    );
    final shift = JsonCodec.mapAt(json, 'shift') ?? const {};
    final shiftStart = JsonCodec.dateTime(
      shift['startsAt'] ?? shift['startAt'] ?? shift['startTime'],
    );
    final occurredAt =
        (checkIn ?? shiftStart ?? JsonCodec.dateTime(json['createdAt']))
            ?.toLocal();

    final minutes = JsonCodec.integer(json['workedMinutes']);
    final fromMinutes = IsoDateRange.workedMinutesLabel(minutes);
    final status = JsonCodec.stringOr(json['status'], '').toLowerCase();
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final residenceId = JsonCodec.stringOr(
      json['residenceId'] ?? residence['id'],
      '',
    );
    final residenceName = JsonCodec.stringOr(
      json['residenceName'] ?? residence['name'],
      '',
    );
    final checkInMeta = JsonCodec.mapAt(json, 'checkIn') ?? const {};
    final selfieUrl = JsonCodec.string(
      checkInMeta['selfieUrl'] ?? json['selfieUrl'],
    );
    final hasPhoto = selfieUrl != null && selfieUrl.isNotEmpty;
    final whereBits = <String>[
      if (residenceName.isNotEmpty) residenceName,
      hasPhoto ? 'Photo on file' : 'No photo',
    ];

    final timeRange = checkIn == null && checkOut == null
        ? (status == 'missed' ? 'No clock-in' : '')
        : IsoDateRange.rangeLabel(checkIn, checkOut);

    return StaffAttendanceHistoryItem(
      id: JsonCodec.stringOr(json['id'], checkIn?.toIso8601String() ?? 'row'),
      dateLabel: occurredAt == null
          ? JsonCodec.stringOr(json['date'], '—')
          : IsoDateRange.formatShortDate(occurredAt),
      timeRange: timeRange,
      durationLabel: fromMinutes.isNotEmpty
          ? fromMinutes
          : (checkIn == null || checkOut == null
                ? (checkOut == null && checkIn != null ? 'In progress' : '—')
                : IsoDateRange.workedMinutesLabel(
                    checkOut.difference(checkIn).inMinutes,
                  )),
      occurredAt: occurredAt,
      isOpen: checkIn != null && checkOut == null && status != 'missed',
      status: status,
      statusLabel: _statusLabel(status, isManual: JsonCodec.boolean(json['isManual']) ?? false),
      residenceId: residenceId,
      residenceName: residenceName,
      whereAndPhotoLabel: whereBits.join(' · '),
      isManual: JsonCodec.boolean(json['isManual']) ?? false,
    );
  }

  static String _statusLabel(String status, {required bool isManual}) {
    switch (status) {
      case 'present':
      case 'on_time':
      case 'ontime':
      case 'completed':
        return 'Present';
      case 'late':
        return 'Late';
      case 'missed':
        return 'Missed';
      case 'pending_approval':
      case 'pending':
        return isManual ? 'Manual entry waiting action' : 'Pending approval';
      case 'rejected':
        return 'Rejected';
      default:
        if (status.isEmpty) return isManual ? 'Manual entry' : '—';
        return status.replaceAll('_', ' ');
    }
  }

  const StaffAttendanceMapper._();
}
