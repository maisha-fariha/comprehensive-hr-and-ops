import 'package:flutter/foundation.dart';

import 'incidents_enums.dart';

/// A single row in the "In Investigation" list on the Under Review tab.
@immutable
class InvestigationIncident {
  final String id;
  final String title;
  final IncidentIconKind iconKind;
  final String statusLabel;
  final String subtitle;
  final String investigatorInitials;
  final String investigatorName;
  final String startedAtLabel;

  const InvestigationIncident({
    required this.id,
    required this.title,
    required this.iconKind,
    required this.statusLabel,
    required this.subtitle,
    required this.investigatorInitials,
    required this.investigatorName,
    required this.startedAtLabel,
  });
}
