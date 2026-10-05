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
  final String? version;
  final List<StaffCirTemplateSection> sections;

  const StaffCirTemplateOption({
    required this.id,
    required this.name,
    this.version,
    this.sections = const [],
  });
}

/// One titled section inside a CIR template.
@immutable
class StaffCirTemplateSection {
  final String key;
  final String title;
  final List<StaffCirTemplateField> fields;

  const StaffCirTemplateSection({
    required this.key,
    required this.title,
    this.fields = const [],
  });
}

/// One answerable field inside a CIR template section.
@immutable
class StaffCirTemplateField {
  final String key;
  final String label;
  final String type;
  final bool required;
  final String helpText;

  const StaffCirTemplateField({
    required this.key,
    required this.label,
    this.type = 'text',
    this.required = false,
    this.helpText = '',
  });
}

/// Option from `GET /residences` for Create Incident (BUG_Report011).
@immutable
class StaffIncidentResidenceOption {
  final String id;
  final String name;

  const StaffIncidentResidenceOption({required this.id, required this.name});
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
    final residence = residenceName?.trim();
    if (residence != null && residence.isNotEmpty) {
      return 'Client · $residence';
    }
    final room = roomLabel?.trim();
    if (room != null && room.isNotEmpty) return 'Client · $room';
    return 'Client';
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }
}

/// Staff directory row for Reported By / Supervisor / Investigator pickers.
@immutable
class StaffIncidentStaffOption {
  final String id;
  final String name;
  final String subtitle;

  const StaffIncidentStaffOption({
    required this.id,
    required this.name,
    this.subtitle = '',
  });
}

/// One row in Evidence & Submission → Parties Notified.
@immutable
class StaffIncidentPartyNotification {
  final String party;
  final bool notified;
  final String contactName;
  final String dateNotified;

  const StaffIncidentPartyNotification({
    required this.party,
    this.notified = false,
    this.contactName = '',
    this.dateNotified = '',
  });

  StaffIncidentPartyNotification copyWith({
    bool? notified,
    String? contactName,
    String? dateNotified,
  }) {
    return StaffIncidentPartyNotification(
      party: party,
      notified: notified ?? this.notified,
      contactName: contactName ?? this.contactName,
      dateNotified: dateNotified ?? this.dateNotified,
    );
  }

  Map<String, dynamic> toJson() => {
        'party': party,
        'notified': notified,
        if (contactName.trim().isNotEmpty) 'contactName': contactName.trim(),
        if (dateNotified.trim().isNotEmpty) 'dateNotified': dateNotified.trim(),
      };
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
