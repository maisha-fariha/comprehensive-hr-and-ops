import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

class _AvatarPalette {
  final Color background;
  final Color foreground;

  const _AvatarPalette({required this.background, required this.foreground});
}

/// Small color palette cycled deterministically by a person's initials, so
/// the same person always renders with the same color.
const List<_AvatarPalette> _avatarPalette = [
  _AvatarPalette(background: AppColors.activeBackground, foreground: AppColors.activeGreen),
  _AvatarPalette(background: AppColors.infoBackground, foreground: AppColors.infoBlue),
  _AvatarPalette(background: AppColors.nightBackground, foreground: AppColors.nightPurple),
  _AvatarPalette(background: AppColors.urgentBackground, foreground: AppColors.urgentAmber),
];

/// Small pill-shaped "initials" avatar used next to a resident/reporter
/// name throughout the Staff Incidents feature.
class StaffAvatarChip extends StatelessWidget {
  final String initials;
  final double size;

  const StaffAvatarChip({super.key, required this.initials, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final palette = _avatarPalette[initials.hashCode.abs() % _avatarPalette.length];
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);

    return Container(
      constraints: BoxConstraints(minWidth: resolvedSize),
      height: resolvedSize,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6),
      decoration: BoxDecoration(color: palette.background, borderRadius: BorderRadius.circular(999)),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: palette.foreground,
          height: 1.2,
        ),
      ),
    );
  }
}
