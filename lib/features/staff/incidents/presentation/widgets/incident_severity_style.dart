import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_incidents_enums.dart';

/// Color + label treatment for an [IncidentSeverity], shared by the list
/// card's leading icon + severity tag, the Create Incident severity picker,
/// and the Incident Details severity pill - so every screen in this
/// feature stays visually consistent with a single source of truth.
class IncidentSeverityStyle {
  final String label;
  final String shortLabel;
  final Color color;
  final Color background;

  const IncidentSeverityStyle({
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.background,
  });

  static const Map<IncidentSeverity, IncidentSeverityStyle> _values = {
    IncidentSeverity.low: IncidentSeverityStyle(
      label: 'Low Severity',
      shortLabel: 'Low',
      color: AppColors.activeGreen,
      background: AppColors.activeBackground,
    ),
    IncidentSeverity.medium: IncidentSeverityStyle(
      label: 'Medium Severity',
      shortLabel: 'Medium',
      color: AppColors.urgentAmber,
      background: AppColors.urgentBackground,
    ),
    IncidentSeverity.high: IncidentSeverityStyle(
      label: 'High Severity',
      shortLabel: 'High',
      color: AppColors.criticalRed,
      background: AppColors.criticalBackground,
    ),
    IncidentSeverity.critical: IncidentSeverityStyle(
      label: 'Critical Severity',
      shortLabel: 'Critical',
      color: AppColors.criticalRed,
      background: AppColors.criticalBackground,
    ),
  };

  factory IncidentSeverityStyle.of(IncidentSeverity severity) => _values[severity]!;
}
