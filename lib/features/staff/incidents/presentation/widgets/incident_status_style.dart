import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_incidents_enums.dart';

/// Color + label treatment for an [IncidentStatus], driving the plain
/// colored-text trailing status link on each Staff Incidents list card
/// (not a pill/badge, per the Figma screenshots).
class IncidentStatusStyle {
  final String label;
  final Color color;

  const IncidentStatusStyle({required this.label, required this.color});

  static const Map<IncidentStatus, IncidentStatusStyle> _values = {
    IncidentStatus.open: IncidentStatusStyle(label: 'Open', color: AppColors.secondaryTeal),
    IncidentStatus.inReview: IncidentStatusStyle(label: 'In Review', color: AppColors.urgentAmber),
    IncidentStatus.closed: IncidentStatusStyle(label: 'Closed', color: AppColors.textMuted),
  };

  factory IncidentStatusStyle.of(IncidentStatus status) => _values[status]!;
}
