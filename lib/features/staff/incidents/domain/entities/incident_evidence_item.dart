import 'package:flutter/foundation.dart';

/// Evidence row on Incident Details, from `GET /incidents/{id}` attachments.
@immutable
class IncidentEvidenceItem {
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String? sizeLabel;
  final String? uploadedByName;
  final String? uploadedAtLabel;

  const IncidentEvidenceItem({
    required this.fileName,
    required this.fileUrl,
    this.fileType = 'file',
    this.sizeLabel,
    this.uploadedByName,
    this.uploadedAtLabel,
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

  /// Primary line — web shows mime type when no file name is stored.
  String get displayName {
    final name = fileName.trim();
    if (name.isNotEmpty && !name.startsWith('http') && name.contains('.')) {
      return name;
    }
    final type = fileType.trim();
    if (type.isNotEmpty && type != 'file') return type;
    if (name.isNotEmpty) return name;
    return 'Attachment';
  }

  String get metaLabel {
    final uploader = uploadedByName?.trim();
    final when = uploadedAtLabel?.trim();
    if ((uploader != null && uploader.isNotEmpty) ||
        (when != null && when.isNotEmpty)) {
      return [
        if (uploader != null && uploader.isNotEmpty) uploader,
        if (when != null && when.isNotEmpty) when,
      ].join(' · ');
    }
    if (sizeLabel != null && sizeLabel!.isNotEmpty) return sizeLabel!;
    if (fileType.toLowerCase().contains('pdf')) return 'PDF Document';
    if (fileType.toLowerCase().startsWith('image/')) return 'Image';
    return fileType;
  }
}
