import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/family_document.dart';
import '../../domain/entities/family_document_enums.dart';
import '../../domain/entities/family_documents_overview.dart';

abstract final class FamilyDocumentsMapper {
  static FamilyDocumentsOverview fromBody(dynamic body) {
    final documents = JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final at = JsonCodec.dateTime(
            json['updatedAt'] ?? json['createdAt'] ?? json['sharedAt'],
          );
          final name = JsonCodec.stringOr(
            json['title'] ?? json['name'] ?? json['fileName'],
            'Document',
          );
          final type = (JsonCodec.string(
                    json['mimeType'] ?? json['fileType'] ?? json['type'] ?? name,
                  ) ??
                  '')
              .toLowerCase();
          final upload = JsonCodec.mapAt(json, 'upload') ?? {};
          return FamilyDocument(
            id: JsonCodec.stringOr(json['id'], name),
            title: name,
            dateLabel: at == null
                ? JsonCodec.stringOr(json['dateLabel'], '')
                : 'Updated ${IsoDateRange.formatMonthDay(at.toLocal())}',
            fileType: type.contains('jp') ||
                    type.contains('png') ||
                    type.contains('image')
                ? FamilyDocumentFileType.jpg
                : FamilyDocumentFileType.pdf,
            uploadId: JsonCodec.string(
              json['uploadId'] ?? upload['id'] ?? json['fileId'],
            ),
            downloadUrl: JsonCodec.string(
              json['downloadUrl'] ??
                  json['url'] ??
                  json['fileUrl'] ??
                  upload['url'],
            ),
            category: JsonCodec.stringOr(
              json['category'] ?? json['documentType'] ?? json['type'],
              '',
            ),
          );
        })
        .toList();
    return FamilyDocumentsOverview(
      captionText: 'Only approved documents are shared.',
      documents: documents,
    );
  }

  const FamilyDocumentsMapper._();
}
