import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/iso_date_range.dart';
import '../../handovers/presentation/widgets/handover_common.dart';
import '../domain/entities/ai_report.dart';

class AiSeverityStyle {
  final String label;
  final Color foreground;
  final Color background;
  final Color bar;

  const AiSeverityStyle({
    required this.label,
    required this.foreground,
    required this.background,
    required this.bar,
  });
}

AiSeverityStyle aiSeverityStyle(AiReportSeverity severity) {
  return switch (severity) {
    AiReportSeverity.attention => const AiSeverityStyle(
        label: 'Needs a look',
        foreground: AppColors.urgentAmber,
        background: AppColors.urgentBackgroundSoft,
        bar: AppColors.urgentAmber,
      ),
    AiReportSeverity.urgent => const AiSeverityStyle(
        label: 'Safety flag',
        foreground: AppColors.criticalRed,
        background: AppColors.criticalBackgroundSoft,
        bar: AppColors.criticalRed,
      ),
    // Web automations / report chips: info → "For information" (blue).
    AiReportSeverity.info => const AiSeverityStyle(
        label: 'For information',
        foreground: AppColors.infoBlue,
        background: AppColors.infoBackground,
        bar: AppColors.infoBlue,
      ),
  };
}

/// Web Automations "Last check" cell copy.
String aiAutomationLastCheckLabel(AiReportAutomation automation) {
  final outcome = (automation.lastOutcome ?? '').toLowerCase();
  final count = automation.lastReports;
  if (outcome == 'reports' || count > 0) {
    final n = count > 0 ? count : 1;
    return n == 1 ? '1 report written' : '$n reports written';
  }
  if (outcome == 'nothing' || outcome == 'empty' || outcome == 'ok') {
    return 'Checked, nothing found';
  }
  if ((automation.lastError ?? '').trim().isNotEmpty) {
    return 'Error';
  }
  final when = aiReportTimeLabel(automation.lastCheckedAt);
  return when.isEmpty ? '—' : when;
}

String aiAutomationLast30Label(AiReportAutomation automation) {
  final n = automation.reportsLast30Days;
  if (n <= 0) return 'None';
  return n == 1 ? '1 report' : '$n reports';
}

Widget aiSeverityChip(BuildContext context, AiReportSeverity severity) {
  final style = aiSeverityStyle(severity);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: style.background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: style.foreground.withValues(alpha: 0.25)),
    ),
    child: Text(
      style.label,
      style: handoverText(
        context,
        11.5,
        weight: FontWeight.w600,
        color: style.foreground,
      ),
    ),
  );
}

Widget aiMetaChip(BuildContext context, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.searchBorder),
    ),
    child: Text(
      label,
      style: handoverText(context, 11.5, weight: FontWeight.w500, color: AppColors.textBody),
    ),
  );
}

String aiReportTimeLabel(DateTime? instant) {
  if (instant == null) return '';
  return IsoDateRange.dateTimeLabel(instant);
}
