import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/status_badge.dart';
import '../../../../../../core/widgets/surface_card.dart';
import '../../../domain/entities/incident_detail.dart';
import '../incident_severity_style.dart';
import '../staff_incident_type_icon.dart';

/// Top overview card on the Incident Details screen: an eyebrow category
/// tag, the incident title with its type icon, a date/time row, severity +
/// status pills, and the incident id.
class IncidentSummaryCard extends StatelessWidget {
  final IncidentDetail detail;

  const IncidentSummaryCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final severityStyle = IncidentSeverityStyle.of(detail.severity);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.categoryLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textFaint,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StaffIncidentTypeIcon(kind: detail.iconKind, color: severityStyle.color, size: 20),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Text(
                  detail.title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: ResponsiveHelper.getResponsiveSize(context, 13),
                color: AppColors.textFaint,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                detail.dateTimeLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            children: [
              StatusBadge.pill(
                label: severityStyle.label,
                background: severityStyle.background,
                foreground: severityStyle.color,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              StatusBadge.pill(
                label: detail.statusLabel,
                background: AppColors.urgentBackground,
                foreground: AppColors.urgentAmber,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Text(
            detail.incidentCode,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
