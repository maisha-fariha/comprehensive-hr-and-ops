import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../attendance_constants.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/overtime_entry.dart';
import 'attendance_avatar.dart';

class _OvertimeStyle {
  final Color color;
  final Color background;
  final String label;

  const _OvertimeStyle({required this.color, required this.background, required this.label});
}

const Map<OvertimeStatus, _OvertimeStyle> _overtimeStyles = {
  OvertimeStatus.exceeded: _OvertimeStyle(
    color: AppColors.criticalRed,
    background: AppColors.criticalBackground,
    label: 'Overtime Exceeded',
  ),
  OvertimeStatus.approaching: _OvertimeStyle(
    color: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
    label: 'Approaching Limit',
  ),
};

/// A single card in the "OT" tab's "Overtime Tracking" list.
class OvertimeCard extends StatelessWidget {
  final OvertimeEntry entry;
  final VoidCallback? onTap;

  const OvertimeCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _overtimeStyles[entry.status]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AttendanceAvatar(initials: initialsFromName(entry.name), paletteIndex: entry.avatarPaletteIndex),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        entry.roleShiftLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge.pill(label: style.label, background: style.background, foreground: style.color),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 13)),
            Row(
              children: [
                Expanded(
                  child: _LabeledValue(label: 'OT TODAY', value: entry.otTodayLabel),
                ),
                Expanded(
                  child: _LabeledValue(label: 'WEEKLY TOTAL', value: entry.weeklyTotalLabel, emphasize: true),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 11)),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, AttendanceDimens.progressBarHeight),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(color: AppColors.dividerLight),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: entry.progress.clamp(0.0, 1.0),
                            child: Container(color: style.color),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 7)),
            Text(
              entry.limitCaption,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _LabeledValue({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
