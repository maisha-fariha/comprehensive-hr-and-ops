import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';

abstract final class FamilyAppointmentsMapper {
  static List<FamilyAppointment> listFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => fromJson(JsonCodec.asMap(item)))
        .toList();
  }

  static FamilyAppointment fromJson(Map<String, dynamic> json) {
    final type = (JsonCodec.string(json['type']) ?? '').toLowerCase();
    final status = _status(json['status'], json['scheduledAt']);
    final at = JsonCodec.dateTime(json['scheduledAt'] ?? json['startsAt']);
    return FamilyAppointment(
      id: JsonCodec.stringOr(json['id'], json['title'] ?? 'appointment'),
      dateTimeLabel: at == null
          ? JsonCodec.stringOr(json['dateLabel'], '')
          : IsoDateRange.dateTimeLabel(at),
      status: status,
      title: JsonCodec.stringOr(
        json['title'] ?? json['purpose'] ?? json['type'],
        _titleForType(type),
      ),
      location: JsonCodec.stringOr(json['location'] ?? json['mode'], ''),
      iconKind: _icon(type, json['title']),
      type: type,
      scheduledAt: at,
    );
  }

  static String _titleForType(String type) {
    switch (type) {
      case 'visit':
      case 'family_visit':
        return 'Family Visit';
      case 'therapy':
        return 'Therapy';
      case 'activity':
        return 'Activity';
      case 'medical':
        return 'Medical Appointment';
      default:
        return 'Appointment';
    }
  }

  static FamilyAppointmentStatus _status(dynamic raw, dynamic scheduledAt) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'approved':
        return FamilyAppointmentStatus.approved;
      case 'completed':
      case 'done':
        return FamilyAppointmentStatus.completed;
      case 'rejected':
      case 'declined':
        return FamilyAppointmentStatus.rejected;
      case 'cancelled':
      case 'canceled':
        return FamilyAppointmentStatus.cancelled;
      case 'reschedule':
      case 'reschedule_requested':
        return FamilyAppointmentStatus.rescheduleRequested;
      case 'pending':
        return FamilyAppointmentStatus.pending;
      default:
        final at = JsonCodec.dateTime(scheduledAt);
        if (at != null && at.isAfter(DateTime.now())) {
          return FamilyAppointmentStatus.upcoming;
        }
        return FamilyAppointmentStatus.pending;
    }
  }

  static FamilyAppointmentIconKind _icon(String type, dynamic title) {
    final text = '$type ${title ?? ''}'.toLowerCase();
    if (text.contains('visit') || text.contains('family')) {
      return FamilyAppointmentIconKind.familyVisit;
    }
    if (text.contains('dent')) return FamilyAppointmentIconKind.dental;
    if (text.contains('physio') ||
        text.contains('therapy') ||
        text.contains('activity')) {
      return FamilyAppointmentIconKind.physiotherapy;
    }
    return FamilyAppointmentIconKind.medical;
  }

  const FamilyAppointmentsMapper._();
}
