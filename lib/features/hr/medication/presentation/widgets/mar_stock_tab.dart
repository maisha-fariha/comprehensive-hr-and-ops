import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/mar_medication_stock.dart';
import '../../domain/entities/mar_options.dart';
import '../medication_labels.dart';
import 'medication_common.dart';

/// Web Medication MAR → Stock tab.
class MarStockTab extends StatelessWidget {
  final List<MarStockRow> rows;
  final List<MarOption> residences;
  final String residenceId;
  final bool loading;
  final String? error;
  final bool canWrite;
  final int lowCount;
  final ValueChanged<String> onResidenceChange;
  final VoidCallback onClearResidence;
  final ValueChanged<MarStockRow> onCountStock;

  const MarStockTab({
    super.key,
    required this.rows,
    required this.residences,
    required this.residenceId,
    required this.loading,
    required this.error,
    required this.canWrite,
    required this.lowCount,
    required this.onResidenceChange,
    required this.onClearResidence,
    required this.onCountStock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: MarSelectField(
                label: 'Home',
                value: residenceId,
                placeholder: 'All Residences',
                allowClear: true,
                options: [
                  for (final r in residences) (r.id, r.label),
                ],
                onChanged: onResidenceChange,
              ),
            ),
            if (residenceId.isNotEmpty) ...[
              const SizedBox(width: 8),
              HandoverButton(
                label: 'Clear filter',
                onPressed: onClearResidence,
              ),
            ],
          ],
        ),
        if (lowCount > 0) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: MarPill(
              label:
                  '$lowCount ${lowCount == 1 ? 'medicine' : 'medicines'} at or below the refill level',
              tone: MarTone.warning,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: 'Count what is on the shelf. Each dose given then takes its ',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
            children: [
              TextSpan(
                text: 'units per dose',
                style: handoverText(
                  context,
                  12.5,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text:
                    ' out of the count, set on the medicine itself — a medicine without it keeps the count you typed.',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          MarEmpty(error!)
        else if (rows.isEmpty)
          MarEmpty(
            residenceId.isEmpty
                ? 'No medicines found across residences.'
                : 'No medicines are prescribed at this home.',
          )
        else
          for (final row in rows) ...[
            _StockCard(
              row: row,
              canWrite: canWrite,
              onCount: () => onCountStock(row),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  final MarStockRow row;
  final bool canWrite;
  final VoidCallback onCount;

  const _StockCard({
    required this.row,
    required this.canWrite,
    required this.onCount,
  });

  @override
  Widget build(BuildContext context) {
    final stock = row.stock;
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: handoverText(
                        context,
                        14.5,
                        weight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.kind,
                      style: handoverText(
                        context,
                        11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (canWrite)
                HandoverButton(
                  label: 'Count stock',
                  icon: Icons.inventory_2_outlined,
                  onPressed: onCount,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _meta(context, 'For', '${row.resident}\n${row.residenceName}'),
          const SizedBox(height: 8),
          _meta(
            context,
            'Per dose',
            row.unitsPerDose?.toString() ??
                "Not set — doses don't change the count",
            muted: row.unitsPerDose == null,
          ),
          const SizedBox(height: 8),
          _meta(
            context,
            'In stock',
            stock == null
                ? 'Not counted'
                : [
                    '${_qty(stock.quantity)}${stock.unit == null || stock.unit!.isEmpty ? '' : ' ${stock.unit}'}',
                    if (stock.needsRefill) 'Low',
                    if (stock.updatedAt != null)
                      'as of ${MedicationLabels.dateTime(stock.updatedAt)}',
                  ].join(' · '),
            muted: stock == null,
            warn: stock?.needsRefill == true,
          ),
          const SizedBox(height: 8),
          _meta(
            context,
            'Refill at',
            stock?.refillThreshold == null
                ? '—'
                : _qty(stock!.refillThreshold!),
            muted: stock?.refillThreshold == null,
          ),
        ],
      ),
    );
  }

  static String _qty(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  Widget _meta(
    BuildContext context,
    String label,
    String value, {
    bool muted = false,
    bool warn = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: handoverText(
              context,
              12,
              weight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: handoverText(
              context,
              13,
              weight: warn ? FontWeight.w700 : FontWeight.w500,
              color: warn
                  ? AppColors.urgentAmber
                  : muted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
