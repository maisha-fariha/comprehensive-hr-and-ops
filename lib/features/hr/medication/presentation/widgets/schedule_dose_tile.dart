import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/schedule_dose.dart';

class _DoseStatusStyle {
  final Color background;
  final Color foreground;
  final String label;

  const _DoseStatusStyle({
    required this.background,
    required this.foreground,
    required this.label,
  });
}

const Map<DoseStatus, _DoseStatusStyle> _doseStatusStyles = {
  DoseStatus.dueSoon: _DoseStatusStyle(
    background: Color(0xFFFEE2E2),
    foreground: Color(0xFFB91C1C),
    label: 'Due Soon',
  ),
  DoseStatus.upcoming: _DoseStatusStyle(
    background: Color(0xFFDBEAFE),
    foreground: Color(0xFF1E40AF),
    label: 'Upcoming',
  ),
  DoseStatus.completed: _DoseStatusStyle(
    background: Color(0xFFEAF6F0),
    foreground: Color(0xFF2E8C58),
    label: 'Completed',
  ),
  DoseStatus.due: _DoseStatusStyle(
    background: Color(0xFFDBEAFE),
    foreground: Color(0xFF1E40AF),
    label: 'Due',
  ),
};

/// Medication schedule card for the Due tab (Priority + Later Today lists).
class ScheduleDoseTile extends StatelessWidget {
  final ScheduleDose dose;
  final bool isPriority;
  final VoidCallback? onTap;

  static const Color _priorityBorder = Color(0xFFF3DADA);

  const ScheduleDoseTile({
    super.key,
    required this.dose,
    this.isPriority = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _doseStatusStyles[dose.status]!;
    final isCompleted = dose.status == DoseStatus.completed;
    final assigneeCaption = isCompleted ? 'GIVEN BY' : 'ASSIGNED';
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isPriority ? _priorityBorder : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RoundedInitialsAvatar(
                  initials: dose.residentInitials,
                  palette: dose.avatarColor,
                  size: 40,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dose.residentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: AppColors.textHeading,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      Text(
                        '${dose.medicationName} ${dose.dose}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: AppColors.textMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                      color: style.foreground,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MiniInfoColumn(
                      caption: 'SCHEDULED',
                      child: Row(
                        children: [
                          const AppSvgIcon(
                            'assets/icons/medication/medication_clock.svg',
                            size: 13,
                            color: AppColors.textHeading,
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                          Flexible(
                            child: Text(
                              dose.scheduledTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveWidth(context, 10),
                    ),
                    child: const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.dividerLight,
                    ),
                  ),
                  Expanded(
                    child: _MiniInfoColumn(
                      caption: assigneeCaption,
                      child: Row(
                        children: [
                          _RoundedInitialsAvatar(
                            initials: dose.assigneeInitials,
                            palette: dose.assigneeAvatarColor,
                            size: 20,
                            radius: 6,
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                          Flexible(
                            child: Text(
                              dose.assigneeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoColumn extends StatelessWidget {
  final String caption;
  final Widget child;

  const _MiniInfoColumn({required this.caption, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
            color: AppColors.textFaint,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
        child,
      ],
    );
  }
}

class _RoundedInitialsAvatar extends StatelessWidget {
  final String initials;
  final AvatarPalette palette;
  final double size;
  final double radius;

  const _RoundedInitialsAvatar({
    required this.initials,
    required this.palette,
    required this.size,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (palette) {
      AvatarPalette.blue => (AppColors.infoBackground, AppColors.infoBlue),
      AvatarPalette.green => (AppColors.activeBackground, AppColors.activeGreen),
      AvatarPalette.purple => (AppColors.nightBackground, AppColors.nightPurple),
    };
    final resolved = ResponsiveHelper.getResponsiveSize(context, size);

    return Container(
      width: resolved,
      height: resolved,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, radius),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.32),
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}
