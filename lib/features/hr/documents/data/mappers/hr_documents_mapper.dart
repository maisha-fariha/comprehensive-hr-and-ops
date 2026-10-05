import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/hr_document.dart';

class HrDocumentsMapper {
  const HrDocumentsMapper._();

  static HrDocument? documentFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return HrDocument(
      id: id,
      name: JsonCodec.stringOr(json['name'], 'Document'),
      documentTypeId: JsonCodec.string(json['documentTypeId']),
      fileUrl: JsonCodec.string(json['fileUrl']),
      ownerType: JsonCodec.string(json['ownerType']),
      ownerId: JsonCodec.string(json['ownerId']),
      expiresAt: JsonCodec.dateTime(json['expiresAt']),
      status: JsonCodec.string(json['status']),
      visibility: JsonCodec.string(json['visibility']),
      notes: JsonCodec.string(json['notes']),
      uploadedBy: JsonCodec.string(json['uploadedBy']),
      deletedAt: JsonCodec.dateTime(json['deletedAt']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      source: JsonCodec.string(json['source']) == 'staff_document'
          ? 'staff_document'
          : 'document',
    );
  }

  static HrDocumentPage pageFrom(dynamic body) {
    final items = [
      for (final row in JsonCodec.unwrapList(body).whereType<Map>())
        ?documentFrom(JsonCodec.asMap(row)),
    ];
    final meta = JsonCodec.metaOf(body);
    return HrDocumentPage(
      items: items,
      total: JsonCodec.integer(meta?['total']) ?? items.length,
      totalPages: JsonCodec.integer(meta?['totalPages']) ?? (items.isEmpty ? 0 : 1),
    );
  }

  static HrDocumentsSummary summaryFrom(dynamic body) {
    final map = JsonCodec.unwrapMap(body);
    return HrDocumentsSummary(
      documents: JsonCodec.integerOr(map['documents'], 0),
      expiringSoon: JsonCodec.integerOr(map['expiringSoon'], 0),
      expired: JsonCodec.integerOr(map['expired'], 0),
      restricted: JsonCodec.integerOr(map['restricted'], 0),
      addedLast30Days: JsonCodec.integerOr(map['addedLast30Days'], 0),
      missingMandatory: JsonCodec.integerOr(map['missingMandatory'], 0),
      missingByType: [
        for (final raw in JsonCodec.listAt(map, 'missingByType').whereType<Map>())
          HrMissingGap(
            documentTypeId: JsonCodec.stringOr(raw['documentTypeId'], ''),
            name: JsonCodec.stringOr(raw['name'], 'Document type'),
            appliesTo: JsonCodec.string(raw['appliesTo']),
            owners: JsonCodec.integerOr(raw['owners'], 0),
            filed: JsonCodec.integerOr(raw['filed'], 0),
            missing: JsonCodec.integerOr(raw['missing'], 0),
          ),
      ],
      byType: [
        for (final raw in JsonCodec.listAt(map, 'byType').whereType<Map>())
          HrCategorySlice(
            documentTypeId: JsonCodec.string(raw['documentTypeId']),
            name: JsonCodec.stringOr(raw['name'], 'Uncategorised'),
            count: JsonCodec.integerOr(raw['count'], 0),
          ),
      ],
    );
  }

  static HrDocumentType? typeFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return HrDocumentType(
      id: id,
      name: JsonCodec.stringOr(json['name'], 'Type'),
      appliesTo: JsonCodec.string(json['appliesTo']),
      isMandatory: JsonCodec.boolean(json['isMandatory']) ?? false,
      isActive: JsonCodec.boolean(json['isActive']) ?? true,
    );
  }

  static List<HrDocumentType> typesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          ?typeFrom(JsonCodec.asMap(row)),
      ];

  /// Clients and staff are named `firstName lastName`; residences by `name`.
  static List<HrDocumentOwner> ownersFrom(dynamic body, String ownerType) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            HrDocumentOwner(
              id: id,
              name: ownerType == 'residence'
                  ? JsonCodec.stringOr(row['name'], '')
                  : [row['firstName'], row['lastName']]
                      .map((p) => JsonCodec.string(p) ?? '')
                      .where((p) => p.isNotEmpty)
                      .join(' '),
            ),
      ];
}
