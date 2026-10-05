import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_training.dart';

class StaffTrainingMetricsStrip extends StatelessWidget {
  final StaffTrainingSummary summary;

  const StaffTrainingMetricsStrip({super.key, required this.summary});

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
                label: 'Assignments',
                value: '${summary.assignments}',
                subtitle: '${summary.outstanding} outstanding',
                icon: Icons.assignment_outlined,
                iconColor: AppColors.secondaryTeal,
                iconBg: AppColors.quickActionCreateShiftBg,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Completed',
                value: '${summary.completed}',
                subtitle: 'Finished courses',
                icon: Icons.check_circle_outline_rounded,
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
                label: 'Overdue',
                value: '${summary.overdue}',
                subtitle: 'Past due date',
                icon: Icons.schedule_rounded,
                iconColor: AppColors.urgentAmber,
                iconBg: AppColors.urgentBackgroundSoft,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Mandatory Outstanding',
                value: '${summary.mandatoryOutstanding}',
                subtitle: 'Required incomplete',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.criticalRed,
                iconBg: AppColors.criticalBackgroundSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StaffTrainingCourseMetricsStrip extends StatelessWidget {
  final StaffTrainingCourseMetrics metrics;

  const StaffTrainingCourseMetricsStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 8);
    final vGap = ResponsiveHelper.getResponsiveHeight(context, 8);
    final cards = [
      _MetricCard(
        label: 'Assigned',
        value: '${metrics.assigned}',
        subtitle: 'Staff enrolled',
        icon: Icons.people_outline_rounded,
        iconColor: AppColors.secondaryTeal,
        iconBg: AppColors.quickActionCreateShiftBg,
        compact: true,
      ),
      _MetricCard(
        label: 'Completed',
        value: '${metrics.completed}',
        subtitle: 'Finished',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.activeGreen,
        iconBg: AppColors.activeBackground,
        compact: true,
      ),
      _MetricCard(
        label: 'In Progress',
        value: '${metrics.inProgress}',
        subtitle: 'Underway',
        icon: Icons.timelapse_rounded,
        iconColor: AppColors.urgentAmber,
        iconBg: AppColors.urgentBackgroundSoft,
        compact: true,
      ),
      _MetricCard(
        label: 'Overdue',
        value: '${metrics.overdue}',
        subtitle: 'Past due',
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.criticalRed,
        iconBg: AppColors.criticalBackgroundSoft,
        compact: true,
      ),
      _MetricCard(
        label: 'Certificates Issued',
        value: '${metrics.certificatesIssued}',
        subtitle: 'For this course',
        icon: Icons.workspace_premium_outlined,
        iconColor: AppColors.primaryNavy,
        iconBg: const Color(0xFFE8EEF5),
        compact: true,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            SizedBox(width: gap),
            Expanded(child: cards[1]),
          ],
        ),
        SizedBox(height: vGap),
        Row(
          children: [
            Expanded(child: cards[2]),
            SizedBox(width: gap),
            Expanded(child: cards[3]),
          ],
        ),
        SizedBox(height: vGap),
        cards[4],
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
  final bool compact;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      compact ? 11 : 12,
                    ),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                width: compact ? 28 : 32,
                height: compact ? 28 : 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: compact ? 16 : 18, color: iconColor),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                compact ? 20 : 24,
              ),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
