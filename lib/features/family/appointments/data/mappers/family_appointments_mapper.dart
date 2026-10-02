import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../profile_settings/domain/entities/family_linked_client.dart';
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
    final rawStatus = JsonCodec.string(json['status']) ?? '';
    final at = JsonCodec.dateTime(json['scheduledAt'] ?? json['startsAt']);
    final decidedByRaw = json['decidedBy'];
    final decidedBy = decidedByRaw is Map
        ? IsoDateRange.personName(decidedByRaw)
        : JsonCodec.string(decidedByRaw);
    final client = JsonCodec.mapAt(json, 'client');
    final residence = JsonCodec.mapAt(json, 'residence');
    return FamilyAppointment(
      id: JsonCodec.stringOr(json['id'], json['title'] ?? 'appointment'),
      dateTimeLabel: at == null
          ? JsonCodec.stringOr(json['dateLabel'], 'Time to be confirmed')
          : IsoDateRange.dateTimeLabel(at),
      status: statusFrom(rawStatus),
      statusLabel: humanise(rawStatus),
      title: JsonCodec.string(json['title']) ??
          JsonCodec.string(json['purpose']) ??
          typeLabel(type),
      location: JsonCodec.string(json['location']) ??
          JsonCodec.string(residence?['name']) ??
          'Main Residence',
      iconKind: _icon(type, json['title']),
      type: type,
      scheduledAt: at,
      clientName: client == null ? '' : IsoDateRange.personName(client),
      notes: JsonCodec.string(json['notes']),
      decidedBy: decidedBy == 'Unknown' ? null : decidedBy,
      decidedAt: JsonCodec.dateTime(json['decidedAt']),
      decisionReason: JsonCodec.string(json['decisionReason']),
    );
  }

  /// Web `humanise`: `family_visit` -> "Family visit", `cancelled` ->
  /// "Cancelled", empty -> "—".
  static String humanise(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final text = raw.replaceAll(RegExp(r'[_-]+'), ' ');
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  /// Card title for an appointment type; mirrors the web register's
  /// `typeLabel` ("Family Visit" for `family_visit`).
  static String typeLabel(String type) {
    switch (type) {
      case '':
        return 'Appointment';
      case 'visit':
      case 'family_visit':
        return 'Family Visit';
      case 'external':
        return 'External';
      default:
        return humanise(type);
    }
  }

  static FamilyAppointmentStatus statusFrom(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'pending':
        return FamilyAppointmentStatus.pending;
      case 'approved':
      case 'confirmed':
        return FamilyAppointmentStatus.approved;
      case 'completed':
        return FamilyAppointmentStatus.completed;
      case 'rejected':
      case 'declined':
        return FamilyAppointmentStatus.rejected;
      case 'cancelled':
      case 'canceled':
        return FamilyAppointmentStatus.cancelled;
      case 'rescheduled':
      case 'reschedule_requested':
        return FamilyAppointmentStatus.rescheduleRequested;
      default:
        return FamilyAppointmentStatus.other;
    }
  }

  /// `GET /family/clients` rows (`id`, `firstName`, `lastName`, optional
  /// `residence`/`room`) as pickable residents.
  static List<FamilyLinkedClient> residentsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final name = IsoDateRange.personName(
            json['preferredName'] ?? json['name'] ?? json,
          );
          final room = JsonCodec.string(json['room'] ?? json['roomNumber']);
          final residence = JsonCodec.string(
            json['residenceName'] ?? JsonCodec.mapAt(json, 'residence')?['name'],
          );
          return FamilyLinkedClient(
            id: JsonCodec.stringOr(json['id'], ''),
            initials: IsoDateRange.initials(name),
            name: name,
            subtitle: [
              ?residence,
              if (room != null) 'Room $room',
            ].join(' · '),
            statusLabel: humanise(JsonCodec.string(json['status']) ?? 'active'),
          );
        })
        .where((client) => client.id.isNotEmpty)
        .toList();
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
