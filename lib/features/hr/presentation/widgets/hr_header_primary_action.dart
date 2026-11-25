import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

/// Compact teal header CTA (Schedule-style “+ Shift”).
///
/// Prefer this in the top bar instead of a lone body button that wastes
/// a whole row under the title.
class HrHeaderPrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Key? actionKey;
  final IconData icon;

  const HrHeaderPrimaryAction({
    super.key,
    required this.label,
    required this.onTap,
    this.actionKey,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: actionKey,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryTeal,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(
              context,
              AppDimens.radiusButton,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.getResponsiveSize(context, 16),
              color: Colors.white,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
