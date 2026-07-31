import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/shift_avatar.dart';

/// A single overlapping facepile avatar (tinted circle, initials) shown on
/// a shift card, mirroring the HR Scheduling feature's `StaffAvatarCircle`.
class ShiftAvatarCircle extends StatelessWidget {
  final ShiftAvatar avatar;
  final int paletteIndex;
  final double size;
  final double overlap;
  final bool isFirst;

  const ShiftAvatarCircle({
    super.key,
    required this.avatar,
    required this.paletteIndex,
    this.size = StaffDimens.shiftAvatarSize,
    this.overlap = StaffDimens.shiftAvatarOverlap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = staffAvatarPalette[paletteIndex % staffAvatarPalette.length];
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);

    return Padding(
      padding: EdgeInsets.only(
        left: isFirst ? 0 : ResponsiveHelper.getResponsiveWidth(context, size - overlap),
      ),
      child: Container(
        width: resolvedSize,
        height: resolvedSize,
        decoration: BoxDecoration(
          color: palette.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          avatar.initials,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.34),
            color: palette.foreground,
          ),
        ),
      ),
    );
  }
}
