import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/incidents_enums.dart';

const Map<IncidentSeverity, String> _severityLabels = {
  IncidentSeverity.low: 'Low',
  IncidentSeverity.medium: 'Medium',
  IncidentSeverity.high: 'High',
  IncidentSeverity.critical: 'Critical',
};

/// 4-segment single-select severity picker (Low / Medium / High / Critical)
/// shown on the wizard's "Details" step. The selected segment always uses
/// the shared "urgent/amber" tone regardless of which severity is picked,
/// matching the single accent color Figma shows on the selected "High"
/// segment (no other selection state was visible in the source screenshot).
class SeveritySelector extends StatelessWidget {
  final IncidentSeverity selected;
  final ValueChanged<IncidentSeverity> onChanged;

  const SeveritySelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final severity in IncidentSeverity.values) ...[
          if (severity != IncidentSeverity.values.first)
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Expanded(
            child: _SeveritySegment(
              label: _severityLabels[severity]!,
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
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeveritySegment({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.urgentBackground : AppColors.surfaceWhite,
          border: Border.all(color: isSelected ? AppColors.urgentAmber : AppColors.searchBorder),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 13),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: isSelected ? AppColors.urgentAmber : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
