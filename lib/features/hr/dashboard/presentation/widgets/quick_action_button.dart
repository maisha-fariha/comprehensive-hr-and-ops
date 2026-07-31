import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/dashboard_enums.dart';
import '../../domain/entities/quick_action.dart';

class _QuickActionStyle {
  final String asset;
  final Color iconColor;
  final Color iconBackground;

  const _QuickActionStyle({
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
  });
}

const Map<QuickActionType, _QuickActionStyle> _quickActionStyles = {
  QuickActionType.createShift: _QuickActionStyle(
    asset: AppAssets.calendarPlus,
    iconColor: AppColors.secondaryTeal,
    iconBackground: AppColors.quickActionCreateShiftBg,
  ),
  QuickActionType.approve: _QuickActionStyle(
    asset: AppAssets.checkCircle,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.quickActionApproveBg,
  ),
  QuickActionType.logNote: _QuickActionStyle(
    asset: AppAssets.notePencil,
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.quickActionLogNoteBg,
  ),
  QuickActionType.message: _QuickActionStyle(
    asset: AppAssets.messageCircle,
    iconColor: AppColors.quickActionMessageIcon,
    iconBackground: AppColors.quickActionMessageBg,
  ),
};

/// A single tile in the "Quick Actions" row.
class QuickActionButton extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;

  const QuickActionButton({super.key, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _quickActionStyles[action.type]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 46);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.button(
        padding: ResponsiveHelper.getResponsivePadding(context, top: 16, bottom: 13, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: style.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(style.asset, size: 20, color: style.iconColor),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 9)),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
