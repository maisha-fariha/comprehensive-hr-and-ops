import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_incidents_summary.dart';

/// Horizontal scroll of summary metric cards (web Incident Reports KPIs).
class StaffIncidentsMetricsRow extends StatelessWidget {
  final StaffIncidentsSummary summary;

  const StaffIncidentsMetricsRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final metrics = [
      _MetricSpec(
        label: 'Total Incidents',
        value: summary.total,
        accent: AppColors.secondaryTeal,
      ),
      _MetricSpec(
        label: 'Open',
        value: summary.open,
        accent: AppColors.infoBlue,
      ),
      _MetricSpec(
        label: 'Investigating',
        value: summary.investigating,
        accent: AppColors.urgentAmber,
      ),
      _MetricSpec(
        label: 'High or Critical',
        value: summary.serious,
        accent: AppColors.criticalRed,
      ),
      _MetricSpec(
        label: 'Closed',
        value: summary.closed,
        accent: AppColors.textSecondary,
      ),
    ];

    return Container(
      key: const Key('staff-incidents-metrics'),
      width: double.infinity,
      child: Wrap(
        spacing: gap,
        runSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
        children: [
          for (final metric in metrics) _MetricCard(spec: metric),
        ],
      ),
    );
  }
}

class _MetricSpec {
  final String label;
  final int value;
  final Color accent;

  const _MetricSpec({
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricSpec spec;

  const _MetricCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final width = ResponsiveHelper.getResponsiveWidth(context, 132);

    return Container(
      width: width,
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.getResponsiveHeight(context, 88),
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 8),
            height: ResponsiveHelper.getResponsiveSize(context, 8),
            decoration: BoxDecoration(
              color: spec.accent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            '${spec.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              color: AppColors.textHeading,
              letterSpacing: -0.4,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            spec.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textSecondary,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
