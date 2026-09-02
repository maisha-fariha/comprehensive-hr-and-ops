import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/family_visit_requests_overview.dart';
import '../../domain/entities/my_visit_request.dart';
import '../../domain/entities/visit_request.dart';
import '../../domain/entities/visit_request_detail.dart';

abstract final class FamilyVisitRequestsMapper {
  static bool isFamilyVisit(Map<String, dynamic> json) {
    final type = (JsonCodec.string(json['type']) ?? '').toLowerCase();
    return type.contains('visit') || type.contains('family');
  }

  static FamilyVisitRequestsOverview overviewFrom(dynamic body) {
    final mine = <MyVisitRequest>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      if (!isFamilyVisit(json)) continue;
      mine.add(myFrom(json));
    }
    final open = mine
        .where(
          (item) =>
              item.status == VisitRequestStatus.pending ||
              item.status == VisitRequestStatus.approved ||
              item.status == VisitRequestStatus.rescheduleRequested,
        )
        .toList();
    final history = mine
        .where(
          (item) =>
              item.status == VisitRequestStatus.completed ||
              item.status == VisitRequestStatus.rejected ||
              item.status == VisitRequestStatus.cancelled,
        )
        .map(
          (item) => VisitRequest(
            id: item.id,
            requesterName: 'You',
            type: item.type,
            dateTimeLabel: item.dateTimeLabel,
            status: item.status,
            locationLabel: item.locationModeLabel,
          ),
        )
        .toList();
    return FamilyVisitRequestsOverview(
      allRequests: const [],
      myRequests: open,
      historyRequests: history,
    );
  }

  static MyVisitRequest myFrom(Map<String, dynamic> json) {
    final at = JsonCodec.dateTime(json['scheduledAt']);
    return MyVisitRequest(
      id: JsonCodec.stringOr(json['id'], 'visit'),
      type: VisitRequestType.visit,
      dateTimeLabel: at == null
          ? JsonCodec.stringOr(json['dateLabel'], '')
          : IsoDateRange.dateTimeLabel(at),
      status: statusFrom(json['status']),
      locationModeLabel: JsonCodec.stringOr(json['location'], ''),
      notes: JsonCodec.string(
        json['notes'] ?? json['decisionReason'] ?? json['purpose'],
      ),
    );
  }

  static VisitRequestDetail detailFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final client = JsonCodec.mapAt(json, 'client') ?? {};
    final staff = JsonCodec.mapAt(json, 'assignedStaff') ??
        JsonCodec.mapAt(json, 'staff') ??
        {};
    final at = JsonCodec.dateTime(json['scheduledAt']);
    final reason = JsonCodec.string(json['decisionReason']);
    return VisitRequestDetail(
      id: JsonCodec.stringOr(json['id'], 'visit'),
      type: VisitRequestType.visit,
      status: statusFrom(json['status']),
      dateTimeLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at),
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
      purpose: JsonCodec.stringOr(json['type'] ?? json['purpose'], 'Family Visit'),
      notes: [
        JsonCodec.string(json['notes']),
        if (reason != null) 'Decision: $reason',
      ].whereType<String>().join('\n'),
    );
  }

  static VisitRequestStatus statusFrom(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'approved':
        return VisitRequestStatus.approved;
      case 'rejected':
      case 'declined':
        return VisitRequestStatus.rejected;
      case 'cancelled':
      case 'canceled':
        return VisitRequestStatus.cancelled;
      case 'completed':
        return VisitRequestStatus.completed;
      case 'reschedule':
      case 'reschedule_requested':
        return VisitRequestStatus.rescheduleRequested;
      default:
        return VisitRequestStatus.pending;
    }
  }

  const FamilyVisitRequestsMapper._();
}
