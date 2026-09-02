import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Full-width outlined red Clock Out button.
class ClockOutButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const ClockOutButton({
    super.key,
    this.onTap,
    this.label = 'Clock Out',
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: const Color(0xFFD64545)),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: const Color(0xFFD64545),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: const Color(0xFFD64545),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
