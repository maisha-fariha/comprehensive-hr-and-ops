import 'package:flutter/foundation.dart';

/// A selectable CIR template from `GET /incidents/cir-templates`.
@immutable
class IncidentCirTemplateOption {
  final String id;
  final String name;
  final String? provinceOrState;
  final int? version;

  const IncidentCirTemplateOption({
    required this.id,
    required this.name,
    this.provinceOrState,
    this.version,
  });

  String get subtitle {
    final parts = <String>[
      if (provinceOrState != null && provinceOrState!.isNotEmpty) provinceOrState!,
      if (version != null) 'v$version',
    ];
    return parts.join(' · ');
  }
}
