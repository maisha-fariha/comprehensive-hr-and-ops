import 'package:flutter/foundation.dart';

/// A selectable CIR template from `GET /incidents/cir-templates`.
@immutable
class IncidentCirTemplateOption {
  final String id;
  final String name;
  final String? provinceOrState;
  final int? version;
  final List<IncidentCirTemplateSection> sections;

  const IncidentCirTemplateOption({
    required this.id,
    required this.name,
    this.provinceOrState,
    this.version,
    this.sections = const [],
  });

  String get subtitle {
    final parts = <String>[
      if (provinceOrState != null && provinceOrState!.isNotEmpty) provinceOrState!,
      if (version != null) 'v$version',
    ];
    return parts.join(' · ');
  }
}

/// One titled section inside a CIR template (Report Form step).
@immutable
class IncidentCirTemplateSection {
  final String key;
  final String title;
  final List<IncidentCirTemplateField> fields;

  const IncidentCirTemplateSection({
    required this.key,
    required this.title,
    this.fields = const [],
  });
}

/// One answerable field inside a CIR template section.
@immutable
class IncidentCirTemplateField {
  final String key;
  final String label;
  final String type;
  final bool required;
  final String helpText;

  const IncidentCirTemplateField({
    required this.key,
    required this.label,
    this.type = 'text',
    this.required = false,
    this.helpText = '',
  });
}
