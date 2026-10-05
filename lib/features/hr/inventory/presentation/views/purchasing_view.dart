import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/purchasing.dart';
import '../controllers/purchasing_controller.dart';
import '../inventory_labels.dart';
import '../widgets/inventory_common.dart';
import '../widgets/purchase_order_form_sheet.dart';
import '../widgets/purchasing_sheets.dart';

/// Web `/dashboard/purchasing`.
class PurchasingView extends StatefulWidget {
  const PurchasingView({super.key});

  @override
  State<PurchasingView> createState() => _PurchasingViewState();
}

class _PurchasingViewState extends State<PurchasingView> {
  late final PurchasingController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<PurchasingController>());
  }

  @override
  void dispose() {
    Get.delete<PurchasingController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return RefreshIndicator(
      color: AppColors.secondaryTeal,
      onRefresh: _c.refreshAll,
      child: Obx(() {
        final orders = _c.tab.value == PurchasingTab.orders;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
          children: [
            if ((orders && _c.canWriteOrders) || (!orders && _c.canWriteSuppliers))
              InventoryToolbar(
                children: [
                  if (orders)
                    HandoverButton(
                      key: const ValueKey('order-new'),
                      label: 'New order',
                      icon: Icons.add_rounded,
                      filled: true,
                      onPressed: () => showPurchaseOrderForm(context, controller: _c),
                    )
                  else
                    HandoverButton(
                      key: const ValueKey('supplier-new'),
                      label: 'Add supplier',
                      icon: Icons.add_rounded,
                      filled: true,
                      onPressed: () => showAddSupplierSheet(context, controller: _c),
                    ),
                ],
              ),
            _tabs(context),
            const SizedBox(height: 14),
            ...(orders ? _orders(context) : _suppliers(context)),
          ],
        );
      }),
    );
  }

  Widget _tabs(BuildContext context) => HandoverPanel(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final (tab, label) in const [
              (PurchasingTab.orders, 'Purchase orders'),
              (PurchasingTab.suppliers, 'Suppliers'),
            ])
              Expanded(
                child: InkWell(
                  key: ValueKey('purchasing-tab-${tab.name}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _c.setTab(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _c.tab.value == tab ? AppColors.filterButtonBackground : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: handoverText(
                        context,
                        13.5,
                        weight: _c.tab.value == tab ? FontWeight.w600 : FontWeight.w400,
                        color: _c.tab.value == tab ? AppColors.textHeading : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _pagination(int total) => AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: total,
        totalPages: _c.totalPages,
        limitOptions: PurchasingController.pageSizes,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      );

  List<Widget> _orders(BuildContext context) {
    if (_c.ordersLoading.value && _c.orders.isEmpty) return const [InventorySkeleton()];
    if (_c.orders.isEmpty) {
      final error = _c.ordersError.value;
      return [
        InventoryEmptyState(
          key: const ValueKey('order-empty'),
          icon: Icons.local_shipping_outlined,
          title: error != null ? 'Orders could not be loaded' : 'No purchase orders',
          message: error ?? 'Orders start as a draft and move through submission, approval and receipt.',
        ),
      ];
    }
    return [
      for (final order in _c.orders) ...[
        _orderCard(context, order),
        const SizedBox(height: 12),
      ],
      _pagination(_c.ordersTotal.value),
    ];
  }

  Widget _orderCard(BuildContext context, PurchaseOrder order) {
    final busy = _c.busyId.value == order.id;
    final count = order.items.length;
    final total = order.total;
    final ordered = order.orderedUnits;
    final received = order.receivedUnits;
    Widget cell(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: handoverText(context, 11.5, color: AppColors.textMuted)),
              const SizedBox(height: 3),
              value,
            ],
          ),
        );
    final actions = <Widget>[
      if (_c.canWriteOrders && order.status == 'draft')
        HandoverButton(
          key: ValueKey('order-edit-${order.id}'),
          label: 'Edit',
          compact: true,
          onPressed: busy ? null : () => showPurchaseOrderForm(context, controller: _c, order: order),
        ),
      if (_c.canWriteOrders && order.allows('submit'))
        order.canSubmit
            ? HandoverButton(
                key: ValueKey('order-submit-${order.id}'),
                label: 'Submit',
                filled: true,
                compact: true,
                onPressed: busy ? null : () => _c.submit(order),
              )
            : Tooltip(
                message: 'Choose a supplier before submitting',
                child: HandoverButton(
                  key: ValueKey('order-submit-${order.id}'),
                  label: 'Submit',
                  filled: true,
                  compact: true,
                  onPressed: null,
                ),
              ),
      if (_c.canWriteOrders && order.allows('requestApproval'))
        HandoverButton(
          key: ValueKey('order-request-approval-${order.id}'),
          label: 'Send for approval',
          compact: true,
          onPressed: busy ? null : () => _c.requestApproval(order),
        ),
      if (_c.canApprove && order.allows('approve')) ...[
        HandoverButton(
          key: ValueKey('order-approve-${order.id}'),
          label: 'Approve',
          filled: true,
          compact: true,
          onPressed: busy ? null : () => _c.approve(order),
        ),
        HandoverButton(
          key: ValueKey('order-reject-${order.id}'),
          label: 'Reject',
          compact: true,
          onPressed: busy ? null : () => showRejectOrderSheet(context, controller: _c, order: order),
        ),
      ],
      if (_c.canReceive && order.allows('receive'))
        HandoverButton(
          key: ValueKey('order-receive-${order.id}'),
          label: 'Receive',
          icon: Icons.inventory_outlined,
          filled: true,
          compact: true,
          onPressed: busy ? null : () => showReceiveOrderSheet(context, controller: _c, order: order),
        ),
      if (_c.canWriteOrders && order.allows('cancel'))
        HandoverButton(
          key: ValueKey('order-cancel-${order.id}'),
          label: 'Cancel',
          compact: true,
          onPressed: busy ? null : () => _c.cancel(order),
        ),
    ];
    return HandoverPanel(
      key: ValueKey('order-${order.id}'),
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
                      order.supplierName ?? 'No supplier',
                      style: handoverText(context, 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.displayReference} · $count product${count == 1 ? '' : 's'}',
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AttendancePill(
                label: InventoryLabels.humanise(order.status),
                tone: InventoryLabels.orderTone(order.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell('Residence', Text(order.residenceName ?? '—', style: handoverText(context, 13))),
              cell(
                'Value',
                total == null
                    ? Text('Not priced', style: handoverText(context, 13, color: AppColors.textMuted))
                    : Text(
                        InventoryLabels.money(total),
                        style: handoverText(context, 13, weight: FontWeight.w600),
                      ),
              ),
              cell(
                'Arrived',
                ordered == 0
                    ? Text('—', style: handoverText(context, 13))
                    : Text(
                        '${InventoryLabels.qty(received)} of ${InventoryLabels.qty(ordered)}',
                        style: handoverText(
                          context,
                          13,
                          color: received >= ordered ? AppColors.activeGreen : AppColors.textHeading,
                        ),
                      ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }

  List<Widget> _suppliers(BuildContext context) {
    if (_c.suppliersLoading.value && _c.suppliers.isEmpty) return const [InventorySkeleton()];
    if (_c.suppliers.isEmpty) {
      return [
        HandoverPanel(
          key: const ValueKey('supplier-empty'),
          padding: const EdgeInsets.all(28),
          child: Text(
            _c.suppliersError.value ?? 'No suppliers yet.',
            textAlign: TextAlign.center,
            style: handoverText(context, 13.5, color: AppColors.textMuted),
          ),
        ),
      ];
    }
    return [
      for (final s in _c.suppliers) ...[
        _supplierCard(context, s),
        const SizedBox(height: 12),
      ],
      _pagination(_c.suppliersTotal.value),
    ];
  }

  Widget _supplierCard(BuildContext context, InventorySupplier s) => HandoverPanel(
        key: ValueKey('supplier-${s.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: handoverText(context, 15, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    s.contactName ?? s.email ?? '—',
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${InventoryLabels.humanise(s.category ?? '')}${s.phone != null ? ' · ${s.phone}' : ''}',
                    style: handoverText(context, 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_c.canWriteSuppliers)
              s.isDeleted
                  ? HandoverButton(
                      key: ValueKey('supplier-restore-${s.id}'),
                      label: 'Restore',
                      compact: true,
                      onPressed: () => _c.restoreSupplier(s),
                    )
                  : HandoverButton(
                      key: ValueKey('supplier-remove-${s.id}'),
                      label: 'Remove',
                      compact: true,
                      onPressed: () => _c.removeSupplier(s),
                    ),
          ],
        ),
      );
}
