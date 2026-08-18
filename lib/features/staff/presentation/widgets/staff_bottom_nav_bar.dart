import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';

class StaffBottomNavItemData {
  final String asset;
  final String label;

  const StaffBottomNavItemData({required this.asset, required this.label});
}

/// Bottom navigation bar for the Staff portal shell.
class StaffBottomNavBar extends StatelessWidget {
  static const List<StaffBottomNavItemData> items = [
    StaffBottomNavItemData(asset: AppAssets.navHome, label: 'Home'),
    StaffBottomNavItemData(asset: AppAssets.navCalendar, label: 'Schedule'),
    StaffBottomNavItemData(asset: AppAssets.users, label: 'Clients'),
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
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              return Expanded(
                child: _StaffBottomNavItem(
                  data: item,
                  isActive: isActive,
                  onTap: () => onTap(index),
                ),
              );
            }),
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
