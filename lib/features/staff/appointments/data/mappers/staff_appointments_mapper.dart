import '../../../../../../core/network/iso_date_range.dart';
import '../../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_appointment.dart';

abstract final class StaffAppointmentsMapper {
  static StaffAppointmentsSummary summaryFromJson(dynamic body) {
    final map = JsonCodec.unwrapMap(body);
    return StaffAppointmentsSummary(
      pending: JsonCodec.integerOr(map['pending'], 0),
      approved: JsonCodec.integerOr(map['approved'], 0),
      rejected: JsonCodec.integerOr(map['rejected'], 0),
      cancelled: JsonCodec.integerOr(map['cancelled'], 0),
      completed: JsonCodec.integerOr(map['completed'], 0),
      approvedToday: JsonCodec.integerOr(map['approvedToday'], 0),
      upcomingVisits: JsonCodec.integerOr(map['upcomingVisits'], 0),
      upcomingExternal: JsonCodec.integerOr(map['upcomingExternal'], 0),
      total: JsonCodec.integerOr(map['total'], 0),
    );
  }

  static StaffAppointment appointmentFromJson(Map<String, dynamic> json) {
    final client = JsonCodec.mapAt(json, 'client');
    final residence = JsonCodec.mapAt(json, 'residence');
    final requester = JsonCodec.mapAt(json, 'requester');
    final decider = JsonCodec.mapAt(json, 'decider');

    return StaffAppointment(
      id: JsonCodec.stringOr(json['id'], ''),
      type: JsonCodec.stringOr(json['type'], 'family_visit'),
      status: JsonCodec.stringOr(json['status'], 'pending'),
      clientId: JsonCodec.stringOr(
        json['clientId'] ?? client?['id'],
        '',
      ),
      clientName: client == null
          ? 'Resident'
          : IsoDateRange.personName(client),
      residenceId: JsonCodec.string(
        json['residenceId'] ?? residence?['id'],
      ),
      residenceName: JsonCodec.stringOr(residence?['name'], ''),
      requesterName: requester == null
          ? ''
          : IsoDateRange.personName(requester),
      requesterRelationship: JsonCodec.string(
        json['requesterRelationship'] ??
            requester?['relationship'] ??
            requester?['relationshipToClient'],
      ),
      scheduledAt: JsonCodec.dateTime(json['scheduledAt']),
      location: JsonCodec.string(json['location']),
      purpose: JsonCodec.string(json['purpose']),
      notes: JsonCodec.string(json['notes']),
      deciderName: decider == null ? null : IsoDateRange.personName(decider),
      decidedAt: JsonCodec.dateTime(json['decidedAt']),
      decisionReason: JsonCodec.string(json['decisionReason']),
    );
  }

  static StaffAppointmentClientOption clientFromJson(
    Map<String, dynamic> json,
  ) {
    final residence = JsonCodec.mapAt(json, 'residence');
    return StaffAppointmentClientOption(
      id: JsonCodec.stringOr(json['id'], ''),
      label: IsoDateRange.personName(json),
      residenceId: JsonCodec.string(
        json['residenceId'] ?? residence?['id'],
      ),
      residenceName: JsonCodec.stringOr(residence?['name'], ''),
    );
  }

  const StaffAppointmentsMapper._();
}
