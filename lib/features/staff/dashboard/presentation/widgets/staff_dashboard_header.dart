import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_dashboard_overview.dart';

/// How far [TodayShiftCard] overlaps the gradient header.
const double kStaffShiftCardOverlap = 38;

/// Teal gradient hero: org switcher, notifications, avatar, greeting.
class StaffDashboardHeader extends StatelessWidget {
  final StaffDashboardOverview overview;
  final VoidCallback? onOrganizationTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  const StaffDashboardHeader({
    super.key,
    required this.overview,
    this.onOrganizationTap,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = overview.dateLabel.toUpperCase().replaceAll('·', '•');

    // No ClipRect — bottom-left circle must overflow below the header.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B6B66),
                  Color(0xFF085550),
                  Color(0xFF064743),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -70,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Bottom-left decorative circle — peeks under the shift card onto
        // the scaffold top-left (needs parent Stack clipBehavior: none).
        Positioned(
          left: -ResponsiveHelper.getResponsiveWidth(context, 72),
          bottom: -ResponsiveHelper.getResponsiveHeight(context, 70),
          child: Container(
            width: ResponsiveHelper.getResponsiveSize(context, 210),
            height: ResponsiveHelper.getResponsiveSize(context, 210),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 20,
              top: 8,
              bottom: 54,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _OrganizationSwitcher(
                          name: overview.organizationName,
                          onTap: onOrganizationTap,
                        ),
                      ),
                    ),
                    _NotificationButton(
                      count: overview.unreadNotificationCount,
                      onTap: onNotificationsTap,
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                    _AvatarButton(onTap: onAvatarTap),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.9,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Text(
                  overview.greetingLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
                    color: Colors.white,
                    letterSpacing: -0.35,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                Text(
                  overview.greetingSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganizationSwitcher extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _OrganizationSwitcher({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    final logoSize = ResponsiveHelper.getResponsiveSize(context, 30);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          left: 7,
          right: 12,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 8),
                ),
              ),
              alignment: Alignment.center,
              // No leaf SVG in assets — eco stands in for the brand mark.
              child: SvgPicture.asset(
                'assets/icons/staff_core/leaf.svg',
                width: ResponsiveHelper.getResponsiveSize(context, 17),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 9)),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 20),
              color: Colors.white.withValues(alpha: 0.92),
            ),
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
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(AppAssets.bell, size: 20, color: Colors.white),
            ),
            if (count > 0)
              Positioned(
                top: -3,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    border: Border.all(color: const Color(0xFF064743), width: 1.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                      color: Colors.white,
                      height: 1.1,
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
  final VoidCallback? onTap;

  const _AvatarButton({this.onTap});

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
          color: const Color(0xFFE8EEF0),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.person_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 22),
          color: const Color(0xFF8A97A8),
        ),
      ),
    );
  }
}
