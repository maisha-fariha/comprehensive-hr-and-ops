import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/mar_round.dart';
import '../medication_labels.dart';
import 'medication_common.dart';

/// Web "Resident chart": one person's day in four buckets, PRN availability
/// and doses given outside a round.
class MarResidentChartTab extends StatelessWidget {
  final String clientId;
  final List<MarChoice> clientOptions;
  final MarResidentChart? chart;
  final bool loading;
  final ValueChanged<String> onClientChange;

  const MarResidentChartTab({
    super.key,
    required this.clientId,
    required this.clientOptions,
    required this.chart,
    required this.loading,
    required this.onClientChange,
  });

  static const _buckets = [
    ('morning', 'Morning'),
    ('afternoon', 'Afternoon'),
    ('evening', 'Evening'),
    ('night', 'Night'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HandoverPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MarSelectField(
                key: const ValueKey('mar-chart-resident'),
                label: 'Resident',
                value: clientId,
                options: clientOptions,
                placeholder: 'Choose a resident',
                onChanged: onClientChange,
              ),
              if (clientId.isNotEmpty && c != null && c.allergies.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Allergies',
                      style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.criticalRed),
                    ),
                    for (final a in c.allergies) MarPill(label: a, tone: MarTone.danger),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (clientId.isEmpty)
          HandoverPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text('Choose a resident', style: handoverText(context, 15, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  "A chart is one person's day.",
                  style: handoverText(context, 13.5, color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else if (loading && c == null)
          const MarEmpty('Loading…')
        else if (c != null) ...[
          for (final (key, label) in _buckets) ...[
            _Bucket(title: label, doses: c.buckets[key] ?? const []),
            const SizedBox(height: 12),
          ],
          HandoverPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'As needed (PRN)',
                  style: handoverText(context, 13.5, weight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 6),
                if (c.prn.isEmpty)
                  Text(
                    'No as-needed medicines on this chart.',
                    style: handoverText(context, 12, color: AppColors.textMuted),
                  )
                else
                  for (final p in c.prn) _PrnLine(prn: p),
              ],
            ),
          ),
          if (c.unscheduled.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Bucket(title: 'Given outside a round', doses: c.unscheduled, showCount: false),
          ],
        ],
      ],
    );
  }
}

class _Bucket extends StatelessWidget {
  final String title;
  final List<MarOccurrence> doses;
  final bool showCount;

  const _Bucket({required this.title, required this.doses, this.showCount = true});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: handoverText(context, 13.5, weight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
              ),
              if (showCount) MarPill(label: '${doses.length}', tone: MarTone.neutral),
            ],
          ),
          const SizedBox(height: 6),
          if (doses.isEmpty)
            Text('Nothing due.', style: handoverText(context, 12, color: AppColors.textMuted))
          else
            for (final d in doses)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: handoverText(context, 13, weight: FontWeight.w600)),
                          Text(
                            [d.scheduledTime, d.dose ?? '']
                                    .where((e) => e.isNotEmpty)
                                    .join(' · ')
                                    .ifEmpty('—'),
                            style: handoverText(context, 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (d.isControlled) ...[
                      const MarPill(label: 'Controlled', tone: MarTone.purple),
                      const SizedBox(width: 6),
                    ],
                    MarPill(
                      label: MedicationLabels.humanise(d.state),
                      tone: MedicationLabels.chartStateTone(d.state),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _PrnLine extends StatelessWidget {
  final MarChartPrn prn;

  const _PrnLine({required this.prn});

  @override
  Widget build(BuildContext context) {
    final wait = prn.availableInMinutes;
    String? waitLabel;
    if (wait != null && wait > 0) {
      final h = wait ~/ 60;
      final m = wait % 60;
      waitLabel = h > 0 ? '${h}h ${m}m' : '${m}m';
    }
    final last = prn.lastAdministeredAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prn.name, style: handoverText(context, 13, weight: FontWeight.w600)),
                Text(
                  '${last != null ? 'Last given ${MedicationLabels.time(last)}' : 'Not given today'}'
                  '${prn.minIntervalMinutes != null && prn.minIntervalMinutes! > 0 ? ' · min ${prn.minIntervalMinutes}m apart' : ''}',
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          waitLabel != null
              ? MarPill(label: 'Available in $waitLabel', tone: MarTone.warning)
              : const MarPill(label: 'Available now', tone: MarTone.success),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
