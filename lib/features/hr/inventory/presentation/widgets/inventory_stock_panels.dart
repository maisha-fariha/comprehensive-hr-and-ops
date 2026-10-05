import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../inventory_labels.dart';
import 'inventory_common.dart';

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? pill;

  const _PanelTitle({required this.icon, required this.title, this.pill});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title, style: handoverText(context, 14.5, weight: FontWeight.w600)),
            ),
            ?pill,
          ],
        ),
      );
}

class _Line extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _Line({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: handoverText(context, 13.5, weight: FontWeight.w500)),
                  Text(subtitle, style: handoverText(context, 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      );
}

/// "Needs ordering": the first five items at or below their reorder level.
class InventoryNeedsOrderingPanel extends StatelessWidget {
  final bool loading;
  final List<InventoryItem> items;
  final int total;
  final VoidCallback onShowAll;
  final VoidCallback onOrderMore;

  const InventoryNeedsOrderingPanel({
    super.key,
    required this.loading,
    required this.items,
    required this.total,
    required this.onShowAll,
    required this.onOrderMore,
  });

  @override
  Widget build(BuildContext context) => HandoverPanel(
        key: const ValueKey('inventory-needs-ordering'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelTitle(
              icon: Icons.shopping_cart_outlined,
              title: 'Needs ordering',
              pill: total > 0
                  ? AttendancePill(label: '$total below its level', tone: AttendanceTone.warning)
                  : null,
            ),
            if (loading)
              const InventoryNote('Checking…')
            else if (total == 0)
              const InventoryNote(
                'Nothing is below its reorder level. Items without a level set are not watched.',
              )
            else ...[
              for (final item in items)
                _Line(
                  title: item.name,
                  subtitle: '${InventoryLabels.qty(item.quantity)} ${item.unitLabel} left · '
                      'reorder at ${InventoryLabels.qty(item.reorderLevel)}',
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (total > items.length)
                    HandoverButton(
                      key: const ValueKey('inventory-see-all-low'),
                      label: 'See all $total',
                      onPressed: onShowAll,
                    ),
                  HandoverButton(
                    key: const ValueKey('inventory-order-more'),
                    label: 'Order more',
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    onPressed: onOrderMore,
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

/// "Going out of date": lots expiring in the next 30 days.
class InventoryExpiringPanel extends StatelessWidget {
  final bool loading;
  final List<InventoryBatch> batches;
  final DateTime? now;

  const InventoryExpiringPanel({
    super.key,
    required this.loading,
    required this.batches,
    this.now,
  });

  static const int _shown = 6;

  @override
  Widget build(BuildContext context) => HandoverPanel(
        key: const ValueKey('inventory-expiring'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelTitle(
              icon: Icons.event_busy_outlined,
              title: 'Going out of date',
              pill: batches.isNotEmpty
                  ? AttendancePill(label: '${batches.length} lots', tone: AttendanceTone.danger)
                  : null,
            ),
            if (loading)
              const InventoryNote('Checking…')
            else if (batches.isEmpty)
              const InventoryNote('Nothing expires in the next month.')
            else
              for (final batch in batches.take(_shown)) _row(batch),
          ],
        ),
      );

  Widget _row(InventoryBatch batch) {
    final days = batch.daysLeft(now: now) ?? 0;
    final (text, tone) = days < 0
        ? ('${days.abs()}d past its date', AttendanceTone.danger)
        : days == 0
            ? ('Today', AttendanceTone.danger)
            : days <= 7
                ? ('${days}d left', AttendanceTone.danger)
                : ('${days}d left', AttendanceTone.warning);
    return _Line(
      title: batch.itemName ?? 'Item',
      subtitle: '${InventoryLabels.qty(batch.quantity)} ${batch.itemUnit ?? ''}'
          '${batch.batchNo != null ? ' · lot ${batch.batchNo}' : ''}'
          '${batch.expiryDay != null ? ' · ${batch.expiryDay}' : ''}',
      trailing: AttendancePill(label: text, tone: tone),
    );
  }
}

/// "Recent stock movement": the last eight entries of the movement log.
class InventoryMovementPanel extends StatelessWidget {
  final bool loading;
  final bool failed;
  final List<StockMovement> movements;

  const InventoryMovementPanel({
    super.key,
    required this.loading,
    required this.failed,
    required this.movements,
  });

  static (IconData, Color, Color) _look(String type) => switch (type) {
        'waste' || 'damaged' || 'expired' || 'lost' => (
            Icons.warning_amber_rounded,
            AppColors.criticalRed,
            AppColors.criticalBackgroundSoft,
          ),
        'transfer_in' || 'transfer_out' => (
            Icons.swap_horiz_rounded,
            AppColors.nightPurple,
            AppColors.nightBackground,
          ),
        'adjustment' => (Icons.fact_check_outlined, AppColors.infoBlue, AppColors.infoBackground),
        'stock_in' || 'purchase_received' || 'batch_added' => (
            Icons.inventory_outlined,
            AppColors.secondaryTeal,
            AppColors.quickActionCreateShiftBg,
          ),
        _ => (Icons.outbox_outlined, AppColors.urgentAmber, AppColors.urgentBackground),
      };

  @override
  Widget build(BuildContext context) => HandoverPanel(
        key: const ValueKey('inventory-movements'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Recent stock movement',
                style: handoverText(context, 14.5, weight: FontWeight.w600),
              ),
            ),
            for (final m in movements) _row(context, m),
            if (movements.isEmpty)
              InventoryNote(
                loading
                    ? 'Loading…'
                    : failed
                        ? 'The movement log could not be loaded.'
                        : 'Nothing has moved yet.',
              ),
          ],
        ),
      );

  Widget _row(BuildContext context, StockMovement m) {
    final (icon, fg, bg) = _look(m.type);
    final label = InventoryLabels.movementTypes[m.type]?.toLowerCase() ?? m.type;
    final meta = [
      m.residenceName,
      m.performedByName,
      InventoryLabels.short(m.createdAt),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: m.itemName ?? 'An item',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' $label · ${m.changeQty > 0 ? '+' : ''}'
                            '${InventoryLabels.qty(m.changeQty)} ${m.unit ?? ''}',
                      ),
                    ],
                  ),
                  style: handoverText(context, 13),
                ),
                Text(meta, style: handoverText(context, 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Recent losses": the latest written-off stock.
class InventoryLossesPanel extends StatelessWidget {
  final List<InventoryLoss> losses;

  const InventoryLossesPanel({super.key, required this.losses});

  @override
  Widget build(BuildContext context) => HandoverPanel(
        key: const ValueKey('inventory-losses'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Recent losses', style: handoverText(context, 14.5, weight: FontWeight.w600)),
            ),
            if (losses.isEmpty)
              const InventoryNote('Nothing written off recently.')
            else
              for (final loss in losses)
                _Line(
                  title: '${loss.itemName ?? 'Item no longer on file'} · '
                      '${InventoryLabels.qty(loss.quantity)} ${loss.unit ?? ''}'
                      '${loss.notes != null && loss.notes!.isNotEmpty ? ' · ${loss.notes}' : ''}',
                  subtitle: [
                    loss.residenceName,
                    loss.loggedByName,
                    if (loss.createdAt != null) InventoryLabels.date(loss.createdAt),
                  ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  trailing: AttendancePill(
                    label: InventoryLabels.humanise(loss.exceptionType),
                    tone: InventoryLabels.lossTone(loss.exceptionType),
                  ),
                ),
          ],
        ),
      );
}
