import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// The "+ Add / Switch Client" teal action row at the bottom of the
/// Linked Clients card.
class FamilyAddClientLink extends StatelessWidget {
  final VoidCallback? onTap;

  static const Color _actionColor = Color(0xFF0E7C7B);
  static const String _plusIcon =
      'assets/icons/family_appointments/plus_outlined.svg';

  const FamilyAddClientLink({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(Icons.add_rounded, color: _actionColor, size: 20,),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              'Add / Switch Client',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
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
