import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White header for Profile & Settings: bordered back, centered title,
/// and trailing initials avatar.
class FamilyProfileSettingsHeader extends StatelessWidget {
  final VoidCallback? onBackTap;
  final String initials;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _buttonBorder = Color(0xFFE2E8EE);
  static const Color _bottomBorder = Color(0xFFEEF1F4);
  static const Color _avatarBg = Color(0xFFE8EEFB);
  static const Color _avatarFg = Color(0xFF3F67B1);

  const FamilyProfileSettingsHeader({
    super.key,
    this.onBackTap,
    this.initials = 'EJ',
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return ColoredBox(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _bottomBorder)),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            top: 10,
            bottom: 12,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBackTap ?? Get.back,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _buttonBorder),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: 3.14159,
                    child: const AppSvgIcon(
                      AppAssets.chevronRight,
                      size: 18,
                      color: _titleColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Profile & Settings',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      17,
                    ),
                    color: _titleColor,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
                  color: _avatarBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13,
                    ),
                    color: _avatarFg,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
