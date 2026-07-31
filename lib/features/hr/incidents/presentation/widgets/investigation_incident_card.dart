import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/investigation_incident.dart';
import 'incident_icon_style.dart';
import 'initials_avatar_chip.dart';

/// A single row in the "In Investigation" list on the Under Review tab.
///
/// Icon note: the "View Investigation" (eye) and "Add Note" (pencil) action
/// glyphs have no matching SVG in `assets/icons/*` (the closest existing
/// asset, `note_pencil.svg`, is a paper+pencil combo icon rather than a
/// plain pencil), so this uses Material `Icons.visibility_outlined` and
/// `Icons.edit_outlined` as temporary stand-ins.
class InvestigationIncidentCard extends StatelessWidget {
  final InvestigationIncident incident;
  final VoidCallback? onViewInvestigation;
  final VoidCallback? onAddNote;

  const InvestigationIncidentCard({
    super.key,
    required this.incident,
    this.onViewInvestigation,
    this.onAddNote,
  });

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
              _OngoingPill(label: incident.statusLabel),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColumnLabel('ASSIGNED INVESTIGATOR'),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                      Row(
                        children: [
                          InitialsAvatarChip(initials: incident.investigatorInitials),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                          Flexible(
                            child: Text(
                              incident.investigatorName,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColumnLabel('STARTED'),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                      Text(
                        incident.startedAtLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.dividerLight),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            children: [
              Expanded(
                child: _OutlinedActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'View Investigation',
                  color: AppColors.secondaryTeal,
                  onTap: onViewInvestigation,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: _OutlinedActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Add Note',
                  color: AppColors.textSecondary,
                  onTap: onAddNote,
                ),
              ),
            ],
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

class _OngoingPill extends StatelessWidget {
  final String label;

  const _OngoingPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 6),
            height: ResponsiveHelper.getResponsiveSize(context, 6),
            decoration: const BoxDecoration(color: AppColors.infoBlue, shape: BoxShape.circle),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.infoBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _OutlinedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 15), color: color),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
