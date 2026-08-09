import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/staff_incidents_enums.dart';
import '../incident_severity_style.dart';

/// 4-option severity picker in a white elevated card (Create Incident
/// reference): colored dots on every option; selected = tinted fill + border.
class SeverityPillSelector extends StatelessWidget {
  final IncidentSeverity selected;
  final ValueChanged<IncidentSeverity> onChanged;

  static const Color _idleFill = Color(0xFFF4F7F9);
  static const Color _idleLabel = Color(0xFF64748B);

  const SeverityPillSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Color _dotColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return AppColors.activeGreen;
      case IncidentSeverity.medium:
        return AppColors.urgentAmber;
      case IncidentSeverity.high:
        return AppColors.criticalRed;
      case IncidentSeverity.critical:
        return const Color(0xFF9B2C2C);
    }
  }

  Color _selectedFill(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return AppColors.activeBackground;
      case IncidentSeverity.medium:
        return AppColors.urgentBackground;
      case IncidentSeverity.high:
      case IncidentSeverity.critical:
        return AppColors.criticalBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardRadius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final severity in IncidentSeverity.values) ...[
            if (severity != IncidentSeverity.values.first)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(
              child: _SeveritySegment(
                label: IncidentSeverityStyle.of(severity).shortLabel,
                isSelected: severity == selected,
                dotColor: _dotColor(severity),
                selectedFill: _selectedFill(severity),
                onTap: () => onChanged(severity),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeveritySegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color dotColor;
  final Color selectedFill;
  final VoidCallback onTap;

  const _SeveritySegment({
    required this.label,
    required this.isSelected,
    required this.dotColor,
    required this.selectedFill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? dotColor : SeverityPillSelector._idleLabel;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 11,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : SeverityPillSelector._idleFill,
          border: Border.all(
            color: isSelected ? dotColor : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSize(context, 6),
              height: ResponsiveHelper.getResponsiveSize(context, 6),
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: labelColor,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
