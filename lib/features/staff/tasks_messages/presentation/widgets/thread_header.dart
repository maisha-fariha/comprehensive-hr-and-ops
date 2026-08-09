import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Header for the Message Details thread: bordered back, avatar + status,
/// phone/video actions.
class ThreadHeader extends StatelessWidget {
  final String contactName;
  final String contactInitials;
  final bool isActiveNow;
  final VoidCallback? onBack;
  final VoidCallback? onCallTap;
  final VoidCallback? onVideoTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _activeGreen = Color(0xFF2D8A56);
  static const Color _avatarBg = Color(0xFFE8F0FE);
  static const Color _avatarFg = Color(0xFF2A5DA6);
  static const Color _actionIcon = Color(0xFF0E7C7B);

  const ThreadHeader({
    super.key,
    required this.contactName,
    required this.contactInitials,
    required this.isActiveNow,
    this.onBack,
    this.onCallTap,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final statusDot = ResponsiveHelper.getResponsiveSize(context, 11);

    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
              top: 10,
              bottom: 12,
            ),
            child: Row(
              children: [
                _SquareIconButton(
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
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: const BoxDecoration(
                        color: _avatarBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        contactInitials,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                          color: _avatarFg,
                          height: 1,
                        ),
                      ),
                    ),
                    if (isActiveNow)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: statusDot,
                          height: statusDot,
                          decoration: BoxDecoration(
                            color: _activeGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contactName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                          color: _titleColor,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                      Row(
                        children: [
                          if (isActiveNow) ...[
                            Container(
                              width: ResponsiveHelper.getResponsiveSize(context, 6),
                              height: ResponsiveHelper.getResponsiveSize(context, 6),
                              decoration: const BoxDecoration(
                                color: _activeGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                          ],
                          Flexible(
                            child: Text(
                              isActiveNow ? 'Active now' : 'Offline',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                color: isActiveNow ? _activeGreen : AppColors.textFaint,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                _SquareIconButton(
                  onTap: onCallTap,
                  child: AppSvgIcon(
                    'assets/icons/staff_tasks_messages/phone.svg',
                    size: ResponsiveHelper.getResponsiveSize(context, 18),
                    color: _actionIcon,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                _SquareIconButton(
                  onTap: onVideoTap,
                  child: AppSvgIcon(
                    'assets/icons/staff_tasks_messages/video.svg',
                    size: ResponsiveHelper.getResponsiveSize(context, 18),
                    color: _actionIcon,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SquareIconButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
