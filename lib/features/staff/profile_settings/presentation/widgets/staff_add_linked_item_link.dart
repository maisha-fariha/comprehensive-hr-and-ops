import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

class StaffAddLinkedItemLink extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  static const Color _actionColor = Color(0xFF0E7C7B);

  const StaffAddLinkedItemLink({
    super.key,
    this.onTap,
    this.label = 'Add / Switch Client',
  });

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
            const Icon(Icons.add_rounded, color: _actionColor, size: 20),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              label,
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
