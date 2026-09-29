import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/emergency_alert.dart';

/// The four web KPI tiles on "Emergency Alarms".
class EmergencyKpiGrid extends StatelessWidget {
  final EmergencyStats stats;

  const EmergencyKpiGrid({super.key, required this.stats});

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
            key: const ValueKey('emergency-kpi-active'),
            icon: Icons.crisis_alert_rounded,
            tone: AppColors.criticalRed,
            toneBackground: AppColors.criticalBackgroundSoft,
            value: stats.active,
            label: 'UNANSWERED',
            caption: 'Nobody has acknowledged these',
          ),
          _Tile(
            key: const ValueKey('emergency-kpi-awaiting'),
            icon: Icons.schedule_rounded,
            tone: AppColors.urgentAmber,
            toneBackground: AppColors.urgentBackground,
            value: stats.awaitingResponse,
            label: 'AWAITING RESPONSE',
            caption: 'Seen, but nobody is on the way yet',
          ),
        ),
        SizedBox(height: gap),
        row(
          _Tile(
            key: const ValueKey('emergency-kpi-in-progress'),
            icon: Icons.warning_amber_rounded,
            tone: AppColors.infoBlue,
            toneBackground: AppColors.infoBackground,
            value: stats.inProgress,
            label: 'BEING HANDLED',
            caption: 'Somebody is dealing with it now',
          ),
          _Tile(
            key: const ValueKey('emergency-kpi-resolved'),
            icon: Icons.check_circle_outline_rounded,
            tone: AppColors.secondaryTeal,
            toneBackground: AppColors.quickActionCreateShiftBg,
            value: stats.resolvedToday,
            label: 'RESOLVED TODAY',
            caption: 'Closed since midnight',
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
