import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/incident_detail.dart';
import '../../../domain/entities/staff_incidents_enums.dart';
import '../incident_severity_style.dart';
import '../staff_incident_type_icon.dart';
import 'high_severity_alert_banner.dart';

/// Top overview card on the Incident Details screen: type icon, category,
/// title, date/time, severity + status pills, incident id, and (when
/// required) the high-severity alert banner.
class IncidentSummaryCard extends StatelessWidget {
  final IncidentDetail detail;

  static const Color _categoryColor = Color(0xFF94A3B8);
  static const Color _metaColor = Color(0xFF64748B);
  static const Color _statusBackground = Color(0xFFFEF3C7);
  static const Color _statusForeground = Color(0xFFD97706);
  static const Color _idBackground = Color(0xFFF1F5F9);
  static const Color _idForeground = Color(0xFF64748B);

  const IncidentSummaryCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final severityStyle = IncidentSeverityStyle.of(detail.severity);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 48);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 24);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
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
                  color: severityStyle.background,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 14),
                  ),
                ),
                alignment: Alignment.center,
                child: StaffIncidentTypeIcon(
                  kind: detail.iconKind,
                  color: severityStyle.color,
                  size: 22,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detail.categoryLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                        color: _categoryColor,
                        letterSpacing: 0.8,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    Text(
                      detail.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                        color: AppColors.textHeading,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                    Row(
                      children: [
                        AppSvgIcon(
                          'assets/icons/staff_incidents/calendar.svg',
                          size: ResponsiveHelper.getResponsiveSize(context, 14),
                          color: _metaColor,
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        Expanded(
                          child: Text(
                            detail.dateTimeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                              color: _metaColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          Wrap(
            spacing: ResponsiveHelper.getResponsiveWidth(context, 8),
            runSpacing: ResponsiveHelper.getResponsiveHeight(context, 8),
            children: [
              _DotPill(
                label: severityStyle.label,
                background: _severityBackground(detail.severity, severityStyle),
                foreground: _severityForeground(detail.severity, severityStyle),
                dotColor: _severityDot(detail.severity, severityStyle),
              ),
              _DotPill(
                label: detail.statusLabel,
                background: _statusBackground,
                foreground: _statusForeground,
                dotColor: _statusForeground,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _IdPill(label: detail.incidentCode),
          if (detail.requiresUrgentReview) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            const HighSeverityAlertBanner(),
          ],
        ],
      ),
    );
  }

  static Color _severityBackground(IncidentSeverity severity, IncidentSeverityStyle style) {
    if (severity == IncidentSeverity.high || severity == IncidentSeverity.critical) {
      return const Color(0xFFFEE2E2);
    }
    return style.background;
  }

  static Color _severityForeground(IncidentSeverity severity, IncidentSeverityStyle style) {
    if (severity == IncidentSeverity.high || severity == IncidentSeverity.critical) {
      return const Color(0xFFB91C1C);
    }
    return style.color;
  }

  static Color _severityDot(IncidentSeverity severity, IncidentSeverityStyle style) {
    if (severity == IncidentSeverity.high || severity == IncidentSeverity.critical) {
      return const Color(0xFFEF4444);
    }
    return style.color;
  }
}

class _DotPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color dotColor;

  const _DotPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 7);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: foreground,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdPill extends StatelessWidget {
  final String label;

  const _IdPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: IncidentSummaryCard._idBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          color: IncidentSummaryCard._idForeground,
          height: 1.1,
        ),
      ),
    );
  }
}
