import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/family_search_hit.dart';

abstract final class FamilySearchMapper {
  static List<FamilySearchHit> listFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => fromJson(JsonCodec.asMap(item)))
        .toList();
  }

  static FamilySearchHit fromJson(Map<String, dynamic> json) {
    final type = _type(json['type'] ?? json['kind'] ?? json['entityType']);
    final at = JsonCodec.dateTime(json['occurredAt'] ?? json['createdAt']);
    return FamilySearchHit(
      id: JsonCodec.stringOr(json['id'] ?? json['entityId'], 'hit'),
      type: type,
      title: JsonCodec.stringOr(
        json['title'] ?? json['name'] ?? json['subject'],
        _label(type),
      ),
      subtitle: [
        JsonCodec.string(json['snippet'] ?? json['body'] ?? json['preview']),
        if (at != null) IsoDateRange.dateTimeLabel(at),
      ].whereType<String>().join(' · '),
    );
  }

  static FamilySearchHitType _type(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'daily_log':
      case 'dailylog':
      case 'update':
        return FamilySearchHitType.dailyLog;
      case 'appointment':
      case 'visit':
        return FamilySearchHitType.appointment;
      case 'message':
      case 'conversation':
        return FamilySearchHitType.message;
      case 'document':
        return FamilySearchHitType.document;
      default:
        return FamilySearchHitType.unknown;
    }
  }

  static String _label(FamilySearchHitType type) {
    switch (type) {
      case FamilySearchHitType.dailyLog:
        return 'Care update';
      case FamilySearchHitType.appointment:
        return 'Appointment';
      case FamilySearchHitType.message:
        return 'Message';
      case FamilySearchHitType.document:
        return 'Document';
      case FamilySearchHitType.unknown:
        return 'Result';
    }
  }

  const FamilySearchMapper._();
}
