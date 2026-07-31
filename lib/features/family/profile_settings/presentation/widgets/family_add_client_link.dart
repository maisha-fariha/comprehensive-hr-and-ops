import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// The "+ Add / Switch Client" teal link row below the "Linked Clients"
/// list — a plain tappable row with no card background.
class FamilyAddClientLink extends StatelessWidget {
  final VoidCallback? onTap;

  const FamilyAddClientLink({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: ResponsiveHelper.getResponsiveFontSize(context, 17),
              color: AppColors.secondaryTeal,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Text(
              'Add / Switch Client',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: AppColors.secondaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
