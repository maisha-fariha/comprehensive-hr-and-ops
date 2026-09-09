import 'package:flutter/foundation.dart';

/// A file selected for incident evidence. After `POST /uploads`, [fileUrl]
/// holds the public URL used by `POST /incidents/:id/evidence`.
@immutable
class IncidentEvidenceFile {
  final String localPath;
  final String fileName;
  final String? mimeType;
  final String? fileUrl;
  final bool isUploading;
  final String? uploadError;

  const IncidentEvidenceFile({
    required this.localPath,
    required this.fileName,
    this.mimeType,
    this.fileUrl,
    this.isUploading = false,
    this.uploadError,
  });

  bool get isReady => fileUrl != null && fileUrl!.isNotEmpty;

  IncidentEvidenceFile copyWith({
    String? fileUrl,
    bool? isUploading,
    String? uploadError,
    bool clearError = false,
  }) {
    return IncidentEvidenceFile(
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
      fileUrl: fileUrl ?? this.fileUrl,
      isUploading: isUploading ?? this.isUploading,
      uploadError: clearError ? null : (uploadError ?? this.uploadError),
    );
  }
}
