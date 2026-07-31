import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/staff_incidents_enums.dart';
import '../incident_severity_style.dart';

/// 4-segment single-select severity picker (Low / Medium / High /
/// Critical) shown on the Create Incident form's "Severity" section.
///
/// Per the Figma screenshot: the selected segment (Medium, by default)
/// renders as a solid colored fill; unselected segments render as a
/// colored outline, with a small leading dot on the higher-risk High and
/// Critical segments to draw extra attention even while unselected.
class SeverityPillSelector extends StatelessWidget {
  final IncidentSeverity selected;
  final ValueChanged<IncidentSeverity> onChanged;

  const SeverityPillSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final severity in IncidentSeverity.values) ...[
          if (severity != IncidentSeverity.values.first)
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Expanded(
            child: _SeveritySegment(
              severity: severity,
              isSelected: severity == selected,
              onTap: () => onChanged(severity),
            ),
          ),
        ],
      ],
    );
  }
}

class _SeveritySegment extends StatelessWidget {
  final IncidentSeverity severity;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeveritySegment({required this.severity, required this.isSelected, required this.onTap});

  bool get _showDot => severity == IncidentSeverity.high || severity == IncidentSeverity.critical;

  @override
  Widget build(BuildContext context) {
    final style = IncidentSeverityStyle.of(severity);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? style.background : AppColors.surfaceWhite,
          border: Border.all(color: isSelected ? style.color : style.color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 13),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showDot && !isSelected) ...[
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 6),
                height: ResponsiveHelper.getResponsiveSize(context, 6),
                decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
            ],
            Flexible(
              child: Text(
                style.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: style.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
