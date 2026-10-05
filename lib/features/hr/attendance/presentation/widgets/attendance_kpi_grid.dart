import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/attendance_record.dart';

/// The four web KPI cards; tapping one toggles that status filter.
class AttendanceKpiGrid extends StatelessWidget {
  final AttendanceSummary summary;
  final AttendanceStatusFilter? activeStatus;
  final ValueChanged<AttendanceStatusFilter> onSelect;

  const AttendanceKpiGrid({
    super.key,
    required this.summary,
    required this.activeStatus,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    Widget card(
      AttendanceStatusFilter status, {
      required IconData icon,
      required Color tone,
      required Color toneBackground,
      required int value,
      required String label,
      required String caption,
      Color? captionColor,
    }) =>
        Expanded(
          child: _KpiCard(
            key: ValueKey('attendance-kpi-${status.value}'),
            icon: icon,
            tone: tone,
            toneBackground: toneBackground,
            value: value,
            label: label,
            caption: caption,
            captionColor: captionColor,
            active: activeStatus == status,
            onTap: () => onSelect(status),
          ),
        );

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                AttendanceStatusFilter.present,
                icon: Icons.how_to_reg_outlined,
                tone: AppColors.activeGreen,
                toneBackground: AppColors.activeBackground,
                value: summary.present,
                label: 'PRESENT',
                caption: 'Clocked in on time',
              ),
              SizedBox(width: gap),
              card(
                AttendanceStatusFilter.late,
                icon: Icons.schedule_rounded,
                tone: AppColors.urgentAmber,
                toneBackground: AppColors.urgentBackground,
                value: summary.late,
                label: 'LATE',
                caption: summary.lateCaption,
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                AttendanceStatusFilter.missed,
                icon: Icons.warning_amber_rounded,
                tone: AppColors.criticalRed,
                toneBackground: AppColors.criticalBackgroundSoft,
                value: summary.missed,
                label: 'MISSED',
                caption: 'Rostered, nobody attended',
                captionColor: AppColors.criticalRed,
              ),
              SizedBox(width: gap),
              card(
                AttendanceStatusFilter.pendingApproval,
                icon: Icons.fact_check_outlined,
                tone: AppColors.secondaryTeal,
                toneBackground: AppColors.quickActionCreateShiftBg,
                value: summary.pendingApproval,
                label: 'PENDING APPROVAL',
                caption: 'Manual claims awaiting review',
                captionColor: AppColors.secondaryTeal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color toneBackground;
  final int value;
  final String label;
  final String caption;
  final Color? captionColor;
  final bool active;
  final VoidCallback onTap;

  const _KpiCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.toneBackground,
    required this.value,
    required this.label,
    required this.caption,
    this.captionColor,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      ResponsiveHelper.getResponsiveRadius(context, 14),
    );
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: active ? AppColors.secondaryTeal : AppColors.cardBorder,
                width: active ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveHelper.getResponsiveSize(context, 34),
                  height: ResponsiveHelper.getResponsiveSize(context, 34),
                  decoration: BoxDecoration(
                    color: toneBackground,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: ResponsiveHelper.getResponsiveSize(context, 18),
                    color: tone,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                Text(
                  '$value',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  caption,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight:
                        captionColor == null ? FontWeight.w400 : FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: captionColor ?? AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
