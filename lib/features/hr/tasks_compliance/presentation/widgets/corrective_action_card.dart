import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/corrective_action.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'person_avatar_chip.dart';

class _IssueStyle {
  final String? svgAsset;
  final IconData? materialIcon;
  final Color color;
  final Color background;

  const _IssueStyle({this.svgAsset, this.materialIcon, required this.color, required this.background});
}

// "Documentation error" and "safety improvement" glyphs have no exact
// exported SVG match, so they fall back to the closest Material icon;
// "handover gap" reuses the existing message-bubble asset from the
// dashboard icon set.
const Map<CorrectiveIssueType, _IssueStyle> _issueStyles = {
  CorrectiveIssueType.documentationError: _IssueStyle(
    materialIcon: Icons.description_outlined,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
  CorrectiveIssueType.safetyImprovement: _IssueStyle(
    materialIcon: Icons.verified_user_rounded,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
  ),
  CorrectiveIssueType.handoverGap: _IssueStyle(
    svgAsset: AppAssets.messageCircle,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
};

class _SeverityStyle {
  final Color color;
  final Color background;
  final String label;

  const _SeverityStyle({required this.color, required this.background, required this.label});
}

const Map<CorrectiveSeverity, _SeverityStyle> _severityStyles = {
  CorrectiveSeverity.high: _SeverityStyle(
    color: AppColors.criticalRed,
    background: AppColors.criticalBackground,
    label: 'HIGH',
  ),
  CorrectiveSeverity.medium: _SeverityStyle(
    color: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
    label: 'MEDIUM',
  ),
};

const Map<CorrectiveActionStatus, ({Color color, String label})> _statusDotStyles = {
  CorrectiveActionStatus.overdue: (color: AppColors.criticalRed, label: 'Overdue'),
  CorrectiveActionStatus.inProgress: (color: AppColors.urgentAmber, label: 'In Progress'),
};

/// A single card in the "Active Corrective Actions" list on the
/// "Corrective" tab.
class CorrectiveActionCard extends StatelessWidget {
  final CorrectiveAction action;
  final VoidCallback? onReviewTap;

  const CorrectiveActionCard({super.key, required this.action, this.onReviewTap});

  @override
  Widget build(BuildContext context) {
    final issueStyle = _issueStyles[action.issueType]!;
    final severityStyle = _severityStyles[action.severity]!;
    final dotStyle = _statusDotStyles[action.status]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return SurfaceCard.card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
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
                        color: issueStyle.background,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 12)),
                      ),
                      alignment: Alignment.center,
                      child: issueStyle.svgAsset != null
                          ? AppSvgIcon(issueStyle.svgAsset!, size: 18, color: issueStyle.color)
                          : Icon(
                              issueStyle.materialIcon,
                              size: ResponsiveHelper.getResponsiveSize(context, 18),
                              color: issueStyle.color,
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
                                  action.title,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    color: AppColors.textHeading,
                                  ),
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
                          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Figma's location-pin glyph has no exported
                              // SVG match, so it falls back to a Material
                              // icon.
                              Icon(
                                Icons.location_on_outlined,
                                size: ResponsiveHelper.getResponsiveSize(context, 12),
                                color: AppColors.textFaint,
                              ),
                              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                              Text(
                                '${action.locationCategory} · ${action.locationName}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w500,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                  color: AppColors.secondaryTeal,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.secondaryTeal,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _AssignedDueColumn(
                        label: 'ASSIGNED',
                        trailingText: action.assignee.name,
                        child: PersonAvatarChip(assignee: action.assignee),
                      ),
                    ),
                    Expanded(
                      child: _DueColumn(
                        dateLabel: action.dueDateLabel,
                        isLate: action.isDueLate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.dividerLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 7),
                      height: ResponsiveHelper.getResponsiveSize(context, 7),
                      decoration: BoxDecoration(color: dotStyle.color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                    Text(
                      dotStyle.label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: dotStyle.color,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onReviewTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Review',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: ResponsiveHelper.getResponsiveSize(context, 13),
                        color: AppColors.secondaryTeal,
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

class _AssignedDueColumn extends StatelessWidget {
  final String label;
  final Widget child;
  final String trailingText;

  const _AssignedDueColumn({required this.label, required this.child, required this.trailingText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Flexible(
              child: Text(
                trailingText,
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
    );
  }
}

class _DueColumn extends StatelessWidget {
  final String dateLabel;
  final bool isLate;

  const _DueColumn({required this.dateLabel, required this.isLate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DUE',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
        Text(
          dateLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: isLate ? AppColors.criticalRed : AppColors.textHeading,
          ),
        ),
      ],
    );
  }
}
