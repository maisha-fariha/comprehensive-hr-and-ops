import '../../../../../../core/network/iso_date_range.dart';
import '../../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_document.dart';

abstract final class StaffDocumentsMapper {
  static StaffDocumentsSummary summaryFromJson(dynamic body) {
    final map = JsonCodec.unwrapMap(body);
    final missing = JsonCodec.listAt(map, 'missingByType')
        .whereType<Map>()
        .map((raw) {
          final json = JsonCodec.asMap(raw);
          return StaffDocumentMissingGap(
            documentTypeId: JsonCodec.stringOr(json['documentTypeId'], ''),
            name: JsonCodec.stringOr(json['name'], 'Document type'),
            appliesTo: JsonCodec.stringOr(json['appliesTo'], 'staff'),
            owners: JsonCodec.integerOr(json['owners'], 0),
            filed: JsonCodec.integerOr(json['filed'], 0),
            missing: JsonCodec.integerOr(json['missing'], 0),
          );
        })
        .toList();
    final byType = JsonCodec.listAt(map, 'byType').whereType<Map>().map((raw) {
      final json = JsonCodec.asMap(raw);
      return StaffDocumentCategorySlice(
        documentTypeId: JsonCodec.string(json['documentTypeId']),
        name: JsonCodec.stringOr(json['name'], 'Uncategorised'),
        count: JsonCodec.integerOr(json['count'], 0),
      );
    }).toList();

    return StaffDocumentsSummary(
      documents: JsonCodec.integerOr(map['documents'], 0),
      addedLast30Days: JsonCodec.integerOr(map['addedLast30Days'], 0),
      missingMandatory: JsonCodec.integerOr(map['missingMandatory'], 0),
      expiringSoon: JsonCodec.integerOr(map['expiringSoon'], 0),
      expired: JsonCodec.integerOr(map['expired'], 0),
      restricted: JsonCodec.integerOr(map['restricted'], 0),
      missingByType: missing,
      byType: byType,
    );
  }

  static StaffDocument documentFromJson(
    Map<String, dynamic> json, {
    required Map<String, String> typeNames,
    required Map<String, String> ownerNames,
  }) {
    final ownerType = JsonCodec.stringOr(json['ownerType'], 'tenant');
    final ownerId = JsonCodec.string(json['ownerId']);
    final typeId = JsonCodec.string(json['documentTypeId']);
    final typeName = typeId == null
        ? 'Unclassified'
        : (typeNames[typeId] ?? 'Retired type');
    final ownerName = ownerId == null
        ? (ownerType == 'tenant' ? 'Organisation' : '—')
        : (ownerNames['$ownerType:$ownerId'] ??
            ownerNames[ownerId] ??
            '—');

    return StaffDocument(
      id: JsonCodec.stringOr(json['id'], ''),
      name: JsonCodec.stringOr(json['name'], 'Document'),
      fileUrl: JsonCodec.string(json['fileUrl']),
      ownerType: ownerType,
      ownerId: ownerId,
      ownerName: ownerName,
      documentTypeId: typeId,
      categoryLabel: typeName,
      status: JsonCodec.stringOr(json['status'], 'valid'),
      visibility: JsonCodec.stringOr(json['visibility'], 'all'),
      expiresAt: JsonCodec.dateTime(json['expiresAt']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      deletedAt: JsonCodec.dateTime(json['deletedAt']),
      notes: JsonCodec.string(json['notes']),
      source: JsonCodec.stringOr(json['source'], 'document'),
    );
  }

  static StaffDocumentType typeFromJson(Map<String, dynamic> json) {
    return StaffDocumentType(
      id: JsonCodec.stringOr(json['id'], ''),
      name: JsonCodec.stringOr(json['name'], 'Type'),
      appliesTo: JsonCodec.stringOr(json['appliesTo'], 'general'),
      isMandatory: JsonCodec.boolean(json['isMandatory']) ?? false,
      isActive: JsonCodec.boolean(json['isActive']) ?? true,
    );
  }

  static StaffDocumentOwnerOption ownerFromPerson(Map<String, dynamic> json) {
    return StaffDocumentOwnerOption(
      id: JsonCodec.stringOr(json['id'], ''),
      label: IsoDateRange.personName(json),
    );
  }

  static StaffDocumentOwnerOption ownerFromResidence(
    Map<String, dynamic> json,
  ) {
    return StaffDocumentOwnerOption(
      id: JsonCodec.stringOr(json['id'], ''),
      label: JsonCodec.stringOr(json['name'], 'Residence'),
    );
  }

  const StaffDocumentsMapper._();
}
