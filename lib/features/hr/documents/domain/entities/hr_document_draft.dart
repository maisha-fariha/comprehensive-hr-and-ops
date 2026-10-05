import 'package:flutter/foundation.dart';

import 'hr_document.dart';
import 'hr_document_row.dart';

/// The upload / edit form values (web `DocumentFormValues`).
@immutable
class HrDocumentDraft {
  final bool editing;
  final String name;
  final String ownerType;
  final String ownerId;
  final String documentTypeId;
  final HrPickedFile? file;
  final String visibility;
  final bool expiryTrackingEnabled;

  /// `YYYY-MM-DD`, empty when unset.
  final String expiryDate;
  final String notes;

  const HrDocumentDraft({
    this.editing = false,
    this.name = '',
    this.ownerType = 'client',
    this.ownerId = '',
    this.documentTypeId = '',
    this.file,
    this.visibility = 'staff_only',
    this.expiryTrackingEnabled = false,
    this.expiryDate = '',
    this.notes = '',
  });

  /// Edit defaults from a registry row; a referral is edited as the
  /// organisation, like the web.
  factory HrDocumentDraft.edit(HrDocumentRow row) {
    final d = row.document;
    final expires = d.expiresAt?.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return HrDocumentDraft(
      editing: true,
      name: d.name,
      ownerType: d.ownerType == 'referral' ? 'tenant' : row.ownerType,
      ownerId: d.ownerId ?? '',
      documentTypeId: d.documentTypeId ?? '',
      visibility: row.visibility,
      expiryTrackingEnabled: d.expiresAt != null,
      expiryDate: expires == null
          ? ''
          : '${expires.year}-${two(expires.month)}-${two(expires.day)}',
      notes: d.notes ?? '',
    );
  }

  bool get isTenant => ownerType == 'tenant';

  /// Field key → message, matching the web schema refinements.
  Map<String, String> validate() => {
        if (name.trim().isEmpty) 'name': 'Give the document a name',
        if (!isTenant && ownerId.isEmpty) 'ownerId': 'Choose who this document belongs to',
        if (!editing && file == null) 'files': 'Attach the file being filed',
        if (expiryTrackingEnabled && expiryDate.isEmpty)
          'expiryDate': 'Set the date it expires, or turn expiry tracking off',
      };

  Map<String, dynamic> createBody(String fileUrl) => {
        'name': name.trim(),
        'ownerType': ownerType,
        if (!isTenant) 'ownerId': ownerId,
        if (documentTypeId.isNotEmpty) 'documentTypeId': documentTypeId,
        if (expiryTrackingEnabled && expiryDate.isNotEmpty) 'expiresAt': expiryDate,
        'visibility': visibility,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
        'fileUrl': fileUrl,
      };

  Map<String, dynamic> updateBody() => {
        'name': name.trim(),
        'documentTypeId': documentTypeId.isEmpty ? null : documentTypeId,
        'expiresAt': expiryTrackingEnabled && expiryDate.isNotEmpty ? expiryDate : null,
        'visibility': visibility,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
      };

  HrDocumentDraft copyWith({
    String? name,
    String? ownerType,
    String? ownerId,
    String? documentTypeId,
    HrPickedFile? file,
    bool clearFile = false,
    String? visibility,
    bool? expiryTrackingEnabled,
    String? expiryDate,
    String? notes,
  }) =>
      HrDocumentDraft(
        editing: editing,
        name: name ?? this.name,
        ownerType: ownerType ?? this.ownerType,
        ownerId: ownerId ?? this.ownerId,
        documentTypeId: documentTypeId ?? this.documentTypeId,
        file: clearFile ? null : (file ?? this.file),
        visibility: visibility ?? this.visibility,
        expiryTrackingEnabled: expiryTrackingEnabled ?? this.expiryTrackingEnabled,
        expiryDate: expiryDate ?? this.expiryDate,
        notes: notes ?? this.notes,
      );
}
