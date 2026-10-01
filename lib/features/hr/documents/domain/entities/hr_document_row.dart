import 'package:flutter/foundation.dart';

import '../../../../../core/formatting/web_formats.dart';
import 'hr_document.dart';

enum HrDocTone { success, warning, danger, neutral }

enum HrExpiryTone { normal, warning, critical }

enum HrFileKind { pdf, sheet, doc, image, file }

/// Option lists exactly as the web registry defines them.
abstract final class HrDocumentOptions {
  static const ownerTypes = [
    ('client', 'Resident'),
    ('staff', 'Staff'),
    ('residence', 'Residence'),
    ('tenant', 'Organisation'),
    ('referral', 'Referral'),
  ];

  /// The upload form cannot file against a referral.
  static final formOwnerTypes =
      ownerTypes.where((o) => o.$1 != 'referral').toList();

  static const visibilities = [
    ('all', 'Everyone'),
    ('staff_only', 'Staff only'),
    ('management_only', 'Management only'),
    ('family', 'Family'),
  ];

  static const statuses = [
    ('valid', 'In date'),
    ('expiring', 'Expiring soon'),
    ('expired', 'Expired'),
  ];

  static const typeAppliesTo = [
    ('general', 'Anything'),
    ('staff', 'Staff'),
    ('client', 'Residents'),
    ('residence', 'Residences'),
  ];

  static const fileFormats = ['PDF', 'DOCX', 'XLSX', 'CSV', 'JPG', 'PNG'];

  static const allowedExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'jpg', 'jpeg', 'png', 'webp', 'heic',
  ];

  static const maxUploadMb = 15;

  static const uploadTips = [
    'Name the document as a reader would search for it',
    'Set an expiry on anything that has to be renewed',
    'Choose the narrowest band that still lets the right people read it',
  ];

  static String label(List<(String, String)> options, String? value, String fallback) {
    for (final (v, l) in options) {
      if (v == value) return l;
    }
    return fallback;
  }

  static String visibilityLabel(String? value) =>
      value == null ? 'Everyone' : label(visibilities, value, value);

  static String appliesToLabel(String? value) =>
      label(typeAppliesTo, value ?? 'general', 'Anything');
}

/// The registry row the web derives from a document (`toDocumentRow`).
@immutable
class HrDocumentRow {
  final HrDocument document;
  final HrFileKind fileKind;
  final String ownerType;
  final String ownerTypeLabel;
  final String ownerName;
  final String category;
  final String? expiryDate;
  final HrExpiryTone expiryTone;
  final String visibility;
  final String visibilityLabel;
  final String uploadedDate;
  final String statusLabel;
  final HrDocTone statusTone;

  const HrDocumentRow._({
    required this.document,
    required this.fileKind,
    required this.ownerType,
    required this.ownerTypeLabel,
    required this.ownerName,
    required this.category,
    required this.expiryDate,
    required this.expiryTone,
    required this.visibility,
    required this.visibilityLabel,
    required this.uploadedDate,
    required this.statusLabel,
    required this.statusTone,
  });

  String get id => document.id;
  String get name => document.name;
  String? get fileUrl => document.fileUrl;
  String? get notes => document.notes;
  bool get withdrawn => document.deletedAt != null;
  bool get isStaffCertificate => document.source == 'staff_document';
  bool get restricted => visibility != 'all';

  /// Edit / Withdraw / Restore only apply to registry documents; staff
  /// certificates are edited on the staff record.
  bool canEdit(bool canWrite) => canWrite && !isStaffCertificate && !withdrawn;
  bool canWithdraw(bool canWrite) => canEdit(canWrite);
  bool canRestore(bool canWrite) => canWrite && !isStaffCertificate && withdrawn;

  static HrExpiryTone expiryToneOf(DateTime? expiresAt, DateTime now) {
    if (expiresAt == null) return HrExpiryTone.normal;
    final days = (expiresAt.difference(now).inMilliseconds / 864e5).ceil();
    if (days < 0) return HrExpiryTone.critical;
    if (days <= 30) return HrExpiryTone.warning;
    return HrExpiryTone.normal;
  }

  static HrFileKind fileKindOf(String? fileUrl) {
    final ext = (fileUrl ?? '').split('?').first.split('.').last.toLowerCase();
    if (ext == 'pdf') return HrFileKind.pdf;
    if (ext == 'xlsx' || ext == 'xls' || ext == 'csv') return HrFileKind.sheet;
    if (ext == 'docx' || ext == 'doc') return HrFileKind.doc;
    if (const ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
      return HrFileKind.image;
    }
    return HrFileKind.file;
  }

  factory HrDocumentRow.from(
    HrDocument d, {
    required Map<String, Map<String, String>> directories,
    required Map<String, String> typeNames,
    required DateTime now,
  }) {
    final tone = expiryToneOf(d.expiresAt, now);
    final ownerType = d.ownerType ?? 'tenant';
    final visibility = d.visibility ?? 'all';

    String ownerName() {
      if (ownerType == 'tenant') return 'Whole organisation';
      final id = d.ownerId;
      if (id == null) return '—';
      return directories[ownerType]?[id] ?? 'Outside your access';
    }

    final String statusLabel;
    final HrDocTone statusTone;
    if (d.deletedAt != null) {
      statusLabel = 'Withdrawn';
      statusTone = HrDocTone.neutral;
    } else if (tone == HrExpiryTone.critical) {
      statusLabel = 'Expired';
      statusTone = HrDocTone.danger;
    } else if (tone == HrExpiryTone.warning) {
      statusLabel = 'Expiring';
      statusTone = HrDocTone.warning;
    } else {
      statusLabel = d.expiresAt != null ? 'Valid' : 'No expiry';
      statusTone = HrDocTone.success;
    }

    final typeId = d.documentTypeId;
    return HrDocumentRow._(
      document: d,
      fileKind: fileKindOf(d.fileUrl),
      ownerType: ownerType,
      ownerTypeLabel: HrDocumentOptions.label(HrDocumentOptions.ownerTypes, d.ownerType, '—'),
      ownerName: ownerName(),
      category: typeId == null ? 'Unclassified' : (typeNames[typeId] ?? 'Retired type'),
      expiryDate: d.expiresAt == null ? null : WebFormat.date(d.expiresAt),
      expiryTone: tone,
      visibility: visibility,
      visibilityLabel: HrDocumentOptions.visibilityLabel(d.visibility),
      uploadedDate: WebFormat.date(d.createdAt),
      statusLabel: statusLabel,
      statusTone: statusTone,
    );
  }
}

/// One slice of the "Document Categories" donut.
@immutable
class HrCategoryShare {
  final String label;
  final String? documentTypeId;
  final int count;
  final String percent;
  final int colorIndex;

  const HrCategoryShare({
    required this.label,
    this.documentTypeId,
    required this.count,
    required this.percent,
    required this.colorIndex,
  });

  /// Whole percentages that add up to 100 (largest remainder), as the web.
  static List<HrCategoryShare> from(List<HrCategorySlice> slices) {
    final total = slices.fold<int>(0, (sum, s) => sum + s.count);
    final exact = [for (final s in slices) total == 0 ? 0.0 : s.count / total * 100];
    final whole = [for (final e in exact) e.floor()];
    var left = (total == 0 ? 0 : 100) - whole.fold<int>(0, (a, b) => a + b);
    final order = [for (var i = 0; i < exact.length; i++) i]
      ..sort((a, b) => (exact[b] - exact[b].floor()).compareTo(exact[a] - exact[a].floor()));
    for (final i in order) {
      if (left <= 0) break;
      whole[i] += 1;
      left -= 1;
    }
    return [
      for (var i = 0; i < slices.length; i++)
        HrCategoryShare(
          label: slices[i].name,
          documentTypeId: slices[i].documentTypeId,
          count: slices[i].count,
          percent: '${whole[i]}%',
          colorIndex: i,
        ),
    ];
  }
}

enum HrAlertTone { critical, warning, secondary, purple }

/// One "Compliance Alerts" line.
@immutable
class HrComplianceAlert {
  final String id;
  final int count;
  final String title;
  final String description;
  final String actionLabel;
  final HrAlertTone tone;

  /// `null` opens the missing-documents list instead of filtering.
  final ({String status, String visibility})? filter;

  const HrComplianceAlert({
    required this.id,
    required this.count,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.tone,
    this.filter,
  });

  static List<HrComplianceAlert> from(HrDocumentsSummary s) => [
        if (s.expired > 0)
          HrComplianceAlert(
            id: 'expired',
            count: s.expired,
            title: s.expired == 1 ? 'expired document' : 'expired documents',
            description: 'Past their expiry date and still on file',
            actionLabel: 'Review',
            tone: HrAlertTone.critical,
            filter: (status: 'expired', visibility: ''),
          ),
        if (s.missingMandatory > 0)
          HrComplianceAlert(
            id: 'missing',
            count: s.missingMandatory,
            title: 'missing required documents',
            description: 'Mandatory types nobody has filed for these people',
            actionLabel: 'See gaps',
            tone: HrAlertTone.warning,
          ),
        if (s.expiringSoon > 0)
          HrComplianceAlert(
            id: 'expiring',
            count: s.expiringSoon,
            title: 'expiring within 30 days',
            description: 'Renew before they lapse',
            actionLabel: 'Review',
            tone: HrAlertTone.secondary,
            filter: (status: 'expiring', visibility: ''),
          ),
        if (s.restricted > 0)
          HrComplianceAlert(
            id: 'restricted',
            count: s.restricted,
            title: 'restricted files',
            description: 'Held in a band narrower than everyone',
            actionLabel: 'View',
            tone: HrAlertTone.purple,
            filter: (status: '', visibility: 'management_only'),
          ),
      ];
}
