import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/corrective_action.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'person_avatar_chip.dart';

class _IssueStyle {
  final String svgAsset;
  final Color color;
  final Color background;

  const _IssueStyle({
    required this.svgAsset,
    required this.color,
    required this.background,
  });
}

const Map<CorrectiveIssueType, _IssueStyle> _issueStyles = {
  CorrectiveIssueType.documentationError: _IssueStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_docs_error.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
  ),
  CorrectiveIssueType.safetyImprovement: _IssueStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_shield.svg',
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
  ),
  CorrectiveIssueType.handoverGap: _IssueStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_message.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
  ),
};

class _SeverityStyle {
  final Color color;
  final Color background;
  final String label;

  const _SeverityStyle({
    required this.color,
    required this.background,
    required this.label,
  });
}

const Map<CorrectiveSeverity, _SeverityStyle> _severityStyles = {
  CorrectiveSeverity.high: _SeverityStyle(
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    label: 'HIGH',
  ),
  CorrectiveSeverity.medium: _SeverityStyle(
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
    label: 'MEDIUM',
  ),
};

/// Active Corrective Action card — matched to the Corrective tab reference.
class CorrectiveActionCard extends StatelessWidget {
  final CorrectiveAction action;
  final VoidCallback? onReviewTap;

  static const Color _overdue = Color(0xFFD64545);
  static const Color _inProgress = Color(0xFFB36B21);
  static const Color _open = Color(0xFF2A5DA6);

  const CorrectiveActionCard({
    super.key,
    required this.action,
    this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final issueStyle = _issueStyles[action.issueType]!;
    final severityStyle = _severityStyles[action.severity]!;
    final (statusColor, statusLabel) = switch (action.status) {
      CorrectiveActionStatus.overdue => (_overdue, 'Overdue'),
      CorrectiveActionStatus.inProgress =>
        action.issueType == CorrectiveIssueType.handoverGap
            ? (_open, 'Open')
            : (_inProgress, 'In Progress'),
    };
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: AppSvgIcon(
                        issueStyle.svgAsset,
                        size: 18,
                        color: issueStyle.color,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      13.5,
                                    ),
                                    color: AppColors.textHeading,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveHelper.getResponsiveWidth(context, 8),
                              ),
                              Container(
                                padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: severityStyle.background,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  severityStyle.label,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      10,
                                    ),
                                    color: severityStyle.color,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(context, 5),
                          ),
                          Row(
                            children: [
                              const AppSvgIcon(
                                'assets/icons/tasks_compliance/tasks_shield_outlined.svg',
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(
                                width: ResponsiveHelper.getResponsiveWidth(context, 4),
                              ),
                              Flexible(
                                child: Text(
                                  '${action.locationCategory} · ${action.locationName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w500,
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
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MetaColumn(
                          label: 'ASSIGNED',
                          child: Row(
                            children: [
                              PersonAvatarChip(assignee: action.assignee),
                              SizedBox(
                                width: ResponsiveHelper.getResponsiveWidth(context, 6),
                              ),
                              Flexible(
                                child: Text(
                                  action.assignee.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      13,
                                    ),
                                    color: AppColors.textHeading,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _MetaColumn(
                          label: 'DUE',
                          child: Text(
                            action.dueDateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13,
                              ),
                              color: action.isDueLate
                                  ? _overdue
                                  : AppColors.textHeading,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 14,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.dividerLight)),
            ),
            child: Row(
              children: [
                Container(
                  width: ResponsiveHelper.getResponsiveSize(context, 7),
                  height: ResponsiveHelper.getResponsiveSize(context, 7),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                Expanded(
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: statusColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onReviewTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Review →',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.secondaryTeal,
                    ),
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

class _MetaColumn extends StatelessWidget {
  final String label;
  final Widget child;

  const _MetaColumn({required this.label, required this.child});

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
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
        child,
      ],
    );
  }
}
