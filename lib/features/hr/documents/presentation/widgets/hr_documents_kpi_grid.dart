import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/hr_document.dart';
import 'hr_documents_common.dart';

/// The four web KPI tiles on "Documents".
class HrDocumentsKpiGrid extends StatelessWidget {
  final HrDocumentsSummary summary;

  const HrDocumentsKpiGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), SizedBox(width: gap), Expanded(child: b)],
          ),
        );
    final added = s.addedLast30Days;
    return Column(
      children: [
        row(
          _Tile(
            key: const ValueKey('documents-kpi-total'),
            icon: Icons.file_copy_outlined,
            tone: AppColors.secondaryTeal,
            toneBackground: AppColors.quickActionCreateShiftBg,
            value: hrCount(s.documents),
            label: 'TOTAL DOCUMENTS',
            caption: added > 0 ? '+$added in the last 30 days' : 'None filed in 30 days',
            captionColor: added > 0 ? AppColors.activeGreen : AppColors.textMuted,
          ),
          _Tile(
            key: const ValueKey('documents-kpi-missing'),
            icon: Icons.warning_amber_rounded,
            tone: AppColors.criticalRed,
            toneBackground: AppColors.criticalBackgroundSoft,
            value: '${s.missingMandatory}',
            label: 'MISSING REQUIRED DOCUMENTS',
            caption: s.missingMandatory > 0 ? 'Review required' : 'All mandatory types filed',
            captionColor:
                s.missingMandatory > 0 ? AppColors.criticalRed : AppColors.activeGreen,
          ),
        ),
        SizedBox(height: gap),
        row(
          _Tile(
            key: const ValueKey('documents-kpi-expiring'),
            icon: Icons.schedule_rounded,
            tone: AppColors.urgentAmber,
            toneBackground: AppColors.urgentBackground,
            value: '${s.expiringSoon}',
            label: 'EXPIRING SOON',
            caption: 'Within 30 days',
            captionColor: AppColors.textMuted,
            captionWeight: FontWeight.w400,
          ),
          _Tile(
            key: const ValueKey('documents-kpi-restricted'),
            icon: Icons.lock_outline_rounded,
            tone: AppColors.activeGreen,
            toneBackground: AppColors.activeBackground,
            value: '${s.restricted}',
            label: 'RESTRICTED FILES',
            caption: 'Access banded',
            captionColor: AppColors.activeGreen,
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
  final String value;
  final String label;
  final String caption;
  final Color captionColor;
  final FontWeight captionWeight;

  const _Tile({
    super.key,
    required this.icon,
    required this.tone,
    required this.toneBackground,
    required this.value,
    required this.label,
    required this.caption,
    required this.captionColor,
    this.captionWeight = FontWeight.w600,
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
              color: toneBackground,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 17), color: tone),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(value, style: text(24, FontWeight.w700, AppColors.textHeading)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            label,
            style: text(11, FontWeight.w600, AppColors.textSecondary).copyWith(letterSpacing: 0.4),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
          Text(caption, style: text(12, captionWeight, captionColor)),
        ],
      ),
    );
  }
}
