import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../hr/attendance/data/mappers/attendance_mapper.dart';
import '../../domain/entities/staff_attendance_history_item.dart';
import '../../domain/entities/staff_attendance_metrics.dart';
import '../../domain/entities/staff_attendance_overview.dart';
import '../../../../../core/time/tenant_clock.dart';

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

    final now = DateTime.now();
    // Web clock-in: the shift is current from 15 minutes before it starts
    // until it ends. Otherwise the next shift in the window is shown.
    final window = AttendanceMapper.shiftWindowFrom(shiftsBody, now);

    final checkIn = JsonCodec.dateTime(
      open?['checkInAt'] ?? open?['clockInAt'] ?? open?['checkIn'],
    );
    // Only a live clock-in (check-in without check-out) counts as on-shift.
    final onShift = checkIn != null;
    final openShiftId = JsonCodec.string(
      open?['shiftId'] ?? JsonCodec.mapAt(open ?? {}, 'shift')?['id'],
    );

    // While punched in, bind the open punch's shift — not the next upcoming
    // window. Late / overtime clock-outs and handover need that shiftId.
    Map<String, dynamic> shift = const {};
    final preferId = onShift ? openShiftId : null;
    final targetId = (preferId != null && preferId.isNotEmpty)
        ? preferId
        : window?.shiftId;
    if (targetId != null) {
      for (final raw in JsonCodec.unwrapList(shiftsBody)) {
        if (raw is! Map) continue;
        final candidate = JsonCodec.asMap(raw);
        if (JsonCodec.string(candidate['id']) == targetId) {
          shift = candidate;
          break;
        }
      }
    }
    if (shift.isEmpty && open != null) {
      final nested = JsonCodec.mapAt(open, 'shift');
      if (nested != null) shift = Map<String, dynamic>.from(nested);
    }
    final hasRosteredShiftNow = window?.isCurrent ?? false;

    final residence = JsonCodec.unwrapMap(residenceBody);
    final onBreak =
        JsonCodec.boolean(open?['onBreak']) ??
        (JsonCodec.dateTime(open?['breakStartedAt']) != null);
    final breakStartedAt = JsonCodec.dateTime(open?['breakStartedAt']);
    final breakMinutes = JsonCodec.integerOr(open?['breakMinutes'], 0);

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
    // Top-level geofenceRadiusMeters wins (same as residences / staff extras).
    final radiusMeters = JsonCodec.number(
      residence['geofenceRadiusMeters'] ??
          geofenceMap['radiusMeters'] ??
          geofenceMap['radius'] ??
          residence['radiusMeters'],
    );
    final geofenceLat = JsonCodec.number(residence['latitude'])?.toDouble();
    final geofenceLng = JsonCodec.number(residence['longitude'])?.toDouble();
    // Top-level `geofenceEnabled` is source of truth (radius alone ≠ ON).
    final geofenceEnabled = JsonCodec.boolean(residence['geofenceEnabled']) ??
        JsonCodec.boolean(geofenceMap['enabled']) ??
        false;
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
    // Before clock-in there is no punch geofenceStatus — leave "checking"
    // until the controller applies the live device fix when GPS is enabled.
    final bool resolvedWithin;
    final String geofenceStatusLabel;
    if (onShift) {
      resolvedWithin = within;
      geofenceStatusLabel = [
        within ? 'Within Geofence' : 'Outside Geofence',
        if (accuracyLabel != null) accuracyLabel,
      ].join(' · ');
    } else if (geofenceEnabled &&
        geofenceLat != null &&
        geofenceLng != null &&
        (radiusMeters ?? 0) > 0) {
      resolvedWithin = false;
      geofenceStatusLabel = 'Checking location…';
    } else {
      resolvedWithin = true;
      geofenceStatusLabel = geofenceEnabled
          ? 'GPS tracking on'
          : 'GPS tracking off';
    }

    final historySource = historyRecords.isNotEmpty
        ? historyRecords
        : todayRecords;

    return StaffAttendanceOverview(
      isOnShift: onShift,
      shiftStartedLabel: checkIn == null
          ? 'Not clocked in'
          : 'Started at ${IsoDateRange.timeLabel(checkIn)}',
      shiftLocationName: locationName,
      shiftTimeRange: IsoDateRange.rangeLabel(start, end).isEmpty
          ? JsonCodec.stringOr(shift['timeRange'], 'No shift assigned')
          : IsoDateRange.rangeLabel(start, end),
      elapsedTimeLabel: checkIn == null
          ? '00:00:00'
          : IsoDateRange.elapsedHms(checkIn),
      checkInAt: (checkIn == null ? null : TenantClock.wallOf(checkIn)),
      isWithinGeofence: resolvedWithin,
      geofenceStatusLabel: geofenceStatusLabel,
      geofenceAddress: geofenceAddress,
      geofenceEnabled: geofenceEnabled,
      geofenceLatitude: geofenceLat,
      geofenceLongitude: geofenceLng,
      geofenceRadiusMeters: radiusMeters?.toDouble(),
      isSelfieVerified: selfieUrl != null && selfieUrl.isNotEmpty,
      selfieVerifiedLabel: selfieUrl == null || selfieUrl.isEmpty
          ? 'Selfie not captured'
          : checkIn == null
          ? 'Verified'
          : 'Verified · ${IsoDateRange.timeLabel(checkIn)}',
      selfieUrl: selfieUrl,
      isOnBreak: onBreak,
      breakStartedAt: onBreak && breakStartedAt != null
          ? TenantClock.wallOf(breakStartedAt)
          : null,
      breakMinutes: breakMinutes,
      breakStatusLabel: _breakStatusLabel(
        onBreak: onBreak,
        breakStartedAt: breakStartedAt == null
            ? null
            : TenantClock.wallOf(breakStartedAt),
        breakMinutes: breakMinutes,
      ),
      shiftId: JsonCodec.string(
            openShiftId ??
                shift['id'] ??
                open?['shiftId'] ??
                JsonCodec.mapAt(open ?? {}, 'shift')?['id'],
          ),
      residenceId: residenceId,
      shiftEndsAt: end,
      shiftStartsAt: start,
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
    final occurredRaw =
        checkIn ?? shiftStart ?? JsonCodec.dateTime(json['createdAt']);
    final occurredAt =
        occurredRaw == null ? null : TenantClock.wallOf(occurredRaw);

    final minutes = JsonCodec.integer(json['workedMinutes']);
    final breakMinutes = JsonCodec.integerOr(json['breakMinutes'], 0);
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

    final isOpen = checkIn != null && checkOut == null && status != 'missed';
    // Web In/Out: "3:22 PM – Still in" while open.
    final timeRange = checkIn == null && checkOut == null
        ? (status == 'missed' ? 'No clock-in' : '')
        : (isOpen
              ? '${IsoDateRange.timeLabel(checkIn)} – Still in'
              : IsoDateRange.rangeLabel(checkIn, checkOut));

    // Web Worked: "—" while still in (no workedMinutes yet); break is a
    // separate secondary line under Worked.
    final worked = fromMinutes.isNotEmpty
        ? fromMinutes
        : (isOpen
              ? '—'
              : (checkIn == null || checkOut == null
                    ? '—'
                    : IsoDateRange.workedMinutesLabel(
                        checkOut.difference(checkIn).inMinutes,
                      )));

    return StaffAttendanceHistoryItem(
      id: JsonCodec.stringOr(json['id'], checkIn?.toIso8601String() ?? 'row'),
      dateLabel: occurredAt == null
          ? JsonCodec.stringOr(json['date'], '—')
          : IsoDateRange.formatShortDate(occurredAt),
      timeRange: timeRange,
      durationLabel: worked,
      breakLabel: breakMinutes > 0 ? '${breakMinutes}m break' : '',
      occurredAt: occurredAt,
      isOpen: isOpen,
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

  /// Live elapsed while on break; completed total matches web Worked "Xm break".
  static String _breakStatusLabel({
    required bool onBreak,
    required DateTime? breakStartedAt,
    required int breakMinutes,
  }) {
    if (onBreak) {
      final elapsed = breakStartedAt == null
          ? 'On break'
          : 'On break · ${IsoDateRange.elapsedHms(breakStartedAt)}';
      if (breakMinutes > 0) return '$elapsed · ${breakMinutes}m earlier';
      return elapsed;
    }
    if (breakMinutes > 0) return '${breakMinutes}m break today';
    return 'Not on break';
  }

  const StaffAttendanceMapper._();
}
