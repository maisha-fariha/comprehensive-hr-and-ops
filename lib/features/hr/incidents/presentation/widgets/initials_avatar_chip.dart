import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

class _AvatarPalette {
  final Color background;
  final Color foreground;

  const _AvatarPalette({required this.background, required this.foreground});
}

/// Small color palette cycled deterministically by a person's initials, so
/// the same person always renders with the same color (matching the
/// variety of avatar chip colors seen across the Figma incident cards:
/// mint-green, sky-blue and lavender-purple).
const List<_AvatarPalette> _avatarPalette = [
  _AvatarPalette(background: AppColors.activeBackground, foreground: AppColors.activeGreen),
  _AvatarPalette(background: AppColors.infoBackground, foreground: AppColors.infoBlue),
  _AvatarPalette(background: AppColors.nightBackground, foreground: AppColors.nightPurple),
  _AvatarPalette(background: AppColors.urgentBackground, foreground: AppColors.urgentAmber),
];

/// Small pill-shaped "initials" avatar used next to a reporter/investigator/
/// reviewer name, e.g. the "MT" chip in "Reported by Mike T." or the "SW"
/// chip in "Sarah Williams".
class InitialsAvatarChip extends StatelessWidget {
  final String initials;

  const InitialsAvatarChip({super.key, required this.initials});

  @override
  Widget build(BuildContext context) {
    final palette = _avatarPalette[initials.hashCode.abs() % _avatarPalette.length];
    final size = ResponsiveHelper.getResponsiveSize(context, 20);

    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 5),
      decoration: BoxDecoration(color: palette.background, borderRadius: BorderRadius.circular(999)),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
          color: palette.foreground,
          height: 1.2,
        ),
      ),
    );
  }
}
