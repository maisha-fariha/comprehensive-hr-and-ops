import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/closed_incident.dart';
import 'incident_icon_style.dart';
import 'initials_avatar_chip.dart';

/// A single row in the "Resolved Incidents" list on the Closed tab. Renders
/// either a "Resolved" (green, with a reviewer) or "Archived" (grey, no
/// reviewer) footer depending on [ClosedIncident.isArchived].
class ClosedIncidentCard extends StatelessWidget {
  final ClosedIncident incident;

  const ClosedIncidentCard({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final iconStyle = IncidentIconStyle.forKind(incident.iconKind);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 46);

    return SurfaceCard.card(
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
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: iconStyle.asset != null
                    ? AppSvgIcon(
                        iconStyle.asset!,
                        size: 21,
                        color: AppColors.textSecondary,
                      )
                    : Icon(
                        iconStyle.materialIcon,
                        size: ResponsiveHelper.getResponsiveSize(context, 21),
                        color: AppColors.textSecondary,
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
              if (incident.isArchived)
                StatusBadge(
                  label: 'Archived',
                  background: AppColors.dividerLight,
                  foreground: AppColors.textSecondary,
                  radius: 999,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                )
              else
                StatusBadge(
                  label: '✓ Resolved',
                  background: AppColors.activeBackground,
                  foreground: AppColors.activeGreen,
                  radius: 999,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 14)),
            child: Divider(height: 1, color: AppColors.dividerLight),
          ),
          Padding(
            padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColumnLabel(incident.isArchived ? 'ARCHIVED' : 'RESOLVED'),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                      Text(
                        incident.dateLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                          color: AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                ),
                if (incident.reviewerName != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ColumnLabel('REVIEWED BY'),
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                        Row(
                          children: [
                            InitialsAvatarChip(initials: incident.reviewerInitials!),
                            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                            Flexible(
                              child: Text(
                                incident.reviewerName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                                  color: AppColors.textHeading,
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
          ),
        ],
      ),
    );
  }
}

class _ColumnLabel extends StatelessWidget {
  final String text;

  const _ColumnLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
        color: AppColors.textFaint,
        letterSpacing: 0.3,
      ),
    );
  }
}
