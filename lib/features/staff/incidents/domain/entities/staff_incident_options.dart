import 'package:flutter/foundation.dart';

/// Option from `GET /incident-categories`.
@immutable
class StaffIncidentCategoryOption {
  final String id;
  final String name;

  const StaffIncidentCategoryOption({required this.id, required this.name});
}

/// Option from `GET /incidents/cir-templates`.
@immutable
class StaffCirTemplateOption {
  final String id;
  final String name;

  const StaffCirTemplateOption({required this.id, required this.name});
}

/// Client/resident from `GET /clients?assignedToMe=true` or `?search=`.
@immutable
class StaffIncidentClientOption {
  final String id;
  final String name;
  final String? residenceId;
  final String? residenceName;
  final String? roomLabel;

  const StaffIncidentClientOption({
    required this.id,
    required this.name,
    this.residenceId,
    this.residenceName,
    this.roomLabel,
  });

  String get subtitle {
    final parts = [
      if (roomLabel != null && roomLabel!.isNotEmpty) roomLabel!,
      if (residenceName != null && residenceName!.isNotEmpty) residenceName!,
    ];
    return parts.join(' · ');
  }
}

/// Local evidence file; [fileUrl] is set after `POST /uploads?category=incidents`.
@immutable
class StaffIncidentEvidenceFile {
  final String localPath;
  final String fileName;
  final String? mimeType;
  final String? fileUrl;
  final bool isUploading;
  final String? uploadError;

  const StaffIncidentEvidenceFile({
    required this.localPath,
    required this.fileName,
    this.mimeType,
    this.fileUrl,
    this.isUploading = false,
    this.uploadError,
  });

  bool get isReady => fileUrl != null && fileUrl!.isNotEmpty;

  String get sizeLabel => isUploading
      ? 'Uploading…'
      : (uploadError != null ? 'Failed' : (isReady ? 'Ready' : 'Pending'));

  String get extensionLabel {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'FILE';
    return parts.last.toUpperCase();
  }

  StaffIncidentEvidenceFile copyWith({
    String? fileUrl,
    bool? isUploading,
    String? uploadError,
    bool clearError = false,
  }) {
    return StaffIncidentEvidenceFile(
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
      fileUrl: fileUrl ?? this.fileUrl,
      isUploading: isUploading ?? this.isUploading,
      uploadError: clearError ? null : (uploadError ?? this.uploadError),
    );
  }
}
