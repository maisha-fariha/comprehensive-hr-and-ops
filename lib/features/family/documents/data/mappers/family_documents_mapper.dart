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
          final type = (JsonCodec.string(json['mimeType'] ?? json['type'] ?? name) ??
                  '')
              .toLowerCase();
          return FamilyDocument(
            id: JsonCodec.stringOr(json['id'], name),
            title: name,
            dateLabel: at == null
                ? JsonCodec.stringOr(json['dateLabel'], '')
                : 'Updated ${IsoDateRange.formatMonthDay(at.toLocal())}',
            fileType: type.contains('jp') || type.contains('png')
                ? FamilyDocumentFileType.jpg
                : FamilyDocumentFileType.pdf,
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
