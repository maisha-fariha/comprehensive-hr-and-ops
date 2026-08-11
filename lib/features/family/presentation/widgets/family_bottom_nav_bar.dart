import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';

class FamilyBottomNavItemData {
  final String asset;
  final String label;
  final int? badgeCount;

  const FamilyBottomNavItemData({
    required this.asset,
    required this.label,
    this.badgeCount,
  });
}

/// Bottom navigation for the Family portal: Home / Updates / Appointments /
/// Messages / More. Used by [FamilyShell].
class FamilyBottomNavBar extends StatelessWidget {
  static const Color _activeColor = Color(0xFF107C7C);
  static const Color _inactiveColor = Color(0xFF8E9CB2);
  static const Color _topBorder = Color(0xFFE8EDF1);

  static const List<FamilyBottomNavItemData> items = [
    FamilyBottomNavItemData(asset: AppAssets.navHome, label: 'Home'),
    FamilyBottomNavItemData(asset: AppAssets.navCalendar, label: 'Updates'),
    FamilyBottomNavItemData(asset: AppAssets.navAppointment, label: 'Appointments'),
    FamilyBottomNavItemData(
      asset: AppAssets.messageCircle,
      label: 'Messages',
      badgeCount: 3,
    ),
    FamilyBottomNavItemData(asset: AppAssets.navMore, label: 'More'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  const FamilyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: _topBorder)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveHeight(context, 6),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 6,
            top: 8,
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              return Expanded(
                child: _FamilyBottomNavItem(
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

class _FamilyBottomNavItem extends StatelessWidget {
  final FamilyBottomNavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _FamilyBottomNavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? FamilyBottomNavBar._activeColor : FamilyBottomNavBar._inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppSvgIcon(data.asset, size: 22, color: color),
                if (!isActive && data.badgeCount != null && data.badgeCount! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: _MessagesBadge(count: data.badgeCount!),
                  ),
              ],
            ),
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
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesBadge extends StatelessWidget {
  final int count;

  const _MessagesBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
      padding: const EdgeInsets.symmetric(horizontal: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9),
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}
