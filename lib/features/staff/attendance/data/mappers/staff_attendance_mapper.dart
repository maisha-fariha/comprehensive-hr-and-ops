import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_attendance_history_item.dart';
import '../../domain/entities/staff_attendance_overview.dart';

abstract final class StaffAttendanceMapper {
  static StaffAttendanceOverview compose({
    required dynamic todayAttendanceBody,
    required dynamic historyBody,
    required dynamic shiftsBody,
    required dynamic residenceBody,
    String? sessionResidenceId,
  }) {
    final todayRecords = JsonCodec.unwrapList(todayAttendanceBody);
    final historyRecords = JsonCodec.unwrapList(historyBody);

    final open = _findOpenRecord(todayRecords) ??
        _findOpenRecord(historyRecords);

    final shifts = JsonCodec.unwrapList(shiftsBody);
    final shift = shifts.isNotEmpty && shifts.first is Map
        ? JsonCodec.asMap(shifts.first as Map)
        : <String, dynamic>{};
    final residence = JsonCodec.unwrapMap(residenceBody);

    final checkIn = JsonCodec.dateTime(
      open?['checkInAt'] ?? open?['clockInAt'] ?? open?['checkIn'],
    );
    final onShift = open != null && checkIn != null;
    final onBreak = JsonCodec.boolean(open?['onBreak']) ??
        (JsonCodec.dateTime(open?['breakStartedAt']) != null);
    final breakStartedAt = JsonCodec.dateTime(open?['breakStartedAt']);

    final geofenceStatus = JsonCodec.string(
      open?['checkInGeofenceStatus'] ?? open?['geofenceStatus'],
    );
    final within = geofenceStatus == null
        ? true
        : geofenceStatus.toLowerCase().contains('inside') ||
            geofenceStatus.toLowerCase().contains('within') ||
            geofenceStatus.toLowerCase() == 'ok' ||
            geofenceStatus.toLowerCase() == 'inside';

    final accuracyMeters = JsonCodec.number(
      open?['checkInAccuracyMeters'] ?? open?['accuracyMeters'],
    );
    final distanceMeters = JsonCodec.number(
      open?['checkInDistanceMeters'] ?? open?['distanceMeters'],
    );

    final start = JsonCodec.dateTime(
      shift['startAt'] ?? shift['startsAt'] ?? shift['startTime'],
    );
    final end = JsonCodec.dateTime(
      shift['endAt'] ?? shift['endsAt'] ?? shift['endTime'],
    );

    final selfieUrl = JsonCodec.string(
      open?['selfieUrl'] ??
          open?['checkInSelfieUrl'] ??
          open?['checkInSelfie'],
    );

    final residenceId = JsonCodec.string(
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

    final historySource =
        historyRecords.isNotEmpty ? historyRecords : todayRecords;

    return StaffAttendanceOverview(
      isOnShift: onShift,
      shiftStartedLabel: checkIn == null
          ? 'Not clocked in'
          : 'Started at ${IsoDateRange.timeLabel(checkIn.toLocal())}',
      shiftLocationName: locationName,
      shiftTimeRange: IsoDateRange.rangeLabel(start, end).isEmpty
          ? JsonCodec.stringOr(shift['timeRange'], 'No shift assigned')
          : IsoDateRange.rangeLabel(start, end),
      elapsedTimeLabel:
          checkIn == null ? '00:00:00' : IsoDateRange.elapsedHms(checkIn),
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
        shift['id'] ?? open?['shiftId'] ?? JsonCodec.mapAt(open ?? {}, 'shift')?['id'],
      ),
      residenceId: residenceId,
      history: [
        for (final item in historySource)
          if (item is Map) _historyRow(JsonCodec.asMap(item)),
      ],
    );
  }

  static Map<String, dynamic>? _findOpenRecord(List<dynamic> records) {
    for (final item in records) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final checkOut =
          json['checkOutAt'] ?? json['clockOutAt'] ?? json['checkOut'];
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
    // Instruction: per-row duration from workedMinutes (excludes break).
    final minutes = JsonCodec.integer(json['workedMinutes']);
    final fromMinutes = IsoDateRange.workedMinutesLabel(minutes);
    return StaffAttendanceHistoryItem(
      id: JsonCodec.stringOr(json['id'], checkIn?.toIso8601String() ?? 'row'),
      dateLabel: checkIn == null
          ? JsonCodec.stringOr(json['date'], '')
          : IsoDateRange.formatShortDate(checkIn.toLocal()),
      timeRange: IsoDateRange.rangeLabel(checkIn, checkOut),
      durationLabel: fromMinutes.isNotEmpty
          ? fromMinutes
          : (checkIn == null || checkOut == null
              ? (checkOut == null && checkIn != null ? 'In progress' : '')
              : IsoDateRange.workedMinutesLabel(
                  checkOut.difference(checkIn).inMinutes,
                )),
    );
  }

  const StaffAttendanceMapper._();
}
