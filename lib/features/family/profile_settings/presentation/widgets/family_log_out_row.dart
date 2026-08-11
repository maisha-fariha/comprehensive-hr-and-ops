import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// Stadium "Sign Out" action at the bottom of Profile & Settings —
/// white fill, soft coral border, centered logout icon + label.
class FamilyLogOutRow extends StatelessWidget {
  final VoidCallback? onTap;

  static const Color _actionColor = Color(0xFFD64545);
  static const Color _borderColor = Color(0xFFF0C9C9);
  static const String _logoutIcon = 'assets/icons/family_more/logout.svg';

  const FamilyLogOutRow({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 999);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const AppSvgIcon(_logoutIcon, size: 18, color: _actionColor),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: _actionColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
