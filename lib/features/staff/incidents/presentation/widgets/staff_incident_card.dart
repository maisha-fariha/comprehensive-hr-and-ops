import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import 'incident_severity_style.dart';
import 'incident_status_style.dart';
import 'staff_incident_type_icon.dart';

/// Incident list card for both Staff Incidents tabs.
///
/// **My Incidents:** icon/title/severity → date → divider → avatar + name +
/// status (no View Details).
///
/// **All Incidents:** same top block → divider → avatar + "Assigned: …" +
/// status → mint outlined View Details button.
class StaffIncidentCard extends StatelessWidget {
  final StaffIncident incident;
  final StaffIncidentsTab tab;
  final VoidCallback? onViewDetails;

  static const Color _divider = Color(0xFFEDF2F5);
  static const Color _dateInk = Color(0xFF7E8CA0);
  static const Color _viewBg = Color(0xFFF3FAF9);
  static const Color _viewBorder = Color(0xFFCFE7E5);

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

  String get _footerInitials {
    if (tab == StaffIncidentsTab.myIncidents) return incident.personInitials;
    final names = incident.assignedNames;
    if (names.isEmpty) return '?';
    return _initialsFromName(names.first);
  }

  String get _footerName {
    if (tab == StaffIncidentsTab.myIncidents) return incident.personName;
    return _assignedLabel;
  }

  static String _initialsFromName(String name) {
    final parts = name
        .replaceAll('.', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return AppColors.infoBlue;
      case IncidentStatus.inReview:
        return AppColors.urgentAmber;
      case IncidentStatus.closed:
        return const Color(0xFF7E8CA0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityStyle = IncidentSeverityStyle.of(incident.severity);
    final statusStyle = IncidentStatusStyle.of(incident.status);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);
    final isAll = tab == StaffIncidentsTab.allIncidents;

    final card = Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: StaffIncidentTypeIcon(
                  kind: incident.iconKind,
                  color: severityStyle.color,
                  size: 20,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: AppColors.textHeading,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                    Row(
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveSize(context, 6),
                          height: ResponsiveHelper.getResponsiveSize(context, 6),
                          decoration: BoxDecoration(
                            color: severityStyle.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        Flexible(
                          child: Text(
                            severityStyle.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              color: severityStyle.color,
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
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            children: [
              const AppSvgIcon(AppAssets.navCalendar, size: 14, color: _dateInk),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Flexible(
                child: Text(
                  incident.dateTimeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: _dateInk,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveHeight(context, 12),
            ),
            child: const Divider(height: 1, thickness: 1, color: _divider),
          ),
          Row(
            children: [
              _CardAvatar(initials: _footerInitials),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Text(
                  _footerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                statusStyle.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: _statusColor(incident.status),
                  height: 1.2,
                ),
              ),
            ],
          ),
          if (isAll) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            _ViewDetailsButton(onTap: onViewDetails),
          ],
        ],
      ),
    );

    if (isAll || onViewDetails == null) return card;

    return GestureDetector(
      onTap: onViewDetails,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _CardAvatar extends StatelessWidget {
  final String initials;

  static const List<(Color, Color)> _palette = [
    (Color(0xFFE8F0FE), Color(0xFF2A5DA6)),
    (Color(0xFFFFF4E5), Color(0xFFD97706)),
    (Color(0xFFF3E8FF), Color(0xFF7C3AED)),
    (Color(0xFFE6F6EE), Color(0xFF2E8C58)),
  ];

  const _CardAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final pair = _palette[initials.hashCode.abs() % _palette.length];
    final size = ResponsiveHelper.getResponsiveSize(context, 28);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: pair.$1, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: pair.$2,
          height: 1,
        ),
      ),
    );
  }
}

/// Mint outlined "View Details" control on All Incidents cards.
class _ViewDetailsButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ViewDetailsButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 12),
        decoration: BoxDecoration(
          color: StaffIncidentCard._viewBg,
          border: Border.all(color: StaffIncidentCard._viewBorder.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 16),
              color: Color(0xFF0E7C7B),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              'View Details',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: Color(0xFF0E7C7B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
