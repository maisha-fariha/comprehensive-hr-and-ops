import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../incidents/presentation/controllers/incidents_controller.dart';

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

/// Live open-incident count for the Alerts tab badge (null hides the badge).
int? hrAlertsBadgeCount() {
  try {
    if (!Get.isRegistered<IncidentsController>()) {
      Get.put(GetIt.instance<IncidentsController>(), permanent: true);
    }
    final count = Get.find<IncidentsController>().board?.open.activeCount ?? 0;
    return count > 0 ? count : null;
  } catch (_) {
    return null;
  }
}

/// Pixel-accurate reproduction of the Manager dashboard's bottom navigation
/// bar: white surface, subtle top shadow, teal active state and a red
/// counter badge on "Alerts". Lives in the HR role shell so every HR tab
/// shares the same bar.
class HrBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? alertsBadgeCount;

  const HrBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.alertsBadgeCount,
  });

  List<HrBottomNavItemData> get _items => [
        const HrBottomNavItemData(asset: AppAssets.navHome, label: 'Home'),
        const HrBottomNavItemData(
          asset: AppAssets.navCalendar,
          label: 'Schedule',
        ),
        const HrBottomNavItemData(
          asset: AppAssets.navChecklist,
          label: 'Attendance',
        ),
        HrBottomNavItemData(
          asset: AppAssets.navBell,
          label: 'Alerts',
          badgeCount: alertsBadgeCount,
        ),
        const HrBottomNavItemData(asset: AppAssets.navMore, label: 'More'),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
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
        minimum: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
        ),
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
    final color = isActive ? AppColors.secondaryTeal : AppColors.textFaint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppSvgIcon(data.asset, size: 22, color: color),
              if (data.badgeCount != null && data.badgeCount! > 0)
                Positioned(
                  right: -ResponsiveHelper.getResponsiveWidth(context, 10),
                  top: -ResponsiveHelper.getResponsiveHeight(context, 6),
                  child: _AlertsBadge(count: data.badgeCount!),
                ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: color,
            ),
          ),
        ],
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
      constraints: BoxConstraints(
        minWidth: ResponsiveHelper.getResponsiveSize(context, 16),
      ),
      height: ResponsiveHelper.getResponsiveSize(context, 16),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.criticalRed,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9),
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
