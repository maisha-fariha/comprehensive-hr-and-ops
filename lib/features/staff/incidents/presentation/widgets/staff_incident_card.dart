import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import 'incident_severity_style.dart';
import 'incident_status_style.dart';
import 'staff_avatar_chip.dart';
import 'staff_incident_type_icon.dart';

/// A single incident card shown on both tabs of the Staff Incidents list.
///
/// The "My Incidents" tab shows the resident's avatar + name next to the
/// date; the "All Incidents" tab instead shows an "Assigned: {staff}" text
/// row and an outlined "View Details" button, per the Figma screenshots.
class StaffIncidentCard extends StatelessWidget {
  final StaffIncident incident;
  final StaffIncidentsTab tab;
  final VoidCallback? onViewDetails;

  const StaffIncidentCard({
    super.key,
    required this.incident,
    required this.tab,
    this.onViewDetails,
  });

  String get _assignedLabel {
    final names = incident.assignedNames;
    if (names.isEmpty) return 'Assigned: Unassigned';
    if (names.length == 1) return 'Assigned: ${names.first}';
    return 'Assigned: ${names.first} +${names.length - 1}';
  }

  @override
  Widget build(BuildContext context) {
    final severityStyle = IncidentSeverityStyle.of(incident.severity);
    final statusStyle = IncidentStatusStyle.of(incident.status);
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
                  color: severityStyle.background,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 13),
                  ),
                ),
                alignment: Alignment.center,
                child: StaffIncidentTypeIcon(kind: incident.iconKind, color: severityStyle.color, size: 21),
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
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveSize(context, 6),
                          height: ResponsiveHelper.getResponsiveSize(context, 6),
                          decoration: BoxDecoration(color: severityStyle.color, shape: BoxShape.circle),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        Text(
                          severityStyle.label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: severityStyle.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                statusStyle.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: statusStyle.color,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 12)),
            child: Divider(height: 1, color: AppColors.dividerLight),
          ),
          Row(
            children: [
              const AppSvgIcon(AppAssets.navCalendar, size: 14, color: AppColors.textFaint),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                incident.dateTimeLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          if (tab == StaffIncidentsTab.myIncidents)
            Row(
              children: [
                StaffAvatarChip(initials: incident.personInitials),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Expanded(
                  child: Text(
                    incident.personName,
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
            )
          else
            Text(
              _assignedLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textBody,
              ),
            ),
          if (tab == StaffIncidentsTab.allIncidents) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            _ViewDetailsButton(onTap: onViewDetails),
          ],
        ],
      ),
    );
  }
}

/// Outlined "👁 View Details" button shown on every "All Incidents" card.
///
/// Icon note: no eye glyph exists in `assets/icons/*` yet, so this uses
/// the Material `Icons.visibility_outlined` as a temporary stand-in.
class _ViewDetailsButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ViewDetailsButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(context, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: AppColors.secondaryTeal,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                Text(
                  'View Details',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
