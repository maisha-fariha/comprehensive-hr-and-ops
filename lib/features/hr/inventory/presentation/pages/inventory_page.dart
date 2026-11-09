import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../presentation/widgets/hr_header_primary_action.dart';
import '../controllers/purchasing_controller.dart';
import '../controllers/stock_counts_controller.dart';
import '../controllers/stock_transfers_controller.dart';
import '../views/inventory_stock_view.dart';
import '../views/purchasing_view.dart';
import '../views/stock_counts_view.dart';
import '../views/stock_transfers_view.dart';
import '../widgets/purchase_order_form_sheet.dart';
import '../widgets/purchasing_sheets.dart';
import '../widgets/stock_count_sheets.dart';
import '../widgets/stock_transfer_sheets.dart';

enum InventoryArea { stock, counts, transfers, purchasing }

/// Manager "Inventory" — mirrors web `/dashboard/inventory` and its sibling
/// pages (counts, transfers, purchasing) behind the same sub-navigation.
class InventoryPage extends StatefulWidget {
  final InventoryArea initialArea;

  const InventoryPage({super.key, this.initialArea = InventoryArea.stock});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final UserSession _session;
  late InventoryArea? _area;

  static const _tabs = [
    (InventoryArea.stock, 'Stock', 'inventory:read', 'What is on the shelf'),
    (InventoryArea.counts, 'Stock counts', 'inventory:read', 'Check what is really there'),
    (InventoryArea.transfers, 'Transfers', 'inventory:read', 'Move stock between houses'),
    (InventoryArea.purchasing, 'Purchasing', 'purchase-orders:read', 'Order more, and book it in'),
  ];

  bool _allowed(InventoryArea area) => switch (area) {
        InventoryArea.purchasing =>
          _session.can('purchase-orders:read') || _session.can('suppliers:read'),
        _ => _session.can('inventory:read'),
      };

  @override
  void initState() {
    super.initState();
    _session = Get.find<UserSession>();
    _area = _allowed(widget.initialArea)
        ? widget.initialArea
        : InventoryArea.values.where(_allowed).firstOrNull;
  }

  static String _title(InventoryArea? area) => switch (area) {
        InventoryArea.counts => 'Stock counts',
        InventoryArea.transfers => 'Stock transfers',
        InventoryArea.purchasing => 'Purchasing',
        _ => 'Inventory',
      };

  Widget? _headerPrimary(BuildContext context) {
    final area = _area;
    if (area == InventoryArea.counts && _session.can('inventory:adjustment')) {
      return HrHeaderPrimaryAction(
        actionKey: const ValueKey('count-start'),
        label: 'Count',
        onTap: _startCount,
      );
    }
    if (area == InventoryArea.transfers &&
        _session.can('inventory:transfer:request')) {
      return HrHeaderPrimaryAction(
        actionKey: const ValueKey('transfer-new'),
        label: 'Move',
        onTap: _newTransfer,
      );
    }
    if (area == InventoryArea.purchasing) {
      if (!Get.isRegistered<PurchasingController>()) return null;
      final c = Get.find<PurchasingController>();
      final orders = c.tab.value == PurchasingTab.orders;
      if (orders && c.canWriteOrders) {
        return HrHeaderPrimaryAction(
          actionKey: const ValueKey('order-new'),
          label: 'Order',
          onTap: () => showPurchaseOrderForm(context, controller: c),
        );
      }
      if (!orders && c.canWriteSuppliers) {
        return HrHeaderPrimaryAction(
          actionKey: const ValueKey('supplier-new'),
          label: 'Supplier',
          onTap: () => showAddSupplierSheet(context, controller: c),
        );
      }
    }
    return null;
  }

  Future<void> _startCount() async {
    if (!Get.isRegistered<StockCountsController>()) return;
    final c = Get.find<StockCountsController>();
    final id = await showStartCountSheet(context, controller: c);
    if (id != null && mounted) {
      await showStockCountSheet(context, controller: c, countId: id);
    }
  }

  Future<void> _newTransfer() async {
    if (!Get.isRegistered<StockTransfersController>()) return;
    await showTransferRequestSheet(
      context,
      controller: Get.find<StockTransfersController>(),
    );
  }

  void _selectArea(InventoryArea tab) {
    setState(() => _area = tab);
  }

  @override
  Widget build(BuildContext context) {
    final area = _area;
    final tabs = [for (final t in _tabs) if (_session.can(t.$3)) t];
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHeading),
                        ),
                        Expanded(
                          child: Text(
                            _title(area),
                            key: const ValueKey('inventory-title'),
                            style: handoverText(context, 18, weight: FontWeight.w700),
                          ),
                        ),
                        _headerPrimary(context) ?? const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  if (area != null && tabs.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          for (final (tab, label, _, hint) in tabs)
                            Tooltip(
                              message: hint,
                              child: InkWell(
                                key: ValueKey('inventory-nav-${tab.name}'),
                                onTap: () => _selectArea(tab),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        width: 2,
                                        color: tab == area ? AppColors.secondaryTeal : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: handoverText(
                                      context,
                                      13.5,
                                      weight: tab == area ? FontWeight.w600 : FontWeight.w400,
                                      color: tab == area ? AppColors.textHeading : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (area) {
              InventoryArea.stock => InventoryStockView(
                  key: const ValueKey('inventory-area-stock'),
                  onOrderMore: () => setState(
                    () => _area = _allowed(InventoryArea.purchasing) ? InventoryArea.purchasing : area,
                  ),
                ),
              InventoryArea.counts => const StockCountsView(key: ValueKey('inventory-area-counts')),
              InventoryArea.transfers =>
                const StockTransfersView(key: ValueKey('inventory-area-transfers')),
              InventoryArea.purchasing => PurchasingView(
                  key: const ValueKey('inventory-area-purchasing'),
                  onHeaderNeedsRebuild: () {
                    if (mounted) setState(() {});
                  },
                ),
              null => const _NoAccess(),
            },
          ),
        ],
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) => Center(
        key: const ValueKey('inventory-no-access'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 28, color: AppColors.textMuted),
              const SizedBox(height: 10),
              Text(
                "You don't have access to this page",
                textAlign: TextAlign.center,
                style: handoverText(context, 16, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Ask an administrator to grant your role the permission it needs.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
}
