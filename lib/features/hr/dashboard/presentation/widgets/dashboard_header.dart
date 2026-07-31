import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/dashboard_overview.dart';

/// The teal gradient hero header: organization switcher, notifications,
/// avatar and the "Good morning" greeting block.
class DashboardHeader extends StatelessWidget {
  final DashboardOverview overview;
  final VoidCallback? onOrganizationTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  const DashboardHeader({
    super.key,
    required this.overview,
    this.onOrganizationTap,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.37, -0.93),
                end: Alignment(0.37, 0.93),
                stops: [0, 0.58, 1],
                colors: [
                  AppColors.secondaryTeal,
                  AppColors.secondaryTealDark,
                  AppColors.secondaryTealDeep,
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -70,
            child: Container(
              width: 230,
              height: 230,
              decoration: const BoxDecoration(
                color: AppColors.whiteOpacity04,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 5,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _OrganizationSwitcher(
                        name: overview.organizationName,
                        onTap: onOrganizationTap,
                      ),
                      Row(
                        children: [
                          _NotificationButton(
                            count: overview.unreadNotificationCount,
                            onTap: onNotificationsTap,
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                          _AvatarButton(
                            initials: overview.avatarInitials,
                            onTap: onAvatarTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                  Text(
                    overview.dateLabel.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.whiteOpacity62,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: ResponsiveHelper.getResponsiveHeight(context, 2),
                      bottom: ResponsiveHelper.getResponsiveHeight(context, 3),
                    ),
                    child: Text(
                      overview.greetingLine,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  Text(
                    overview.greetingSubtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.whiteOpacity80,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationSwitcher extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _OrganizationSwitcher({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, left: 8, right: 14, top: 7, bottom: 7),
        decoration: BoxDecoration(
          color: AppColors.whiteOpacity13,
          border: Border.all(color: AppColors.whiteOpacity16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSize(context, 28),
              height: ResponsiveHelper.getResponsiveSize(context, 28),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 8),
                ),
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(AppAssets.homeSmall, size: 17, color: AppColors.secondaryTeal),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 9)),
            Text(
              name,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: Colors.white,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 9)),
            const AppSvgIcon(AppAssets.chevronDown, size: 16, color: AppColors.whiteOpacity70),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 42);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.whiteOpacity13,
                border: Border.all(color: AppColors.whiteOpacity16),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 13),
                ),
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(AppAssets.bell, size: 20, color: Colors.white),
            ),
            if (count > 0)
              Positioned(
                top: -5,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed,
                    border: Border.all(color: AppColors.secondaryTealDark, width: 2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final String initials;
  final VoidCallback? onTap;

  const _AvatarButton({required this.initials, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 42);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 13),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: AppColors.secondaryTeal,
          ),
        ),
      ),
    );
  }
}
