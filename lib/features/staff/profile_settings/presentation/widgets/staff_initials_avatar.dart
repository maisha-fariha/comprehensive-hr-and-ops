import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/account_photo.dart';

class StaffInitialsAvatar extends StatelessWidget {
  final String initials;
  final Color background;
  final Color foreground;
  final double size;
  final String? imageUrl;

  const StaffInitialsAvatar({
    super.key,
    required this.initials,
    required this.background,
    required this.foreground,
    this.size = 44,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    return AccountPhoto(
      url: imageUrl,
      size: resolvedSize,
      background: background,
      fallback: Text(
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
