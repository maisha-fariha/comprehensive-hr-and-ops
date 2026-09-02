import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_dashboard_overview.dart';
import '../../family_dashboard_constants.dart';
import 'family_dashboard_search_bar.dart';

/// Teal hero header: residence switcher, notifications, avatar, and greeting.
class FamilyDashboardHeader extends StatelessWidget {
  final FamilyDashboardOverview overview;
  final VoidCallback? onResidenceTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearchTap;

  static const Color _headerTop = Color(0xFF12807E);
  static const Color _headerMid = Color(0xFF0C6462);
  static const Color _headerBottom = Color(0xFF0A5250);
  static const Color _badgeRed = Color(0xFFE53935);

  const FamilyDashboardHeader({
    super.key,
    required this.overview,
    this.onResidenceTap,
    this.onNotificationsTap,
    this.onAvatarTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = overview.dateLabel.toUpperCase().replaceAll('·', '•');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_headerTop, _headerMid, _headerBottom],
                  ),
                ),
              ),
            ),
            // Single decorative circle — top-right only.
            Positioned(
              top: -110,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
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
                  // Room above the overlapping search bar (centered on the seam).
                  bottom: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _ResidenceSwitcher(
                              name: overview.residenceName,
                              onTap: onResidenceTap,
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
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                    FamilyDashboardSearchBar(onTap: onSearchTap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidenceSwitcher extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _ResidenceSwitcher({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    final logoSize = ResponsiveHelper.getResponsiveSize(context, 28);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          left: 6,
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
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(
                AppAssets.navHome,
                size: 15,
                color: AppColors.secondaryTeal,
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
                    color: FamilyDashboardHeader._badgeRed,
                    border: Border.all(color: FamilyDashboardHeader._headerBottom, width: 1.5),
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

/// Circular avatar placeholder. The reference shows a resident photo; until a
/// media pipeline exists this uses a person glyph plus the purple status badge.
// TODO(figma-asset): swap for the real resident photo once available.
class _AvatarButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AvatarButton({this.onTap});

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
                color: FamilyDashboardColors.avatarPlaceholderBackground,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 22),
                color: FamilyDashboardColors.avatarPlaceholderIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
