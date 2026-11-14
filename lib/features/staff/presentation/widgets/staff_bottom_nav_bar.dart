import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/roles/bottom_nav_promotions.dart';
import '../../../../core/roles/permission_gate.dart';
import '../../../../core/roles/user_session.dart';
import '../../../../core/widgets/app_svg_icon.dart';

class StaffBottomNavItemData {
  final String asset;
  final String label;

  const StaffBottomNavItemData({required this.asset, required this.label});
}

/// Bottom navigation bar for the Staff portal shell.
class StaffBottomNavBar extends StatelessWidget {
  /// Web sidebar order after Scheduling → Attendance; Daily Logs stays next.
  static const List<StaffBottomNavItemData> items = [
    StaffBottomNavItemData(asset: AppAssets.navHome, label: 'Home'),
    StaffBottomNavItemData(asset: AppAssets.navCalendar, label: 'Schedule'),
    StaffBottomNavItemData(asset: AppAssets.clock, label: 'Attendance'),
    StaffBottomNavItemData(asset: AppAssets.users, label: 'Daily Logs'),
    StaffBottomNavItemData(asset: AppAssets.navChecklist, label: 'MAR / Tasks'),
    StaffBottomNavItemData(asset: AppAssets.navMore, label: 'More'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  const StaffBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = Get.isRegistered<UserSession>()
          ? Get.find<UserSession>()
          : null;
      session?.permissionEpoch;
      final slots = <({StaffBottomNavItemData data, VoidCallback onTap, bool active})>[];
      for (var index = 0; index < items.length; index++) {
        final isMore = index == items.length - 1;
        if (session != null && !staffTabAllowed(session, index)) continue;
        if (isMore) continue;
        slots.add((
          data: items[index],
          onTap: () => onTap(index),
          active: index == currentIndex,
        ));
      }

      if (session != null) {
        final room = BottomNavPromotions.staffTargetSlots - slots.length - 1;
        if (room > 0) {
          for (final promo
              in BottomNavPromotions.staffCandidates(session).take(room)) {
            slots.add((
              data: StaffBottomNavItemData(
                asset: promo.asset,
                label: promo.label,
              ),
              onTap: promo.open,
              active: false,
            ));
          }
        }
      }

      slots.add((
        data: items.last,
        onTap: () => onTap(items.length - 1),
        active: currentIndex == items.length - 1,
      ));

      return _bar(context, slots);
    });
  }

  Widget _bar(
    BuildContext context,
    List<({StaffBottomNavItemData data, VoidCallback onTap, bool active})> slots,
  ) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveHeight(context, 6),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 8,
            top: 8,
          ),
          child: Row(
            children: [
              for (final slot in slots)
                Expanded(
                  child: _StaffBottomNavItem(
                    data: slot.data,
                    isActive: slot.active,
                    onTap: slot.onTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffBottomNavItem extends StatelessWidget {
  final StaffBottomNavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _StaffBottomNavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.secondaryTeal : AppColors.navInactive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(data.asset, size: 22, color: color),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
