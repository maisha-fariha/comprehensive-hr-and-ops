import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/hr_appointment.dart';
import '../hr_appointments_labels.dart';

/// The six web KPI tiles, all read from `GET /appointments/summary`.
class HrAppointmentsKpiGrid extends StatelessWidget {
  final HrAppointmentSummary summary;

  const HrAppointmentsKpiGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final tiles = [
      _Tile(
        key: const ValueKey('appointments-kpi-pending'),
        icon: Icons.pending_actions_rounded,
        tone: HrAppointmentTone.warning,
        value: s.pending,
        label: 'PENDING REQUESTS',
        caption: 'Needs review',
        captionTone: true,
      ),
      _Tile(
        key: const ValueKey('appointments-kpi-approved-today'),
        icon: Icons.check_circle_outline_rounded,
        tone: HrAppointmentTone.success,
        value: s.approvedToday,
        label: 'APPROVED TODAY',
        caption: 'Decided today',
      ),
      _Tile(
        key: const ValueKey('appointments-kpi-external'),
        icon: Icons.directions_car_outlined,
        tone: HrAppointmentTone.secondary,
        value: s.upcomingExternal,
        label: 'EXTERNAL APPOINTMENTS',
        caption: 'Still to come',
      ),
      _Tile(
        key: const ValueKey('appointments-kpi-family'),
        icon: Icons.event_available_rounded,
        tone: HrAppointmentTone.purple,
        value: s.upcomingVisits,
        label: 'UPCOMING FAMILY VISITS',
        caption: 'Approved, still to come',
      ),
      _Tile(
        key: const ValueKey('appointments-kpi-closed'),
        icon: Icons.block_rounded,
        tone: HrAppointmentTone.danger,
        value: s.cancelledOrRejected,
        label: 'CANCELLED / REJECTED',
        caption: 'On the register',
      ),
      _Tile(
        key: const ValueKey('appointments-kpi-completed'),
        icon: Icons.event_available_rounded,
        tone: HrAppointmentTone.success,
        value: s.completed,
        label: 'COMPLETED',
        caption: 'Visits that happened',
      ),
    ];
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                SizedBox(width: gap),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final HrAppointmentTone tone;
  final int value;
  final String label;
  final String caption;
  final bool captionTone;

  const _Tile({
    super.key,
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
    required this.caption,
    this.captionTone = false,
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
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 14)),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 34),
            height: ResponsiveHelper.getResponsiveSize(context, 34),
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 11)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 17), color: tone.foreground),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text('$value', style: text(24, FontWeight.w700, AppColors.textHeading)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            label,
            style: text(11, FontWeight.w600, AppColors.textSecondary).copyWith(letterSpacing: 0.4),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
          Text(
            caption,
            style: captionTone
                ? text(12, FontWeight.w600, tone.foreground)
                : text(12, FontWeight.w400, AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
