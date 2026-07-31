import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_enums.dart';

class _AvatarStyle {
  final Color background;
  final Color foreground;

  const _AvatarStyle({required this.background, required this.foreground});
}

const Map<AvatarPalette, _AvatarStyle> _avatarStyles = {
  AvatarPalette.blue: _AvatarStyle(
    background: AppColors.infoBackground,
    foreground: AppColors.infoBlue,
  ),
  AvatarPalette.green: _AvatarStyle(
    background: AppColors.activeBackground,
    foreground: AppColors.activeGreen,
  ),
  AvatarPalette.purple: _AvatarStyle(
    background: AppColors.nightBackground,
    foreground: AppColors.nightPurple,
  ),
};

/// Circular initials avatar used for residents and staff across every
/// Medication tab (list rows, "ASSIGNED"/"REPORTED BY" mini-labels).
class MedicationAvatar extends StatelessWidget {
  final String initials;
  final AvatarPalette palette;
  final double size;

  const MedicationAvatar({
    super.key,
    required this.initials,
    required this.palette,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final style = _avatarStyles[palette]!;
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);

    return Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(color: style.background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.34),
          color: style.foreground,
        ),
      ),
    );
  }
}
