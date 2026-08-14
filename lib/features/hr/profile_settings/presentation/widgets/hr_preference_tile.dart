import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/hr_preference_item.dart';
import '../../hr_profile_settings_constants.dart';

class HrPreferenceTile extends StatelessWidget {
  final HrPreferenceItem item;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _chevronColor = Color(0xFFC5CCD6);

  const HrPreferenceTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final iconAsset = HrProfileSettingsConstants.preferenceIconAsset(item.type);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: HrProfileSettingsConstants.preferenceIconBackground,
                borderRadius: BorderRadius.circular(radius),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(
                iconAsset,
                size: 20,
                color: HrProfileSettingsConstants.preferenceIconForeground,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                  color: _titleColor,
                  height: 1.25,
                ),
              ),
            ),
            const AppSvgIcon(
              AppAssets.chevronRight,
              size: 18,
              color: _chevronColor,
            ),
          ],
        ),
      ),
    );
  }
}
