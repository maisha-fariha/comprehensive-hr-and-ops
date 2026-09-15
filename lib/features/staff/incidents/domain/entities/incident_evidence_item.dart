import 'package:flutter/foundation.dart';

/// Evidence row on Incident Details, from `GET /incidents/{id}` attachments.
@immutable
class IncidentEvidenceItem {
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String? sizeLabel;

  const IncidentEvidenceItem({
    required this.fileName,
    required this.fileUrl,
    this.fileType = 'file',
    this.sizeLabel,
  });

  String get extensionLabel {
    final parts = fileName.split('.');
    if (parts.length > 1 && parts.last.trim().isNotEmpty) {
      return parts.last.toUpperCase();
    }
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return 'PDF';
    if (type.contains('png')) return 'PNG';
    if (type.contains('jpeg') || type.contains('jpg')) return 'JPG';
    return 'FILE';
  }

  String get metaLabel {
    if (sizeLabel != null && sizeLabel!.isNotEmpty) return sizeLabel!;
    if (fileType.toLowerCase().contains('pdf')) return 'PDF Document';
    if (fileType.toLowerCase().startsWith('image/')) return 'Image';
    return fileType;
  }
}
