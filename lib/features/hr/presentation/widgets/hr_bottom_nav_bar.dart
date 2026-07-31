import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';

class HrBottomNavItemData {
  final String asset;
  final String label;
  final int? badgeCount;

  const HrBottomNavItemData({
    required this.asset,
    required this.label,
    this.badgeCount,
  });
}

/// Pixel-accurate reproduction of the Manager dashboard's bottom navigation
/// bar: white surface, subtle top shadow, teal active state and a red
/// counter badge on "Alerts". Lives in the HR role shell so every HR tab
/// shares the same bar.
class HrBottomNavBar extends StatelessWidget {
  static const List<HrBottomNavItemData> items = [
    HrBottomNavItemData(asset: AppAssets.navHome, label: 'Home'),
    HrBottomNavItemData(asset: AppAssets.navCalendar, label: 'Schedule'),
    HrBottomNavItemData(asset: AppAssets.navChecklist, label: 'Attendance'),
    HrBottomNavItemData(asset: AppAssets.navBell, label: 'Alerts', badgeCount: 3),
    HrBottomNavItemData(asset: AppAssets.navMore, label: 'More'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  const HrBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, -ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 10)),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 18,
            top: 10,
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              return Expanded(
                child: _HrBottomNavItem(
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

class _HrBottomNavItem extends StatelessWidget {
  final HrBottomNavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _HrBottomNavItem({
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
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppSvgIcon(data.asset, size: 22, color: color),
                if (data.badgeCount != null && data.badgeCount! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: _AlertsBadge(count: data.badgeCount!),
                  ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
            Text(
              data.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: data.label == 'Attendance' ? FontWeight.w600 : FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsBadge extends StatelessWidget {
  final int count;

  const _AlertsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.criticalRed,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceWhite, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}
