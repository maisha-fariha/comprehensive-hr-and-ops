import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Shared Staff Incidents header.
///
/// List pages: bordered back + centered title.
/// Create / Details: bordered back + left-aligned title/subtitle + optional
/// trailing (typically a matching bordered icon button).
class StaffIncidentsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  static const Color _subtitle = Color(0xFF6B7280);

  const StaffIncidentsHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  /// Bordered rounded icon button used for back / share on Details.
  static Widget iconButton({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final buttonRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);

    final backButton = iconButton(
      context: context,
      onTap: onBack ?? Get.back,
      child: Transform.rotate(
        angle: 3.14159,
        child: const AppSvgIcon(
          AppAssets.chevronRight,
          size: 18,
          color: AppColors.textHeading,
        ),
      ),
    );

    if (subtitle == null) {
      return ColoredBox(
        color: AppColors.surfaceWhite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 8,
                bottom: 12,
              ),
              child: SizedBox(
                height: buttonSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                        color: AppColors.textHeading,
                        height: 1.2,
                      ),
                    ),
                    Align(alignment: Alignment.centerLeft, child: backButton),
                    if (trailing != null)
                      Align(alignment: Alignment.centerRight, child: trailing!),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 20,
              top: 10,
              bottom: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                backButton,
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                          color: AppColors.textHeading,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: _subtitle,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }
}
