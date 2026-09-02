import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_attendance_history_item.dart';
import '../../domain/entities/staff_attendance_overview.dart';

abstract final class StaffAttendanceMapper {
  static StaffAttendanceOverview compose({
    required dynamic attendanceBody,
    required dynamic shiftsBody,
    required dynamic residenceBody,
  }) {
    final records = JsonCodec.unwrapList(attendanceBody);
    Map<String, dynamic>? open;
    for (final item in records) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final checkOut = json['checkOutAt'] ?? json['clockOutAt'] ?? json['checkOut'];
      if (checkOut == null) {
        open = json;
        break;
      }
    }

    final shifts = JsonCodec.unwrapList(shiftsBody);
    final shift = shifts.isNotEmpty && shifts.first is Map
        ? JsonCodec.asMap(shifts.first as Map)
        : <String, dynamic>{};
    final residence = JsonCodec.unwrapMap(residenceBody);

    final checkIn = JsonCodec.dateTime(
      open?['checkInAt'] ?? open?['clockInAt'] ?? open?['checkIn'],
    );
    final onShift = open != null && checkIn != null;
    final onBreak = JsonCodec.boolean(open?['onBreak']) ?? false;
    final geofenceStatus = JsonCodec.string(
      open?['checkInGeofenceStatus'] ?? open?['geofenceStatus'],
    );
    final within = geofenceStatus == null
        ? true
        : geofenceStatus.toLowerCase().contains('inside') ||
            geofenceStatus.toLowerCase().contains('within');

    final start = JsonCodec.dateTime(
      shift['startAt'] ?? shift['startsAt'] ?? shift['startTime'],
    );
    final end = JsonCodec.dateTime(
      shift['endAt'] ?? shift['endsAt'] ?? shift['endTime'],
    );

    final accuracy = JsonCodec.number(open?['checkInAccuracyMeters']);
    final selfieUrl = JsonCodec.string(open?['selfieUrl'] ?? open?['checkInSelfieUrl']);
    final residenceId = JsonCodec.string(
      residence['id'] ??
          shift['residenceId'] ??
          JsonCodec.mapAt(shift, 'residence')?['id'],
    );

    return StaffAttendanceOverview(
      isOnShift: onShift,
      shiftStartedLabel: checkIn == null
          ? 'Not clocked in'
          : 'Started at ${IsoDateRange.timeLabel(checkIn.toLocal())}',
      shiftLocationName: JsonCodec.stringOr(
        residence['name'] ??
            shift['residenceName'] ??
            JsonCodec.mapAt(shift, 'residence')?['name'],
        'Residence',
      ),
      shiftTimeRange: IsoDateRange.rangeLabel(start, end).isEmpty
          ? JsonCodec.stringOr(shift['timeRange'], '')
          : IsoDateRange.rangeLabel(start, end),
      elapsedTimeLabel:
          checkIn == null ? '00:00:00' : IsoDateRange.elapsedHms(checkIn),
      isWithinGeofence: within,
      geofenceAddress: JsonCodec.stringOr(
        residence['address'] ??
            JsonCodec.mapAt(residence, 'geofence')?['address'] ??
            residence['formattedAddress'],
        JsonCodec.stringOr(open?['checkInGeofenceStatus'], 'Geofence'),
      ),
      isSelfieVerified: selfieUrl != null,
      selfieVerifiedLabel: selfieUrl == null
          ? 'Selfie not captured'
          : accuracy == null
              ? 'Selfie verified'
              : 'Accuracy ${accuracy.round()} m',
      isOnBreak: onBreak,
      breakStatusLabel: onBreak ? 'On break' : 'Not on break',
      shiftId: JsonCodec.string(shift['id'] ?? open?['shiftId']),
      residenceId: residenceId,
      history: [
        for (final item in records)
          if (item is Map) _historyRow(JsonCodec.asMap(item)),
      ],
    );
  }

  static StaffAttendanceHistoryItem _historyRow(Map<String, dynamic> json) {
    final checkIn = JsonCodec.dateTime(
      json['checkInAt'] ?? json['clockInAt'] ?? json['checkIn'],
    );
    final checkOut = JsonCodec.dateTime(
      json['checkOutAt'] ?? json['clockOutAt'] ?? json['checkOut'],
    );
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
              ? ''
              : IsoDateRange.workedMinutesLabel(
                  checkOut.difference(checkIn).inMinutes,
                )),
    );
  }

  const StaffAttendanceMapper._();
}
