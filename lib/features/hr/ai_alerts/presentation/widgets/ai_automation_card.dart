import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/ai_report.dart';
import '../ai_alerts_styles.dart';

/// One row of the web Automations table, adapted for phone width.
class AiAutomationCard extends StatelessWidget {
  final AiReportAutomation automation;

  const AiAutomationCard({super.key, required this.automation});

  @override
  Widget build(BuildContext context) {
    final severity = automation.severity ?? AiReportSeverity.info;
    final lastCheck = aiAutomationLastCheckLabel(automation);
    final last30 = aiAutomationLast30Label(automation);
    final next = aiReportTimeLabel(automation.nextCheckAt);
    final when = (automation.schedule ?? '').trim();
    final relative = _relative(automation.lastCheckedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    automation.label,
                    style: handoverText(context, 15, weight: FontWeight.w700),
                  ),
                ),
                aiSeverityChip(context, severity),
              ],
            ),
            if ((automation.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                automation.description!.trim(),
                style: handoverText(context, 13, color: AppColors.textBody),
              ),
            ],
            if (when.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Labeled(
                label: 'When it runs',
                child: Text(
                  when,
                  style: handoverText(context, 12.5, color: AppColors.textBody),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _Labeled(
              label: 'Last check',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastCheck,
                    style: handoverText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: lastCheck == 'Error'
                          ? AppColors.criticalRed
                          : AppColors.activeGreen,
                    ),
                  ),
                  if (relative.isNotEmpty)
                    Text(
                      relative,
                      style: handoverText(context, 11.5, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            if (next.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Labeled(
                label: 'Next check',
                child: Text(
                  next,
                  style: handoverText(context, 12.5, color: AppColors.textBody),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _Labeled(
              label: 'Last 30 days',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: last30 == 'None'
                      ? AppColors.filterButtonBackground
                      : AppColors.activeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  last30,
                  style: handoverText(
                    context,
                    12,
                    weight: FontWeight.w600,
                    color: last30 == 'None'
                        ? AppColors.textMuted
                        : AppColors.activeGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relative(DateTime? at) {
    if (at == null) return '';
    final delta = DateTime.now().toUtc().difference(at.toUtc());
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inHours < 1) return '${delta.inMinutes} minutes ago';
    if (delta.inHours < 36) {
      return delta.inHours == 1
          ? 'about 1 hour ago'
          : 'about ${delta.inHours} hours ago';
    }
    if (delta.inDays < 14) {
      return delta.inDays == 1 ? '1 day ago' : '${delta.inDays} days ago';
    }
    return '';
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;

  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
