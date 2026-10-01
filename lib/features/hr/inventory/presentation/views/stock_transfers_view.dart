import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/stock_ops.dart';
import '../controllers/stock_transfers_controller.dart';
import '../inventory_labels.dart';
import '../widgets/inventory_common.dart';
import '../widgets/stock_transfer_sheets.dart';

/// Web "Stock transfers".
class StockTransfersView extends StatefulWidget {
  const StockTransfersView({super.key});

  @override
  State<StockTransfersView> createState() => _StockTransfersViewState();
}

class _StockTransfersViewState extends State<StockTransfersView> {
  late final StockTransfersController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<StockTransfersController>());
  }

  @override
  void dispose() {
    Get.delete<StockTransfersController>();
    super.dispose();
  }

  void _step(StockTransfer transfer, String step) {
    if (step == 'dispatch' || step == 'receive') {
      showTransferStepSheet(context, controller: _c, transfer: transfer, step: step);
    } else {
      _c.approve(transfer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return RefreshIndicator(
      color: AppColors.secondaryTeal,
      onRefresh: _c.load,
      child: Obx(
        () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
          children: [
            if (_c.canRequest)
              InventoryToolbar(
                children: [
                  HandoverButton(
                    key: const ValueKey('transfer-new'),
                    label: 'Move stock',
                    icon: Icons.add_rounded,
                    filled: true,
                    onPressed: () => showTransferRequestSheet(context, controller: _c),
                  ),
                ],
              ),
            ..._list(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _list(BuildContext context) {
    if (_c.loading.value && _c.transfers.isEmpty) return const [InventorySkeleton()];
    if (_c.transfers.isEmpty) {
      final error = _c.loadError.value;
      return [
        InventoryEmptyState(
          key: const ValueKey('transfer-empty'),
          icon: Icons.swap_horiz_rounded,
          title: error != null ? 'Transfers could not be loaded' : 'No transfers',
          message: error ?? 'Stock moving between residences appears here.',
        ),
      ];
    }
    return [
      for (final t in _c.transfers) ...[
        _card(context, t),
        const SizedBox(height: 12),
      ],
      AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: _c.total.value,
        totalPages: _c.totalPages,
        limitOptions: StockTransfersController.pageSizes,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    ];
  }

  static String _lineStatus(StockTransferLine line) {
    final q = InventoryLabels.qty(line.quantity);
    final sent = line.dispatchedQuantity;
    final arrived = line.receivedQuantity;
    if (sent == null) return '$q requested';
    if (arrived == null) return '${InventoryLabels.qty(sent)} sent of $q';
    final missing = sent - arrived;
    return '${InventoryLabels.qty(arrived)} arrived of ${InventoryLabels.qty(sent)} sent'
        '${missing > 0 ? ' · ${InventoryLabels.qty(missing)} unaccounted for' : ''}';
  }

  Widget _card(BuildContext context, StockTransfer t) {
    final busy = _c.busyId.value == t.id;
    final steps = [for (final s in t.nextSteps) if (_c.canStep(s)) s];
    final count = t.lines.length;
    return HandoverPanel(
      key: ValueKey('transfer-${t.id}'),
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
                      '${t.fromResidenceName ?? '—'} → ${t.toResidenceName ?? '—'}',
                      style: handoverText(context, 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count product${count == 1 ? '' : 's'}'
                      '${t.notes != null && t.notes!.isNotEmpty ? ' · ${t.notes}' : ''}',
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AttendancePill(
                label: InventoryLabels.humanise(t.status),
                tone: InventoryLabels.transferTone(t.status),
                dot: true,
              ),
            ],
          ),
          if (steps.isNotEmpty || (_c.canCancel && t.canCancel)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in steps)
                  HandoverButton(
                    key: ValueKey('transfer-$s-${t.id}'),
                    label: InventoryLabels.transferSteps[s]!,
                    filled: true,
                    compact: true,
                    onPressed: busy ? null : () => _step(t, s),
                  ),
                if (_c.canCancel && t.canCancel)
                  HandoverButton(
                    key: ValueKey('transfer-cancel-${t.id}'),
                    label: 'Cancel',
                    compact: true,
                    onPressed: busy ? null : () => _c.cancel(t),
                  ),
              ],
            ),
          ],
          if (t.lines.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 6),
            for (final line in t.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(line.itemName ?? 'Item', style: handoverText(context, 13)),
                    ),
                    Text(
                      _lineStatus(line),
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
