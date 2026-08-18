import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/shift_avatar.dart';

class _AvatarTone {
  final Color background;
  final Color foreground;

  const _AvatarTone(this.background, this.foreground);
}

/// Solid facepile colors to match the schedule reference (white initials).
const List<_AvatarTone> _avatarTones = [
  _AvatarTone(Color(0xFF2A5DA6), Colors.white),
  _AvatarTone(Color(0xFF2E8C58), Colors.white),
  _AvatarTone(Color(0xFF6A4BC7), Colors.white),
  _AvatarTone(Color(0xFF0E7C7B), Colors.white),
  _AvatarTone(Color(0xFFB4791C), Colors.white),
];

/// Overlapping facepile avatar used on a shift card.
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
    final tone = _avatarTones[paletteIndex % _avatarTones.length];
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    final pullIn = ResponsiveHelper.getResponsiveWidth(context, overlap);

    final circle = Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(
        color: tone.background,
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
          color: tone.foreground,
          height: 1,
        ),
      ),
    );

    if (isFirst) return circle;

    // Lay out narrower than the circle so neighbors overlap without negative
    // margins (Container forbids margin.isNonNegative == false).
    return SizedBox(
      width: (resolvedSize - pullIn).clamp(0.0, resolvedSize),
      height: resolvedSize,
      child: OverflowBox(
        minWidth: resolvedSize,
        maxWidth: resolvedSize,
        minHeight: resolvedSize,
        maxHeight: resolvedSize,
        alignment: Alignment.centerRight,
        child: circle,
      ),
    );
  }
}
