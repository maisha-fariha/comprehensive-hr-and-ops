import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/entities/open_incident.dart';
import 'incident_icon_style.dart';

class _SeverityStyle {
  final String label;
  final Color color;
  final Color background;

  const _SeverityStyle({
    required this.label,
    required this.color,
    required this.background,
  });
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
    background: AppColors.criticalIconBackground,
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

const List<(Color, Color)> _reporterPalette = [
  (AppColors.infoBackground, AppColors.infoBlue),
  (AppColors.activeBackground, AppColors.activeGreen),
  (AppColors.nightBackground, AppColors.nightPurple),
  (AppColors.urgentBackground, AppColors.urgentAmber),
];

/// A single card in the "Active Incidents" list on the Open tab — matched
/// to the "Open - Incidents" Figma reference.
class OpenIncidentCard extends StatelessWidget {
  final OpenIncident incident;
  final VoidCallback? onTap;

  const OpenIncidentCard({super.key, required this.incident, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconStyle = IncidentIconStyle.forKind(incident.iconKind);
    final severityStyle = _severityStyles[incident.severity]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 46);
    final reporterPalette = _reporterPalette[
        incident.reporterInitials.hashCode.abs() % _reporterPalette.length];
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 22);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowNavy.withValues(alpha: 0.03),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
            ),
          ],
        ),
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
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: iconStyle.asset != null
                      ? AppSvgIcon(
                          iconStyle.asset!,
                          size: 22,
                          color: iconStyle.color,
                        )
                      : Icon(
                          iconStyle.materialIcon,
                          size: ResponsiveHelper.getResponsiveSize(context, 22),
                          color: iconStyle.color,
                        ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              incident.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  15,
                                ),
                                color: AppColors.textHeading,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(context, 8),
                          ),
                          _PillBadge(
                            label: severityStyle.label,
                            background: severityStyle.background,
                            foreground: severityStyle.color,
                            fontSize: 10.5,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 3),
                      ),
                      Text(
                        incident.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12.5,
                          ),
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 8),
                      ),
                      _PillBadge(
                        label: incident.statusLabel,
                        background: AppColors.urgentBackground,
                        foreground: AppColors.urgentAmber,
                        fontSize: 11.5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Row(
              children: [
                Flexible(
                  child: Text(
                    incident.reportedAtLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        12,
                      ),
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 6,
                  ),
                  child: Container(
                    width: ResponsiveHelper.getResponsiveSize(context, 3),
                    height: ResponsiveHelper.getResponsiveSize(context, 3),
                    decoration: const BoxDecoration(
                      color: AppColors.textFaint,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: reporterPalette.$1,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    incident.reporterInitials,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        9,
                      ),
                      color: reporterPalette.$2,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                Flexible(
                  flex: 2,
                  child: Text(
                    'Reported by ${incident.reporterName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        12,
                      ),
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

class _PillBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;

  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, fontSize),
          color: foreground,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
