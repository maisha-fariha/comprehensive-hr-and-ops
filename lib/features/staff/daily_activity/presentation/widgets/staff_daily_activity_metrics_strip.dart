import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_activity_metrics.dart';

/// Web-parity metric cards for Daily Activity.
class StaffDailyActivityMetricsStrip extends StatelessWidget {
  final StaffDailyActivityMetrics metrics;

  const StaffDailyActivityMetricsStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final vGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: "Today's Activities",
                value: '${metrics.todaysActivities}',
                subtitle: 'Activities recorded today',
                icon: Icons.monitor_heart_outlined,
                iconColor: AppColors.secondaryTeal,
                iconBg: AppColors.quickActionCreateShiftBg,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Active Clients',
                value: '${metrics.activeClients}',
                subtitle: 'Clients with activity updates',
                icon: Icons.groups_outlined,
                iconColor: AppColors.activeGreen,
                iconBg: AppColors.activeBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: vGap),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Staff Entries',
                value: '${metrics.staffEntries}',
                subtitle: 'Staff submitted updates',
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.infoBlue,
                iconBg: AppColors.infoBackground,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Pending Review',
                value: '${metrics.pendingReview}',
                subtitle: 'Activities requiring attention',
                icon: Icons.assignment_outlined,
                iconColor: AppColors.urgentAmber,
                iconBg: AppColors.urgentBackgroundSoft,
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
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
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
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textMuted,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
