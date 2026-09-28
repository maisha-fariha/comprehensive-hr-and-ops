import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Full-width Clock In / Clock Out button (BUG_Report020).
class ClockOutButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool isClockOut;

  const ClockOutButton({
    super.key,
    this.onTap,
    this.label = 'Clock Out',
    this.isClockOut = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    final accent = isClockOut
        ? const Color(0xFFD64545)
        : AppColors.secondaryTeal;
    final fill = isClockOut ? AppColors.surfaceWhite : AppColors.secondaryTeal;
    final fg = isClockOut ? accent : Colors.white;

    return GestureDetector(
      key: Key(isClockOut ? 'staff-attendance-clock-out' : 'staff-attendance-clock-in'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: accent, width: 1.5),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isClockOut ? Icons.logout_rounded : Icons.login_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: fg,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
