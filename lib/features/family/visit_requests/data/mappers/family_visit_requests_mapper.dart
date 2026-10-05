import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../appointments/data/mappers/family_appointments_mapper.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/family_visit_requests_overview.dart';
import '../../domain/entities/my_visit_request.dart';
import '../../domain/entities/visit_request_detail.dart';

abstract final class FamilyVisitRequestsMapper {
  static bool isFamilyVisit(Map<String, dynamic> json) {
    final type = (JsonCodec.string(json['type']) ?? '').toLowerCase();
    // The live API ignores `type=family_visit`; filter client-side.
    return type == 'family_visit' ||
        type == 'visit' ||
        type.contains('family_visit');
  }

  static FamilyVisitRequestsOverview overviewFrom(dynamic body) {
    final requests = <MyVisitRequest>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      if (!isFamilyVisit(json)) continue;
      requests.add(myFrom(json));
    }
    return FamilyVisitRequestsOverview(requests: requests);
  }

  static MyVisitRequest myFrom(Map<String, dynamic> json) {
    final at = JsonCodec.dateTime(json['scheduledAt']);
    final rawStatus = JsonCodec.string(json['status']);
    final status = statusFrom(rawStatus);
    final decisionReason = JsonCodec.string(json['decisionReason']);
    final notes = JsonCodec.string(json['notes'] ?? json['purpose']);
    return MyVisitRequest(
      id: JsonCodec.stringOr(json['id'], 'visit'),
      type: VisitRequestType.visit,
      dateTimeLabel: at == null
          ? JsonCodec.stringOr(json['dateLabel'], 'Time to be confirmed')
          : IsoDateRange.dateTimeLabel(at),
      status: status,
      statusLabel: FamilyAppointmentsMapper.humanise(rawStatus),
      locationModeLabel: JsonCodec.stringOr(json['location'], ''),
      notes: status == VisitRequestStatus.rejected &&
              (decisionReason != null && decisionReason.trim().isNotEmpty)
          ? decisionReason
          : notes,
    );
  }

  static VisitRequestDetail detailFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final client = JsonCodec.mapAt(json, 'client') ?? {};
    final staff = JsonCodec.mapAt(json, 'assignedStaff') ??
        JsonCodec.mapAt(json, 'staff') ??
        {};
    final at = JsonCodec.dateTime(json['scheduledAt']);
    final rawStatus = JsonCodec.string(json['status']);
    final decidedByRaw = json['decidedBy'];
    final decidedBy = decidedByRaw is Map
        ? IsoDateRange.personName(decidedByRaw)
        : JsonCodec.string(decidedByRaw);
    final type = (JsonCodec.string(json['type']) ?? '').toLowerCase();
    return VisitRequestDetail(
      id: JsonCodec.stringOr(json['id'], 'visit'),
      type: VisitRequestType.visit,
      status: statusFrom(rawStatus),
      statusLabel: FamilyAppointmentsMapper.humanise(rawStatus),
      dateTimeLabel: at == null ? 'Time to be confirmed' : IsoDateRange.dateTimeLabel(at),
      locationModeLabel: JsonCodec.stringOr(json['location'], ''),
      patientName: IsoDateRange.personName(
        client.isEmpty ? json['clientName'] : client,
      ),
      assignedStaffLabel: staff.isEmpty
          ? JsonCodec.stringOr(json['assignedStaffName'], '')
          : IsoDateRange.personName(staff),
      roomLocationLabel: JsonCodec.stringOr(
        json['location'] ?? client['room'],
        '',
      ),
      purpose: JsonCodec.string(json['purpose']) ??
          FamilyAppointmentsMapper.typeLabel(type.isEmpty ? 'family_visit' : type),
      notes: JsonCodec.stringOr(json['notes'], ''),
      decidedBy: decidedBy == 'Unknown' ? null : decidedBy,
      decidedAt: JsonCodec.dateTime(json['decidedAt']),
      decisionReason: JsonCodec.string(json['decisionReason']),
    );
  }

  static VisitRequestStatus statusFrom(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'pending':
        return VisitRequestStatus.pending;
      case 'approved':
      case 'confirmed':
        return VisitRequestStatus.approved;
      case 'rejected':
      case 'declined':
        return VisitRequestStatus.rejected;
      case 'cancelled':
      case 'canceled':
        return VisitRequestStatus.cancelled;
      case 'completed':
        return VisitRequestStatus.completed;
      case 'rescheduled':
      case 'reschedule':
      case 'reschedule_requested':
        return VisitRequestStatus.rescheduleRequested;
      default:
        return VisitRequestStatus.other;
    }
  }

  const FamilyVisitRequestsMapper._();
}
