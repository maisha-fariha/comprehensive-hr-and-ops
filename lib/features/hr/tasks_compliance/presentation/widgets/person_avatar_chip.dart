import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/assignee.dart';

class _AvatarColorStyle {
  final Color background;
  final Color foreground;

  const _AvatarColorStyle({required this.background, required this.foreground});
}

const Map<AssigneeColorTag, _AvatarColorStyle> _avatarColorStyles = {
  AssigneeColorTag.blue: _AvatarColorStyle(
    background: AppColors.infoBackground,
    foreground: AppColors.infoBlue,
  ),
  AssigneeColorTag.purple: _AvatarColorStyle(
    background: AppColors.nightBackground,
    foreground: AppColors.nightPurple,
  ),
  AssigneeColorTag.green: _AvatarColorStyle(
    background: AppColors.activeBackground,
    foreground: AppColors.activeGreen,
  ),
};

/// Small circular initials chip used to represent an [Assignee] inline in a
/// list-tile subtitle or an "ASSIGNED" row (e.g. "SJ" for "Sarah J.").
class PersonAvatarChip extends StatelessWidget {
  final Assignee assignee;

  const PersonAvatarChip({super.key, required this.assignee});

  @override
  Widget build(BuildContext context) {
    final style = _avatarColorStyles[assignee.colorTag]!;
    final size = ResponsiveHelper.getResponsiveSize(context, 19);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: style.background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        assignee.initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9),
          color: style.foreground,
          height: 1,
        ),
      ),
    );
  }
}
