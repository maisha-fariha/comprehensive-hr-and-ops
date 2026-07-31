import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/entities/open_incident.dart';
import 'incident_icon_style.dart';
import 'initials_avatar_chip.dart';

class _SeverityStyle {
  final String label;
  final Color color;
  final Color background;

  const _SeverityStyle({required this.label, required this.color, required this.background});
}

const Map<IncidentSeverity, _SeverityStyle> _severityStyles = {
  IncidentSeverity.low: _SeverityStyle(
    label: 'LOW',
    color: AppColors.activeGreen,
    background: AppColors.activeBackground,
  ),
  IncidentSeverity.critical: _SeverityStyle(
    label: 'CRITICAL',
    color: AppColors.criticalRed,
    background: AppColors.criticalBackground,
  ),
  IncidentSeverity.high: _SeverityStyle(
    label: 'HIGH',
    color: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
  ),
  IncidentSeverity.medium: _SeverityStyle(
    label: 'MEDIUM',
    color: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
  ),
};

/// A single row in the "Active Incidents" list on the Open tab.
class OpenIncidentCard extends StatelessWidget {
  final OpenIncident incident;
  final VoidCallback? onTap;

  const OpenIncidentCard({super.key, required this.incident, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconStyle = IncidentIconStyle.forKind(incident.iconKind);
    final severityStyle = _severityStyles[incident.severity]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 46);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: iconStyle.background,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 13),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    iconStyle.icon,
                    size: ResponsiveHelper.getResponsiveSize(context, 21),
                    color: iconStyle.color,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        incident.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                          color: AppColors.textHeading,
                        ),
                      ),
                      Text(
                        incident.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                StatusBadge.pill(
                  label: severityStyle.label,
                  background: severityStyle.background,
                  foreground: severityStyle.color,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            StatusBadge(
              label: incident.statusLabel,
              background: AppColors.urgentBackground,
              foreground: AppColors.urgentAmber,
              radius: 999,
              fontSize: 11.5,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 12)),
              child: Divider(height: 1, color: AppColors.dividerLight),
            ),
            Row(
              children: [
                Text(
                  '${incident.reportedAtLabel} · ',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
                InitialsAvatarChip(initials: incident.reporterInitials),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                Expanded(
                  child: Text(
                    'Reported by ${incident.reporterName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
