import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White top bar for Daily Updates: bordered back, centered title/subtitle,
/// bordered filter.
class FamilyDailyUpdatesAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onFilterTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _subtitleColor = Color(0xFF7D8FA9);
  static const Color _buttonBorder = Color(0xFFE2E8EE);

  const FamilyDailyUpdatesAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          top: 10,
          bottom: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SquareIconButton(
              size: buttonSize,
              radius: radius,
              onTap: onBack ?? Get.back,
              child: Transform.rotate(
                angle: 3.14159,
                child: const AppSvgIcon(
                  AppAssets.chevronRight,
                  size: 18,
                  color: _titleColor,
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                      color: _titleColor,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: _subtitleColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            _SquareIconButton(
              size: buttonSize,
              radius: radius,
              onTap: onFilterTap,
              child: const AppSvgIcon(
                AppAssets.filter,
                size: 18,
                color: _titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final double size;
  final double radius;
  final VoidCallback? onTap;
  final Widget child;

  const _SquareIconButton({
    required this.size,
    required this.radius,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: FamilyDailyUpdatesAppBar._buttonBorder),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
