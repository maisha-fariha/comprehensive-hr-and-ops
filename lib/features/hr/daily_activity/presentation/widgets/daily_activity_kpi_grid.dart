import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/daily_activity.dart';

/// The four web KPI tiles, fed by the registry's `meta.summary`.
class DailyActivityKpiGrid extends StatelessWidget {
  final DailyActivityStats stats;

  const DailyActivityKpiGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), SizedBox(width: gap), Expanded(child: b)],
          ),
        );

    return Column(
      children: [
        row(
          _Tile(
            key: const ValueKey('daily-activity-kpi-today'),
            icon: Icons.monitor_heart_outlined,
            tone: AppColors.secondaryTeal,
            toneBackground: AppColors.quickActionCreateShiftBg,
            value: stats.todaysActivities,
            label: "TODAY'S ACTIVITIES",
            caption: 'Activities recorded today',
          ),
          _Tile(
            key: const ValueKey('daily-activity-kpi-clients'),
            icon: Icons.people_outline_rounded,
            tone: AppColors.activeGreen,
            toneBackground: AppColors.activeBackground,
            value: stats.activeClients,
            label: 'ACTIVE CLIENTS',
            caption: 'Clients with activity updates',
          ),
        ),
        SizedBox(height: gap),
        row(
          _Tile(
            key: const ValueKey('daily-activity-kpi-staff'),
            icon: Icons.how_to_reg_outlined,
            tone: AppColors.textSecondary,
            toneBackground: AppColors.filterButtonBackground,
            value: stats.staffEntries,
            label: 'STAFF ENTRIES',
            caption: 'Staff submitted updates',
          ),
          _Tile(
            key: const ValueKey('daily-activity-kpi-pending'),
            icon: Icons.assignment_turned_in_outlined,
            tone: AppColors.urgentAmber,
            toneBackground: AppColors.urgentBackground,
            value: stats.pendingReview,
            label: 'PENDING REVIEW',
            caption: 'Activities requiring attention',
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color toneBackground;
  final int value;
  final String label;
  final String caption;

  const _Tile({
    super.key,
    required this.icon,
    required this.tone,
    required this.toneBackground,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle text(double size, FontWeight weight, Color color) => TextStyle(
          fontFamily: 'Outfit',
          fontWeight: weight,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size),
          color: color,
        );
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
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
              size: ResponsiveHelper.getResponsiveSize(context, 17),
              color: tone,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text('$value', style: text(24, FontWeight.w700, AppColors.textHeading)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            label,
            style: text(11, FontWeight.w600, AppColors.textSecondary)
                .copyWith(letterSpacing: 0.4),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
          Text(caption, style: text(12, FontWeight.w400, AppColors.textMuted)),
        ],
      ),
    );
  }
}
