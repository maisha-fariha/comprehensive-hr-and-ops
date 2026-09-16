import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';

abstract final class StaffExtrasMapper {
  static List<Map<String, String>> rowsFrom(
    dynamic body, {
    required String titleKeys,
    String subtitleKeys = 'status,description,notes,summary,type',
  }) {
    final titleCandidates = titleKeys.split(',');
    final subtitleCandidates = subtitleKeys.split(',');

    return JsonCodec.unwrapList(body).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
      var title = 'Item';
      for (final key in titleCandidates) {
        final value = JsonCodec.string(json[key.trim()]);
        if (value != null && value.isNotEmpty) {
          title = value;
          break;
        }
      }
      var subtitle = '';
      for (final key in subtitleCandidates) {
        final raw = json[key.trim()];
        final value = JsonCodec.string(raw) ??
            (raw == null ? null : raw.toString().trim());
        if (value != null && value.isNotEmpty && value != 'null') {
          subtitle = value;
          break;
        }
      }
      final at = JsonCodec.dateTime(
        json['createdAt'] ?? json['activityDate'] ?? json['updatedAt'],
      );
      if (subtitle.isEmpty && at != null) {
        subtitle = IsoDateRange.formatDisplayDate(at.toLocal());
      }
      return {
        'id': JsonCodec.stringOr(json['id'], title),
        'title': title,
        'subtitle': subtitle,
        'status': JsonCodec.stringOr(json['status'] ?? json['state'], ''),
        'clientId': JsonCodec.stringOr(json['clientId'], ''),
        'courseId': JsonCodec.stringOr(
          json['courseId'] ?? JsonCodec.mapAt(json, 'course')?['id'],
          '',
        ),
      };
    }).toList();
  }

  static Map<String, dynamic> unwrap(dynamic body) => JsonCodec.unwrapMap(body);

  const StaffExtrasMapper._();
}
