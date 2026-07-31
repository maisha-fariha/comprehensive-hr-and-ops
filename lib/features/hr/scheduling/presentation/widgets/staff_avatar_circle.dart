import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_avatar.dart';

/// A single overlapping facepile avatar (white circle, thin border,
/// initials) as seen on Calendar/Board shift cards.
class StaffAvatarCircle extends StatelessWidget {
  final StaffAvatar avatar;
  final double size;
  final double overlap;
  final bool isFirst;

  const StaffAvatarCircle({
    super.key,
    required this.avatar,
    required this.size,
    this.overlap = 10,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    return Padding(
      padding: EdgeInsets.only(
        left: isFirst ? 0 : ResponsiveHelper.getResponsiveWidth(context, size - overlap),
      ),
      child: Container(
        width: resolvedSize,
        height: resolvedSize,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          avatar.initials,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.32),
            color: AppColors.textBody,
          ),
        ),
      ),
    );
  }
}

/// A single "+N" overflow circle rendered at the end of a facepile, styled
/// the same as [StaffAvatarCircle].
class StaffAvatarOverflowCircle extends StatelessWidget {
  final int count;
  final double size;
  final double overlap;

  const StaffAvatarOverflowCircle({
    super.key,
    required this.count,
    required this.size,
    this.overlap = 10,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    return Padding(
      padding: EdgeInsets.only(left: ResponsiveHelper.getResponsiveWidth(context, size - overlap)),
      child: Container(
        width: resolvedSize,
        height: resolvedSize,
        decoration: BoxDecoration(
          color: AppColors.dividerLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '+$count',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.3),
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
