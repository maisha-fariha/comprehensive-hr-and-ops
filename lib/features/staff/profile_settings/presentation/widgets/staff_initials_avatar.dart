import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

class StaffInitialsAvatar extends StatelessWidget {
  final String initials;
  final Color background;
  final Color foreground;
  final double size;

  const StaffInitialsAvatar({
    super.key,
    required this.initials,
    required this.background,
    required this.foreground,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    return Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.32),
          color: foreground,
        ),
      ),
    );
  }
}
