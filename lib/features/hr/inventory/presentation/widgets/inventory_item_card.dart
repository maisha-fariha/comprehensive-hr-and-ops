import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../inventory_labels.dart';

/// One row of the web stock table (Item, Residence, On hand, Stock,
/// Batches, Supplier, Value, actions) laid out as a card.
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final bool canWrite;
  final VoidCallback onOpen;
  final VoidCallback onStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.canWrite,
    required this.onOpen,
    required this.onStock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sku = item.sku == null || item.sku!.isEmpty ? null : item.sku;
    final state = item.stockState;
    Widget cell(String label, Widget value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: handoverText(context, 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 3),
            value,
          ],
        );
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
                    InkWell(
                      key: ValueKey('inventory-item-open-${item.id}'),
                      onTap: onOpen,
                      child: Text(
                        item.name,
                        style: handoverText(
                          context,
                          15,
                          weight: FontWeight.w600,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.categoryName ?? '—'}${sku != null ? ' · $sku' : ''}',
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AttendancePill(
                label: InventoryLabels.stockLabel(state),
                tone: InventoryLabels.stockTone(state),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: cell(
                  'Residence',
                  Text(item.residenceName ?? '—', style: handoverText(context, 13)),
                ),
              ),
              Expanded(
                child: cell(
                  'On hand',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${InventoryLabels.qty(item.quantity)} ${item.unitLabel}',
                        style: handoverText(context, 13, weight: FontWeight.w600),
                      ),
                      if (item.reorderLevel != null)
                        Text(
                          'reorder at ${InventoryLabels.qty(item.reorderLevel)}',
                          style: handoverText(context, 11.5, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: cell(
                  'Batches',
                  Align(
                    alignment: Alignment.centerLeft,
                    child: item.tracksBatches
                        ? const AttendancePill(label: 'Batch tracked', tone: AttendanceTone.info)
                        : Text('—', style: handoverText(context, 13)),
                  ),
                ),
              ),
              Expanded(
                child: cell(
                  'Supplier',
                  Text(item.supplierName ?? '—', style: handoverText(context, 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          cell(
            'Value',
            item.stockValue == null
                ? Text('Not costed', style: handoverText(context, 13, color: AppColors.textMuted))
                : Text(
                    InventoryLabels.money(item.stockValue!),
                    style: handoverText(context, 13, weight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HandoverButton(
                key: ValueKey('inventory-item-stock-${item.id}'),
                label: 'Stock',
                compact: true,
                onPressed: onStock,
              ),
              if (canWrite) ...[
                HandoverButton(
                  key: ValueKey('inventory-item-edit-${item.id}'),
                  label: 'Edit',
                  compact: true,
                  onPressed: onEdit,
                ),
                Tooltip(
                  message: 'Delete item',
                  child: HandoverButton(
                    key: ValueKey('inventory-item-delete-${item.id}'),
                    label: '',
                    icon: Icons.delete_outline_rounded,
                    foreground: AppColors.criticalRed,
                    compact: true,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
