import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_search_record.dart';

abstract final class StaffSearchMapper {
  static StaffTenantModules modulesFrom(dynamic body) {
    final me = JsonCodec.unwrapMap(body);
    final tenant = JsonCodec.mapAt(me, 'tenant') ?? const <String, dynamic>{};
    final raw = JsonCodec.mapAt(tenant, 'modules') ?? const <String, dynamic>{};
    return StaffTenantModules({
      for (final entry in raw.entries)
        entry.key: JsonCodec.boolean(entry.value) ?? false,
    });
  }

  static List<StaffSearchRecord> recordsFrom(dynamic body) {
    final data = JsonCodec.unwrapMap(body);
    return [
      for (final item in JsonCodec.listAt(data, 'clients').whereType<Map>())
        _client(JsonCodec.asMap(item)),
      for (final item in JsonCodec.listAt(data, 'documents').whereType<Map>())
        _document(JsonCodec.asMap(item)),
      for (final item in JsonCodec.listAt(data, 'medications').whereType<Map>())
        _medication(JsonCodec.asMap(item)),
    ];
  }

  static StaffSearchRecord _client(Map<String, dynamic> json) {
    final fullName = [
      JsonCodec.string(json['firstName']),
      JsonCodec.string(json['lastName']),
    ].whereType<String>().join(' ');
    return StaffSearchRecord(
      id: JsonCodec.stringOr(json['id'], ''),
      type: StaffSearchRecordType.client,
      title: JsonCodec.stringOr(
        json['name'],
        fullName.isEmpty ? 'Client' : fullName,
      ),
      subtitle: _nameOf(json['residence']) ?? '',
    );
  }

  static StaffSearchRecord _document(Map<String, dynamic> json) {
    return StaffSearchRecord(
      id: JsonCodec.stringOr(json['id'], ''),
      type: StaffSearchRecordType.document,
      title: JsonCodec.stringOr(
        json['title'] ?? json['name'] ?? json['fileName'],
        'Document',
      ),
      subtitle: [
        JsonCodec.string(json['category'] ?? json['type']),
        _nameOf(json['client']),
      ].whereType<String>().join(' · '),
    );
  }

  static StaffSearchRecord _medication(Map<String, dynamic> json) {
    return StaffSearchRecord(
      id: JsonCodec.stringOr(json['id'], ''),
      type: StaffSearchRecordType.medication,
      title: JsonCodec.stringOr(json['name'], 'Medication'),
      subtitle: [
        JsonCodec.string(json['dose']),
        _nameOf(json['client']),
      ].whereType<String>().join(' · '),
    );
  }

  /// `/search` returns related names as plain strings; tolerate `{name}` too.
  static String? _nameOf(dynamic value) {
    if (value is Map) return JsonCodec.string(JsonCodec.asMap(value)['name']);
    return JsonCodec.string(value);
  }

  const StaffSearchMapper._();
}
