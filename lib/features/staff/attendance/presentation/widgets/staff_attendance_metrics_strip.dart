import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_attendance_metrics.dart';

/// Web-parity metric cards: Present / Late / Missed / Pending Approval.
class StaffAttendanceMetricsStrip extends StatelessWidget {
  final StaffAttendanceMetrics metrics;

  const StaffAttendanceMetricsStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'PRESENT',
                value: '${metrics.present}',
                subtitle: 'Clocked in on time.',
                color: AppColors.activeGreen,
                background: AppColors.activeBackground,
                icon: Icons.person_outline_rounded,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: _MetricCard(
                label: 'LATE',
                value: '${metrics.late}',
                subtitle: 'Clocked in after the shift started.',
                color: AppColors.urgentAmber,
                background: AppColors.urgentBackgroundSoft,
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'MISSED',
                value: '${metrics.missed}',
                subtitle: 'Rostered, nobody attended.',
                color: AppColors.criticalRed,
                background: AppColors.criticalBackgroundSoft,
                icon: Icons.warning_amber_rounded,
                emphasizeSubtitle: metrics.missed > 0,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: _MetricCard(
                label: 'PENDING APPROVAL',
                value: '${metrics.pendingApproval}',
                subtitle: 'Manual claims awaiting review.',
                color: AppColors.secondaryTeal,
                background: AppColors.quickActionCreateShiftBg,
                icon: Icons.hourglass_top_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color background;
  final IconData icon;
  final bool emphasizeSubtitle;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.icon,
    this.emphasizeSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 28),
                height: ResponsiveHelper.getResponsiveSize(context, 28),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                  color: AppColors.textHeading,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: emphasizeSubtitle ? color : AppColors.textMuted,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
