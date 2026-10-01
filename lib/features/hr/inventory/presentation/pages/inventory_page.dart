import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../views/inventory_stock_view.dart';
import '../views/purchasing_view.dart';
import '../views/stock_counts_view.dart';
import '../views/stock_transfers_view.dart';

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
                                onTap: () => setState(() => _area = tab),
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
              InventoryArea.purchasing =>
                const PurchasingView(key: ValueKey('inventory-area-purchasing')),
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
