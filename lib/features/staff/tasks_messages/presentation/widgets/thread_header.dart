import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../staff_tasks_messages_constants.dart';

/// Header for the Message Details (conversation thread) screen: a back
/// chevron, a small avatar, the contact's name + "Active now"/"Offline"
/// status line, and phone/video call icon buttons.
///
/// Icon note: no matching SVGs exist in `assets/icons/*` for a back
/// chevron, phone-call or video-call glyph, so this uses
/// `Icons.arrow_back_ios_new_rounded`, `Icons.call_rounded` and
/// `Icons.videocam_rounded` as temporary stand-ins.
class ThreadHeader extends StatelessWidget {
  final String contactName;
  final String contactInitials;
  final bool isActiveNow;
  final VoidCallback? onBack;
  final VoidCallback? onCallTap;
  final VoidCallback? onVideoTap;

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
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.avatarSizeLarge - 8);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, top: 10, bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? Get.back,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(color: AppColors.infoIconBackground, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              contactInitials,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.infoBlue,
              ),
            ),
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
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActiveNow) ...[
                      Container(
                        width: ResponsiveHelper.getResponsiveSize(context, 6),
                        height: ResponsiveHelper.getResponsiveSize(context, 6),
                        decoration: const BoxDecoration(color: AppColors.activeGreen, shape: BoxShape.circle),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                    ],
                    Text(
                      isActiveNow ? 'Active now' : 'Offline',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                        color: isActiveNow ? AppColors.activeGreen : AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CircleIconButton(icon: Icons.call_rounded, onTap: onCallTap),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          _CircleIconButton(icon: Icons.videocam_rounded, onTap: onVideoTap),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 36);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.filterButtonBackground, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 18), color: AppColors.secondaryTeal),
      ),
    );
  }
}
