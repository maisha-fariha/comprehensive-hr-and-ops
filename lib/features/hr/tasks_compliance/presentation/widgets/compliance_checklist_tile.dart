import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/compliance_checklist_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'person_avatar_chip.dart';

class _ChecklistStatusStyle {
  final String? svgAsset;
  final IconData? materialIcon;
  final Color color;
  final Color background;
  final String badgeLabel;

  const _ChecklistStatusStyle({
    this.svgAsset,
    this.materialIcon,
    required this.color,
    required this.background,
    required this.badgeLabel,
  });
}

const Map<ComplianceItemStatus, _ChecklistStatusStyle> _statusStyles = {
  ComplianceItemStatus.completed: _ChecklistStatusStyle(
    svgAsset: AppAssets.checkCircle,
    color: AppColors.activeGreen,
    background: AppColors.activeIconBackground,
    badgeLabel: 'Completed',
  ),
  ComplianceItemStatus.pending: _ChecklistStatusStyle(
    svgAsset: AppAssets.clock,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
    badgeLabel: 'Pending',
  ),
  // "Due Soon" has no matching exported SVG (a small archive/box glyph in
  // Figma), so it falls back to the closest Material icon.
  ComplianceItemStatus.dueSoon: _ChecklistStatusStyle(
    materialIcon: Icons.inventory_2_outlined,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
    badgeLabel: 'Due Soon',
  ),
};

/// A single row in the "Compliance Checklist" list on the "Compliance" tab.
class ComplianceChecklistTile extends StatelessWidget {
  final ComplianceChecklistItem item;
  final VoidCallback? onTap;

  const ComplianceChecklistTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[item.status]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 12)),
              ),
              alignment: Alignment.center,
              child: style.svgAsset != null
                  ? AppSvgIcon(style.svgAsset!, size: 18, color: style.color)
                  : Icon(
                      style.materialIcon,
                      size: ResponsiveHelper.getResponsiveSize(context, 18),
                      color: style.color,
                    ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.category} · ',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: AppColors.textMuted,
                        ),
                      ),
                      PersonAvatarChip(assignee: item.assignee),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                      Flexible(
                        child: Text(
                          '${item.assignee.name} · ${item.dateLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
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
            StatusBadge.pill(
              label: style.badgeLabel,
              background: style.background,
              foreground: style.color,
            ),
          ],
        ),
      ),
    );
  }
}
