import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_quick_action.dart';

class _QuickActionVisual {
  final String id;
  final String title;
  final String subtitle;
  final String trailing;
  final String asset;
  final Color iconColor;
  final Color iconBackground;
  final Color trailingColor;

  const _QuickActionVisual({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
    required this.trailingColor,
  });
}

/// UI-hardcoded Quick Action rows from the Staff Dashboard reference.
const List<_QuickActionVisual> _referenceActions = [
  _QuickActionVisual(
    id: 'clock-in-out',
    title: 'Clock In / Out',
    subtitle: 'Tap to manage your shift',
    trailing: 'On Shift',
    asset: AppAssets.clock,
    iconColor: Colors.white,
    iconBackground: Color(0xFF2E8C58),
    trailingColor: Color(0xFF2E8C58),
  ),
  _QuickActionVisual(
    id: 'daily-logs',
    title: 'Start Daily Logs',
    subtitle: 'Record client daily notes',
    trailing: '8 Clients',
    asset: 'assets/icons/team_reports/team_doc.svg',
    iconColor: Color(0xFF2A5DA6),
    iconBackground: Color(0xFFEAF0F9),
    trailingColor: AppColors.textSecondary,
  ),
  _QuickActionVisual(
    id: 'medication-mar',
    title: 'Medication MAR',
    subtitle: 'Administer & record meds',
    trailing: '4 Due',
    asset: 'assets/icons/staff_core/medication_due.svg',
    iconColor: Color(0xFF2A5DA6),
    iconBackground: Color(0xFFEEF2F7),
    trailingColor: AppColors.textSecondary,
  ),
  _QuickActionVisual(
    id: 'my-tasks',
    title: 'My Tasks',
    subtitle: 'View assigned tasks',
    trailing: '6 Due',
    asset: 'assets/icons/staff_core/tasks_due.svg',
    iconColor: Color(0xFF2A5DA6),
    iconBackground: Color(0xFFEAF0F9),
    trailingColor: AppColors.textSecondary,
  ),
];

/// "Quick Actions" heading + vertical list of action cards.
class StaffQuickActionsSection extends StatelessWidget {
  /// Kept for call-site compatibility; reference list is UI-hardcoded.
  final List<StaffQuickAction> actions;
  final ValueChanged<StaffQuickAction>? onActionTap;

  const StaffQuickActionsSection({
    super.key,
    required this.actions,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();
    final visible = _referenceActions.where((item) {
      if (item.id == 'daily-logs') return session.canAccessClients;
      if (item.id == 'medication-mar') return session.canAccessMar;
      return true;
    }).toList();
    final gap = ResponsiveHelper.getResponsiveHeight(context, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _QuickActionCard(
            item: visible[i],
            onTap: onActionTap == null
                ? null
                : () => onActionTap!(
                      StaffQuickAction(
                        id: visible[i].id,
                        asset: visible[i].asset,
                        label: visible[i].title,
                      ),
                    ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionVisual item;
  final VoidCallback? onTap;

  const _QuickActionCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 44);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowNavy.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: item.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(item.asset, size: 20, color: item.iconColor),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              item.trailing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: item.trailingColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
