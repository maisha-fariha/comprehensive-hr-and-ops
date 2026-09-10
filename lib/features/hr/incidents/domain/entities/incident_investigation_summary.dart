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
  final String reportedByName;
  final String description;
  final String statusLabel;
  final IncidentIconKind iconKind;
  final List<CirFormSection> formSections;

  const IncidentInvestigationSummary({
    required this.id,
    required this.title,
    required this.shortIdLabel,
    required this.clientName,
    required this.residenceName,
    required this.reportedAtLabel,
    required this.reportedByName,
    required this.description,
    required this.statusLabel,
    required this.iconKind,
    this.formSections = const [],
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
