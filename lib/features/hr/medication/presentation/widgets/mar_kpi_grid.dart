import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/mar_round.dart';
import '../medication_labels.dart';

/// The four web KPI cards, all read from `GET /mar/round` → `summary`.
class MarKpiGrid extends StatelessWidget {
  final MarSummary summary;

  const MarKpiGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final tiles = [
      _Tile(
        key: const ValueKey('mar-kpi-scheduled'),
        icon: Icons.event_note_rounded,
        tone: MarTone.info,
        value: '${s.scheduled}',
        label: 'SCHEDULED TODAY',
        caption: 'across all residences',
      ),
      _Tile(
        key: const ValueKey('mar-kpi-administered'),
        icon: Icons.check_circle_outline_rounded,
        tone: MarTone.success,
        value: '${s.administered}',
        label: 'ADMINISTERED',
        caption: s.unscheduled > 0 ? '${s.unscheduled} outside a round' : 'all on the round',
        captionTone: true,
      ),
      _Tile(
        key: const ValueKey('mar-kpi-missed'),
        icon: Icons.warning_amber_rounded,
        tone: MarTone.danger,
        value: '${s.missed}',
        label: 'MISSED / OVERDUE',
        caption: 'requires follow-up',
        captionTone: true,
      ),
      _Tile(
        key: const ValueKey('mar-kpi-compliance'),
        icon: Icons.percent_rounded,
        tone: MarTone.purple,
        value: s.complianceRate == null ? '—' : '${s.complianceRate}%',
        label: 'COMPLIANCE RATE',
        caption: "of today's scheduled doses",
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
  final MarTone tone;
  final String value;
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
          Text(value, style: text(24, FontWeight.w700, AppColors.textHeading)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(label, style: text(11, FontWeight.w600, AppColors.textSecondary).copyWith(letterSpacing: 0.4)),
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
