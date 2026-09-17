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
          final fileUrl = JsonCodec.string(
            json['fileUrl'] ??
                json['downloadUrl'] ??
                json['url'] ??
                upload['url'] ??
                upload['fileUrl'],
          );
          final fileName = JsonCodec.string(
                json['fileName'] ?? upload['fileName'],
              ) ??
              _fileNameFromPath(fileUrl);
          final category = JsonCodec.stringOr(
            json['category'] ??
                json['documentType'] ??
                json['type'] ??
                _categoryFromPath(fileUrl),
            '',
          );
          return FamilyDocument(
            id: JsonCodec.stringOr(json['id'], name),
            title: name,
            dateLabel: at == null
                ? JsonCodec.stringOr(json['dateLabel'], '')
                : 'Updated ${IsoDateRange.formatMonthDay(at.toLocal())}',
            fileType: type.contains('jp') ||
                    type.contains('png') ||
                    type.contains('image') ||
                    (fileName?.toLowerCase().endsWith('.jpg') ?? false) ||
                    (fileName?.toLowerCase().endsWith('.jpeg') ?? false) ||
                    (fileName?.toLowerCase().endsWith('.png') ?? false)
                ? FamilyDocumentFileType.jpg
                : FamilyDocumentFileType.pdf,
            uploadId: JsonCodec.string(
              json['uploadId'] ?? upload['id'] ?? json['fileId'],
            ),
            downloadUrl: JsonCodec.string(
              json['downloadUrl'] ?? json['url'] ?? upload['url'],
            ),
            fileUrl: fileUrl,
            fileName: fileName,
            tenantId: JsonCodec.string(json['tenantId'] ?? upload['tenantId']),
            category: category,
          );
        })
        .toList();
    return FamilyDocumentsOverview(
      captionText: 'Only approved documents are shared.',
      documents: documents,
    );
  }

  static String? _fileNameFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final uriPath = Uri.tryParse(path)?.path ?? path;
    final parts = uriPath.split('/').where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.last;
  }

  static String? _categoryFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final uriPath = Uri.tryParse(path)?.path ?? path;
    final parts = uriPath.split('/').where((part) => part.isNotEmpty).toList();
    // /files/{category}/{fileName} or /files/{tenantId}/{category}/{fileName}
    if (parts.length >= 3 && parts.first == 'files') {
      return parts.length >= 4 ? parts[2] : parts[1];
    }
    return null;
  }

  const FamilyDocumentsMapper._();
}
