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
/// **My Incidents:** reference card — icon/title/severity → calendar date →
/// divider → avatar + name + status (tappable, no View Details).
///
/// **All Incidents:** prior layout with Assigned footer + View Details.
class StaffIncidentCard extends StatelessWidget {
  final StaffIncident incident;
  final StaffIncidentsTab tab;
  final VoidCallback? onViewDetails;

  static const Color _divider = Color(0xFFEDF2F5);
  static const Color _dateInk = Color(0xFF7E8CA0);
  static const Color _viewBg = Color(0xFFF3FAF9);
  static const Color _viewBorder = Color(0xFFCFE7E5);
  static const Color _myTitle = Color(0xFF1A2B3C);
  static const Color _closedStatus = Color(0xFF5B6B7C);

  const StaffIncidentCard({
    super.key,
    required this.incident,
    required this.tab,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (tab == StaffIncidentsTab.myIncidents) {
      final card = _MyIncidentCard(incident: incident);
      if (onViewDetails == null) return card;
      return GestureDetector(
        onTap: onViewDetails,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return _AllIncidentCard(
      incident: incident,
      onViewDetails: onViewDetails,
    );
  }
}

/// My Incidents card — matched to the staff incidents reference screenshot.
class _MyIncidentCard extends StatelessWidget {
  final StaffIncident incident;

  const _MyIncidentCard({required this.incident});

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return AppColors.infoBlue;
      case IncidentStatus.inReview:
        return AppColors.urgentAmber;
      case IncidentStatus.closed:
        return StaffIncidentCard._closedStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityStyle = IncidentSeverityStyle.of(incident.severity);
    final statusStyle = IncidentStatusStyle.of(incident.status);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2B3C).withValues(alpha: 0.07),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
            spreadRadius: 0,
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
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          16.5,
                        ),
                        color: StaffIncidentCard._myTitle,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 6),
                    ),
                    Row(
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveSize(context, 7),
                          height: ResponsiveHelper.getResponsiveSize(context, 7),
                          decoration: BoxDecoration(
                            color: severityStyle.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(context, 6),
                        ),
                        Flexible(
                          child: Text(
                            severityStyle.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12.5,
                              ),
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
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          Row(
            children: [
              const AppSvgIcon(
                AppAssets.navCalendar,
                size: 15,
                color: StaffIncidentCard._dateInk,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
              Flexible(
                child: Text(
                  incident.dateTimeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: StaffIncidentCard._dateInk,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
            ),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: StaffIncidentCard._divider,
            ),
          ),
          Row(
            children: [
              _MyCardAvatar(initials: incident.personInitials),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: Text(
                  incident.personName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: StaffIncidentCard._myTitle,
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
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _statusColor(incident.status),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyCardAvatar extends StatelessWidget {
  final String initials;

  /// Pastel chips matching the My Incidents reference (lavender / mint / rose).
  static const List<(Color, Color)> _palette = [
    (Color(0xFFEDE7F6), Color(0xFF6D5BCE)),
    (Color(0xFFE6F6EE), Color(0xFF2E8C58)),
    (Color(0xFFFCE7F0), Color(0xFFC2478E)),
    (Color(0xFFE8F0FE), Color(0xFF2A5DA6)),
  ];

  const _MyCardAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final pair = _palette[initials.hashCode.abs() % _palette.length];
    final size = ResponsiveHelper.getResponsiveSize(context, 30);

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
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: pair.$2,
          height: 1,
        ),
      ),
    );
  }
}

/// All Incidents card — previous layout preserved (Assigned + View Details).
class _AllIncidentCard extends StatelessWidget {
  final StaffIncident incident;
  final VoidCallback? onViewDetails;

  const _AllIncidentCard({
    required this.incident,
    this.onViewDetails,
  });

  String get _assignedLabel {
    final names = incident.assignedNames;
    if (names.isEmpty) return 'Assigned: Unassigned';
    if (names.length == 1) return 'Assigned: ${names.first}';
    return 'Assigned: ${names.first} +${names.length - 1}';
  }

  String get _footerInitials {
    final names = incident.assignedNames;
    if (names.isEmpty) return '?';
    return _initialsFromName(names.first);
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

    return Container(
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
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          15,
                        ),
                        color: AppColors.textHeading,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 5),
                    ),
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
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(context, 6),
                        ),
                        Flexible(
                          child: Text(
                            severityStyle.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12,
                              ),
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
              const AppSvgIcon(
                AppAssets.navCalendar,
                size: 14,
                color: StaffIncidentCard._dateInk,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Flexible(
                child: Text(
                  incident.dateTimeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: StaffIncidentCard._dateInk,
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
            child: const Divider(
              height: 1,
              thickness: 1,
              color: StaffIncidentCard._divider,
            ),
          ),
          Row(
            children: [
              _AllCardAvatar(initials: _footerInitials),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Text(
                  _assignedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
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
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: _statusColor(incident.status),
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _ViewDetailsButton(onTap: onViewDetails),
        ],
      ),
    );
  }
}

class _AllCardAvatar extends StatelessWidget {
  final String initials;

  static const List<(Color, Color)> _palette = [
    (Color(0xFFE8F0FE), Color(0xFF2A5DA6)),
    (Color(0xFFFFF4E5), Color(0xFFD97706)),
    (Color(0xFFF3E8FF), Color(0xFF7C3AED)),
    (Color(0xFFE6F6EE), Color(0xFF2E8C58)),
  ];

  const _AllCardAvatar({required this.initials});

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
          border: Border.all(
            color: StaffIncidentCard._viewBorder.withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 16),
              color: const Color(0xFF0E7C7B),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              'View Details',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: const Color(0xFF0E7C7B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
