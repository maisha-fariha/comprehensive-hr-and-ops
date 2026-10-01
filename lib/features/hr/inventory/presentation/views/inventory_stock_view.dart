import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../controllers/inventory_stock_controller.dart';
import '../widgets/inventory_catalogue_sheet.dart';
import '../widgets/inventory_common.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/inventory_item_detail_sheet.dart';
import '../widgets/inventory_item_form_sheet.dart';
import '../widgets/inventory_kpi_grid.dart';
import '../widgets/inventory_stock_action_sheet.dart';
import '../widgets/inventory_stock_panels.dart';

/// Web `/dashboard/inventory` ("Stock").
class InventoryStockView extends StatefulWidget {
  final VoidCallback onOrderMore;

  const InventoryStockView({super.key, required this.onOrderMore});

  @override
  State<InventoryStockView> createState() => _InventoryStockViewState();
}

class _InventoryStockViewState extends State<InventoryStockView> {
  late final InventoryStockController _c;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<InventoryStockController>());
  }

  @override
  void dispose() {
    _search.dispose();
    Get.delete<InventoryStockController>();
    super.dispose();
  }

  Future<void> _confirmDelete(InventoryItem item) async {
    final confirmed = await confirmInventoryAction(
      context,
      title: 'Delete this item?',
      description: 'It leaves the shelf list. The item and its stock history are kept rather '
          'than destroyed, so it can be restored.',
      confirmLabel: 'Delete',
    );
    if (confirmed) await _c.deleteItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return RefreshIndicator(
      color: AppColors.secondaryTeal,
      onRefresh: _c.refreshAll,
      child: Obx(
        () => ListView(
          key: const ValueKey('inventory-stock-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
          children: [
            _toolbar(context),
            InventoryKpiGrid(
              summary: _c.summary.value,
              onShowLowStock: () => _c.setLowStock(true),
            ),
            const SizedBox(height: 14),
            InventoryNeedsOrderingPanel(
              loading: _c.lowLoading.value,
              items: _c.lowItems.toList(),
              total: _c.lowTotal.value,
              onShowAll: () => _c.setLowStock(true),
              onOrderMore: widget.onOrderMore,
            ),
            const SizedBox(height: 12),
            InventoryExpiringPanel(
              loading: _c.expiringLoading.value,
              batches: _c.expiring.toList(),
            ),
            const SizedBox(height: 14),
            if (_c.lowStock.value) ...[
              _lowBanner(context),
              const SizedBox(height: 12),
            ],
            _searchField(context),
            const SizedBox(height: 12),
            ..._list(context),
            const SizedBox(height: 14),
            InventoryMovementPanel(
              loading: _c.movementsLoading.value,
              failed: _c.movementsFailed.value,
              movements: _c.movements.toList(),
            ),
            const SizedBox(height: 12),
            InventoryLossesPanel(losses: _c.losses.toList()),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context) => InventoryToolbar(
        children: [
          InventoryFilterButton(
            key: const ValueKey('inventory-filter-residence'),
            title: 'Residence',
            options: [('', 'All Residences'), for (final r in _c.residences) (r.value, r.label)],
            value: _c.residenceId.value ?? '',
            onChanged: (v) => _c.setResidence(v.isEmpty ? null : v),
          ),
          InventoryFilterButton(
            key: const ValueKey('inventory-filter-category'),
            title: 'Category',
            options: [('', 'All Categories'), for (final o in _c.categoryOptions) (o.value, o.label)],
            value: _c.categoryId.value ?? '',
            onChanged: (v) => _c.setCategory(v.isEmpty ? null : v),
          ),
          if (_c.canWrite) ...[
            HandoverButton(
              key: const ValueKey('inventory-open-catalogue'),
              label: 'Categories & units',
              icon: Icons.tune_rounded,
              onPressed: () => showInventoryCatalogueSheet(context, controller: _c),
            ),
            HandoverButton(
              key: const ValueKey('inventory-add-item'),
              label: 'Add item',
              icon: Icons.add_rounded,
              filled: true,
              onPressed: () => showInventoryItemForm(context, controller: _c),
            ),
          ],
        ],
      );

  Widget _lowBanner(BuildContext context) => Container(
        key: const ValueKey('inventory-low-banner'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.urgentBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Showing only what is at or below its reorder level.',
                style: handoverText(context, 13, color: AppColors.textHeading),
              ),
            ),
            const SizedBox(width: 8),
            HandoverButton(
              key: const ValueKey('inventory-show-everything'),
              label: 'Show everything',
              compact: true,
              onPressed: () => _c.setLowStock(false),
            ),
          ],
        ),
      );

  Widget _searchField(BuildContext context) => TextField(
        key: const ValueKey('inventory-search'),
        controller: _search,
        onChanged: _c.setSearch,
        style: handoverText(context, 13.5),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by item name or SKU…',
          hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surfaceWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
        ),
      );

  List<Widget> _list(BuildContext context) {
    if (_c.loading.value && _c.items.isEmpty) return const [InventorySkeleton()];
    if (_c.items.isEmpty) {
      final error = _c.loadError.value;
      return [
        InventoryEmptyState(
          key: const ValueKey('inventory-empty'),
          icon: Icons.inventory_2_outlined,
          title: error != null ? 'Inventory could not be loaded' : 'No items found',
          message: error ?? 'Items you add appear here with their stock level.',
        ),
      ];
    }
    return [
      for (final item in _c.items) ...[
        InventoryItemCard(
          key: ValueKey('inventory-item-${item.id}'),
          item: item,
          canWrite: _c.canWrite,
          onOpen: () => showInventoryItemDetail(context, controller: _c, item: item),
          onStock: () => showInventoryStockAction(context, controller: _c, item: item),
          onEdit: () => showInventoryItemForm(context, controller: _c, item: item),
          onDelete: () => _confirmDelete(item),
        ),
        const SizedBox(height: 12),
      ],
      AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: _c.total.value,
        totalPages: _c.totalPages,
        limitOptions: InventoryStockController.pageSizes,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    ];
  }
}
