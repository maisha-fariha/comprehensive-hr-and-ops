import 'package:flutter/foundation.dart';

/// Residence option for Manual Attendance Entry (`GET /residences`).
@immutable
class ManualEntryResidenceOption {
  final String id;
  final String name;

  const ManualEntryResidenceOption({
    required this.id,
    required this.name,
  });
}

/// Staff option for Manual Attendance Entry (`GET /staff`).
@immutable
class ManualEntryStaffOption {
  final String id;
  final String name;
  final String detail;
  final String initials;

  const ManualEntryStaffOption({
    required this.id,
    required this.name,
    required this.detail,
    required this.initials,
  });
}

/// Rostered shift option (`GET /shifts`, filtered by staff).
@immutable
class ManualEntryShiftOption {
  final String id;
  final String label;
  final DateTime startsAt;
  final DateTime endsAt;

  const ManualEntryShiftOption({
    required this.id,
    required this.label,
    required this.startsAt,
    required this.endsAt,
  });
}

/// Local evidence file; [fileUrl] is set after `POST /uploads`.
@immutable
class ManualEntryEvidenceFile {
  final String localPath;
  final String fileName;
  final String? mimeType;
  final String? fileUrl;
  final bool isUploading;
  final String? uploadError;

  const ManualEntryEvidenceFile({
    required this.localPath,
    required this.fileName,
    this.mimeType,
    this.fileUrl,
    this.isUploading = false,
    this.uploadError,
  });

  bool get isReady => fileUrl != null && fileUrl!.isNotEmpty;

  String get fileType {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return switch (ext) {
      'pdf' => 'pdf',
      'doc' || 'docx' => 'document',
      'png' || 'jpg' || 'jpeg' || 'webp' || 'heic' => 'image',
      _ => ext.isEmpty ? 'file' : ext,
    };
  }

  ManualEntryEvidenceFile copyWith({
    String? fileUrl,
    bool? isUploading,
    String? uploadError,
    bool clearError = false,
  }) {
    return ManualEntryEvidenceFile(
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
      fileUrl: fileUrl ?? this.fileUrl,
      isUploading: isUploading ?? this.isUploading,
      uploadError: clearError ? null : (uploadError ?? this.uploadError),
    );
  }
}
