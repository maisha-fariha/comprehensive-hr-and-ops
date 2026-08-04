import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/compliance_checklist_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'person_avatar_chip.dart';

class _ChecklistStatusStyle {
  final String svgAsset;
  final Color color;
  final Color background;
  final String badgeLabel;

  const _ChecklistStatusStyle({
    required this.svgAsset,
    required this.color,
    required this.background,
    required this.badgeLabel,
  });
}

const Map<ComplianceItemStatus, _ChecklistStatusStyle> _statusStyles = {
  ComplianceItemStatus.completed: _ChecklistStatusStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_tick.svg',
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
    badgeLabel: 'Completed',
  ),
  ComplianceItemStatus.pending: _ChecklistStatusStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_clock.svg',
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
    badgeLabel: 'Pending',
  ),
  ComplianceItemStatus.dueSoon: _ChecklistStatusStyle(
    svgAsset: 'assets/icons/tasks_compliance/taska_training.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
    badgeLabel: 'Due Soon',
  ),
};

/// Compliance Checklist row — matched to the Compliance tab reference.
class ComplianceChecklistTile extends StatelessWidget {
  final ComplianceChecklistItem item;
  final VoidCallback? onTap;

  const ComplianceChecklistTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[item.status]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(style.svgAsset, size: 16, color: style.color),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textHeading,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${item.category} · ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      PersonAvatarChip(assignee: item.assignee),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${item.assignee.name} · ${item.dateLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Container(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                style.badgeLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                  color: style.color,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
