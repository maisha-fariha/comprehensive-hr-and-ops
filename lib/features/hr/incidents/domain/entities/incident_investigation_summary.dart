import 'package:flutter/foundation.dart';

import 'incidents_enums.dart';

/// Full investigation summary shown from Under Review → View Investigation.
@immutable
class IncidentInvestigationSummary {
  final String id;
  final String title;
  final String shortIdLabel;
  final String clientName;
  final String residenceName;
  final String reportedAtLabel;

  /// UTC stamp for CIR PDF header, e.g. `2026-08-27 06:33 UTC`.
  final String reportedAtUtcLabel;
  final String reportedByName;
  final String description;
  final String statusLabel;

  /// Raw API status for CIR PDF (e.g. `investigating`).
  final String statusRaw;
  final String severityLabel;
  final IncidentIconKind iconKind;
  final List<CirFormSection> formSections;

  /// Filed CIR answers from `payloadJson` / `payload`.
  final Map<String, dynamic> cirPayload;

  /// Template snapshot used to resolve option labels / section layout.
  final Map<String, dynamic>? templateSnapshot;

  const IncidentInvestigationSummary({
    required this.id,
    required this.title,
    required this.shortIdLabel,
    required this.clientName,
    required this.residenceName,
    required this.reportedAtLabel,
    this.reportedAtUtcLabel = '-',
    required this.reportedByName,
    required this.description,
    required this.statusLabel,
    this.statusRaw = '',
    this.severityLabel = '-',
    required this.iconKind,
    this.formSections = const [],
    this.cirPayload = const {},
    this.templateSnapshot,
  });

  String get headerMeta =>
      [shortIdLabel, clientName, residenceName]
          .where((part) => part.trim().isNotEmpty)
          .join(' · ');
}

@immutable
class CirFormSection {
  final String title;
  final List<CirFormField> fields;

  const CirFormSection({
    required this.title,
    this.fields = const [],
  });
}

@immutable
class CirFormField {
  final String label;
  final String value;

  const CirFormField({
    required this.label,
    required this.value,
  });
}
