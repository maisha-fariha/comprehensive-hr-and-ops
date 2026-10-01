import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../mar_row.dart';
import '../medication_labels.dart';
import 'medication_common.dart';

enum MarRowAction { view, chart, delete, edit, discontinue }

/// One registry row: the web table columns stacked into a card, with the
/// row's action icons (View, Record administration, Delete prescription,
/// Edit prescription, Discontinue) in the web's order.
class MarRowCard extends StatelessWidget {
  final MarRow row;
  final bool canChart;
  final bool canWrite;
  final ValueChanged<MarRowAction> onAction;

  const MarRowCard({
    super.key,
    required this.row,
    required this.canChart,
    required this.canWrite,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final r = row;
    final statusTone = r.state != null
        ? MedicationLabels.stateTone(r.state)
        : r.statusLabel == 'Discontinued'
            ? MarTone.neutral
            : MarTone.info;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onAction(MarRowAction.view),
      child: HandoverPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MarAvatar(initials: r.residentInitials, color: r.avatarColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.residentName,
                        style: handoverText(context, 14, weight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                      if (r.isControlled)
                        Text(
                          'Controlled drug',
                          style: handoverText(context, 12, color: AppColors.urgentAmber),
                        ),
                    ],
                  ),
                ),
                MarPill(label: r.statusLabel.toUpperCase(), tone: statusTone, rounded: true),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                MarDot(r.dotColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.medication,
                    style: handoverText(context, 14, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Grid(
              cells: [
                ('Residence', r.residence, null),
                ('Dosage', r.dosage, null),
                (r.isPrn ? 'Given' : 'Schedule', r.scheduleSlot, r.scheduleTime),
                ('Last Admin', r.lastAdministered, r.administeredBy),
                if (!r.isPrn) ('Next Due', r.nextDue, null),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Action(
                  key: ValueKey('mar-view-${r.id}'),
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  onTap: () => onAction(MarRowAction.view),
                ),
                if (canChart)
                  _Action(
                    key: ValueKey('mar-chart-${r.id}'),
                    icon: Icons.vaccines_outlined,
                    label: 'Record administration',
                    onTap: () => onAction(MarRowAction.chart),
                  ),
                if (canWrite) ...[
                  _Action(
                    key: ValueKey('mar-delete-${r.id}'),
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete prescription',
                    danger: true,
                    onTap: () => onAction(MarRowAction.delete),
                  ),
                  _Action(
                    key: ValueKey('mar-edit-${r.id}'),
                    icon: Icons.edit_outlined,
                    label: 'Edit prescription',
                    onTap: () => onAction(MarRowAction.edit),
                  ),
                  _Action(
                    key: ValueKey('mar-discontinue-${r.id}'),
                    icon: Icons.block_rounded,
                    label: 'Discontinue',
                    onTap: () => onAction(MarRowAction.discontinue),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<(String, String, String?)> cells;

  const _Grid({required this.cells});

  @override
  Widget build(BuildContext context) {
    Widget cell((String, String, String?) c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.$1.toUpperCase(),
              style: handoverText(context, 10.5, weight: FontWeight.w600, color: AppColors.textMuted)
                  .copyWith(letterSpacing: 0.4),
            ),
            const SizedBox(height: 2),
            Text(c.$2, style: handoverText(context, 13, weight: FontWeight.w500)),
            if (c.$3 != null && c.$3!.isNotEmpty)
              Text(c.$3!, style: handoverText(context, 11.5, color: AppColors.textMuted)),
          ],
        );
    return Column(
      children: [
        for (var i = 0; i < cells.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < cells.length ? 8 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cell(cells[i])),
                const SizedBox(width: 12),
                Expanded(child: i + 1 < cells.length ? cell(cells[i + 1]) : const SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 19, color: danger ? AppColors.criticalRed : AppColors.primaryNavy),
      ),
    );
  }
}
