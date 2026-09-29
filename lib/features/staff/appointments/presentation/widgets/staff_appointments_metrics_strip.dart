import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_appointment.dart';

class StaffAppointmentsMetricsStrip extends StatelessWidget {
  final StaffAppointmentsSummary summary;
  final ValueChanged<StaffAppointmentTab>? onMetricTap;

  const StaffAppointmentsMetricsStrip({
    super.key,
    required this.summary,
    this.onMetricTap,
  });

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
                label: 'Pending Requests',
                value: '${summary.pending}',
                subtitle: 'Awaiting review',
                icon: Icons.hourglass_top_rounded,
                iconColor: AppColors.urgentAmber,
                iconBg: AppColors.urgentBackgroundSoft,
                onTap: onMetricTap == null
                    ? null
                    : () => onMetricTap!(StaffAppointmentTab.pending),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Approved Today',
                value: '${summary.approvedToday}',
                subtitle: 'Decisions today',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.activeGreen,
                iconBg: AppColors.activeBackground,
                onTap: onMetricTap == null
                    ? null
                    : () => onMetricTap!(StaffAppointmentTab.approved),
              ),
            ),
          ],
        ),
        SizedBox(height: vGap),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'External Appointments',
                value: '${summary.upcomingExternal}',
                subtitle: 'Upcoming external',
                icon: Icons.local_hospital_outlined,
                iconColor: AppColors.infoBlue,
                iconBg: AppColors.infoBackground,
                onTap: onMetricTap == null
                    ? null
                    : () => onMetricTap!(StaffAppointmentTab.external),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Upcoming Family Visits',
                value: '${summary.upcomingVisits}',
                subtitle: 'Scheduled visits',
                icon: Icons.family_restroom_rounded,
                iconColor: AppColors.secondaryTeal,
                iconBg: AppColors.quickActionCreateShiftBg,
                onTap: onMetricTap == null
                    ? null
                    : () => onMetricTap!(StaffAppointmentTab.familyVisits),
              ),
            ),
          ],
        ),
        SizedBox(height: vGap),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Cancelled / Rejected',
                value: '${summary.cancelledOrRejected}',
                subtitle: 'Closed without visit',
                icon: Icons.cancel_outlined,
                iconColor: AppColors.criticalRed,
                iconBg: AppColors.criticalBackgroundSoft,
                onTap: onMetricTap == null
                    ? null
                    : () => onMetricTap!(StaffAppointmentTab.rejected),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Completed',
                value: '${summary.completed}',
                subtitle: 'Finished visits',
                icon: Icons.task_alt_rounded,
                iconColor: AppColors.primaryNavy,
                iconBg: AppColors.quickActionMessageBg,
                onTap: onMetricTap == null
                    ? null
                    : () => onMetricTap!(StaffAppointmentTab.all),
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
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                          12,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
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
        ),
      ),
    );
  }
}
