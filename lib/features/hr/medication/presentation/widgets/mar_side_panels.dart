import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../mar_row.dart';
import '../medication_labels.dart';
import 'medication_common.dart';

/// Web "Due Now": the next six due / upcoming doses with a Record button.
class MarDueNowPanel extends StatelessWidget {
  final List<MarRow> items;
  final bool loading;

  /// Null hides the Record buttons (no `mar:write`).
  final ValueChanged<MarRow>? onRecord;
  final String? disabledReason;

  const MarDueNowPanel({
    super.key,
    required this.items,
    required this.loading,
    this.onRecord,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final shown = items.take(6).toList();
    return HandoverPanel(
      key: const ValueKey('mar-due-now'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: AppColors.primaryNavy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Due Now',
                  style: handoverText(context, 15, weight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
              ),
              if (!loading) MarPill(label: '${items.length} pending', tone: MarTone.warning),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const MarEmpty('Loading…')
          else if (items.isEmpty)
            const MarEmpty('Nothing left to give today.')
          else ...[
            for (final r in shown)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MarDot(r.dotColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.medication,
                                  overflow: TextOverflow.ellipsis,
                                  style: handoverText(context, 13, weight: FontWeight.w600, color: AppColors.primaryNavy),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.residentName} · ${r.residence} · ${r.scheduleTime}',
                            overflow: TextOverflow.ellipsis,
                            style: handoverText(context, 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (onRecord != null)
                      Tooltip(
                        message: disabledReason ?? '',
                        child: HandoverButton(
                          key: ValueKey('mar-due-record-${r.id}'),
                          label: 'Record',
                          icon: Icons.vaccines_outlined,
                          compact: true,
                          onPressed: disabledReason == null ? () => onRecord!(r) : null,
                        ),
                      ),
                  ],
                ),
              ),
            if (items.length > shown.length)
              Text(
                'and ${items.length - shown.length} more later today',
                style: handoverText(context, 12, color: AppColors.textMuted),
              ),
          ],
        ],
      ),
    );
  }
}

/// Web "Missed / Overdue": the first six alerts and "Review All".
class MarAlertsPanel extends StatelessWidget {
  final List<MarRow> items;
  final bool loading;
  final ValueChanged<MarRow> onSelect;
  final VoidCallback onReviewAll;

  const MarAlertsPanel({
    super.key,
    required this.items,
    required this.loading,
    required this.onSelect,
    required this.onReviewAll,
  });

  static const Map<String, String> _labels = {
    'overdue': 'Overdue',
    'missed': 'Missed',
    'refused': 'Refused',
  };

  @override
  Widget build(BuildContext context) {
    final shown = items.take(6).toList();
    return HandoverPanel(
      key: const ValueKey('mar-alerts'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.criticalRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Missed / Overdue',
                  style: handoverText(context, 15, weight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
              ),
              MarPill(label: '${items.length} alerts', tone: MarTone.danger),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                key: ValueKey('mar-alert-${r.id}'),
                borderRadius: BorderRadius.circular(11),
                onTap: () => onSelect(r),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBackgroundSoft.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.residentName,
                              overflow: TextOverflow.ellipsis,
                              style: handoverText(context, 13, weight: FontWeight.w600, color: AppColors.primaryNavy),
                            ),
                          ),
                          MarPill(
                            label: _labels[r.state] ?? '',
                            tone: r.state == 'refused' ? MarTone.warning : MarTone.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${r.medication} · ${r.dosage} · due ${r.scheduleTime}',
                        style: handoverText(context, 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (items.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'and ${items.length - shown.length} more in the registry',
                style: handoverText(context, 12, color: AppColors.textMuted),
              ),
            ),
          if (items.isEmpty) MarEmpty(loading ? 'Loading…' : 'No missed or overdue medications.'),
          SizedBox(
            width: double.infinity,
            child: HandoverButton(
              key: const ValueKey('mar-review-all'),
              label: 'Review All',
              onPressed: onReviewAll,
            ),
          ),
        ],
      ),
    );
  }
}
