import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../controllers/inventory_stock_controller.dart';
import '../inventory_labels.dart';
import 'inventory_common.dart';

/// Web item detail modal: lots and expiry, stock history, cost history and
/// the suppliers linked to the item.
Future<void> showInventoryItemDetail(
  BuildContext context, {
  required InventoryStockController controller,
  required InventoryItem item,
}) =>
    showInventorySheet<void>(
      context,
      (_) => InventoryItemDetailSheet(controller: controller, item: item),
    );

class InventoryItemDetailSheet extends StatefulWidget {
  final InventoryStockController controller;
  final InventoryItem item;
  final DateTime? now;

  const InventoryItemDetailSheet({
    super.key,
    required this.controller,
    required this.item,
    this.now,
  });

  @override
  State<InventoryItemDetailSheet> createState() => _InventoryItemDetailSheetState();
}

class _InventoryItemDetailSheetState extends State<InventoryItemDetailSheet> {
  static const int _historyLimit = 12;
  static const int _costShown = 8;

  List<InventoryBatch>? _batches;
  List<StockMovement>? _history;
  List<InventoryCostEntry>? _costs;
  List<InventoryItemSupplier>? _suppliers;
  bool _busy = false;

  bool _addingLot = false;
  String? _editingLot;
  final _lotNo = TextEditingController();
  String _lotExpiry = '';
  final _newQty = TextEditingController();
  final _newLotNo = TextEditingController();
  String _newExpiry = '';
  final _newCost = TextEditingController();

  bool _addingSupplier = false;
  String _supplierId = '';
  final _supplierSku = TextEditingController();
  final _supplierCost = TextEditingController();

  InventoryItem get _item => widget.item;
  String get _unit => _item.unitLabel;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    for (final c in [_lotNo, _newQty, _newLotNo, _newCost, _supplierSku, _supplierCost]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() => Future.wait([_loadBatches(), _loadHistory(), _loadCosts(), _loadSuppliers()]);

  Future<void> _loadBatches() async {
    final r = await widget.controller.repository.batches(_item.id);
    if (mounted) setState(() => _batches = r.when(success: (v) => v, failure: (_) => const []));
  }

  Future<void> _loadHistory() async {
    final r = await widget.controller.repository.movements(itemId: _item.id, limit: _historyLimit);
    if (mounted) setState(() => _history = r.when(success: (v) => v, failure: (_) => const []));
  }

  Future<void> _loadCosts() async {
    final r = await widget.controller.repository.costHistory(_item.id);
    if (mounted) setState(() => _costs = r.when(success: (v) => v, failure: (_) => const []));
  }

  Future<void> _loadSuppliers() async {
    final r = await widget.controller.repository.itemSuppliers(_item.id);
    if (mounted) setState(() => _suppliers = r.when(success: (v) => v, failure: (_) => const []));
  }

  Future<bool> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return false;
    setState(() => _busy = false);
    return error == null;
  }

  Future<void> _recordLot() async {
    final qty = num.tryParse(_newQty.text.trim());
    if (qty == null || qty <= 0) {
      AppSnackbar.show('How many came in?', '');
      return;
    }
    final cost = num.tryParse(_newCost.text.trim());
    final ok = await _run(() => widget.controller.addBatch(_item.id, {
          'quantity': qty,
          if (_newLotNo.text.trim().isNotEmpty) 'batchNo': _newLotNo.text.trim(),
          if (_newExpiry.isNotEmpty) 'expiryDate': _newExpiry,
          if (_newCost.text.trim().isNotEmpty && cost != null) 'unitCost': cost,
        }));
    if (!ok) return;
    setState(() {
      _addingLot = false;
      _newQty.clear();
      _newLotNo.clear();
      _newExpiry = '';
      _newCost.clear();
    });
    await Future.wait([_loadBatches(), _loadHistory()]);
  }

  Future<void> _correctLot(String batchId) async {
    final ok = await _run(() => widget.controller.updateBatch(_item.id, batchId, {
          'batchNo': _lotNo.text.trim().isEmpty ? null : _lotNo.text.trim(),
          'expiryDate': _lotExpiry.isEmpty ? null : _lotExpiry,
        }));
    if (!ok) return;
    setState(() => _editingLot = null);
    await _loadBatches();
  }

  Future<void> _linkSupplier() async {
    if (_supplierId.isEmpty) {
      AppSnackbar.show('Choose a supplier.', '');
      return;
    }
    final cost = num.tryParse(_supplierCost.text.trim());
    final ok = await _run(() => widget.controller.linkSupplier(_item.id, {
          'supplierId': _supplierId,
          if (_supplierSku.text.trim().isNotEmpty) 'supplierSku': _supplierSku.text.trim(),
          if (_supplierCost.text.trim().isNotEmpty && cost != null) 'unitCost': cost,
        }));
    if (!ok) return;
    setState(() {
      _addingSupplier = false;
      _supplierId = '';
      _supplierSku.clear();
      _supplierCost.clear();
    });
    await _loadSuppliers();
  }

  Future<void> _unlinkSupplier(String linkId) async {
    final ok = await _run(() => widget.controller.unlinkSupplier(_item.id, linkId));
    if (ok) await _loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return InventorySheet(
      icon: Icons.inventory_2_outlined,
      title: _item.name,
      description: '${InventoryLabels.qty(_item.quantity)} $_unit on hand · '
          '${_item.categoryName ?? '—'}'
          '${_item.reorderLevel != null ? ' · reorder at ${InventoryLabels.qty(_item.reorderLevel)}' : ''}',
      actions: [HandoverButton(label: 'Close', onPressed: () => Navigator.of(context).pop())],
      children: [
        _lots(c),
        _historySection(),
        _costSection(),
        _supplierSection(c),
      ],
    );
  }

  Widget _lots(InventoryStockController c) {
    final batches = _batches;
    return InventorySection(
      key: const ValueKey('inventory-detail-lots'),
      title: 'Lots and expiry',
      icon: Icons.event_busy_outlined,
      trailing: _item.tracksBatches && c.canMove && !_addingLot
          ? HandoverButton(
              key: const ValueKey('inventory-record-lot'),
              label: 'Record a lot',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: () => setState(() => _addingLot = true),
            )
          : null,
      children: [
        if (!_item.tracksBatches)
          const InventoryNote(
            "This item is not tracked in lots. Turn on batch tracking in the item's settings "
            'if its stock carries expiry dates.',
          )
        else if (batches == null)
          const InventoryNote('Loading…')
        else if (batches.isEmpty)
          const InventoryNote(
            'No lots on file. A batch-tracked item starts empty — its stock arrives as dated lots.',
          )
        else
          for (final b in batches) _lotRow(c, b),
        if (_addingLot) ...[
          const SizedBox(height: 8),
          InventoryField(
            key: const ValueKey('inventory-lot-qty'),
            label: 'How many',
            required: true,
            number: true,
            controller: _newQty,
          ),
          const SizedBox(height: 10),
          InventoryField(label: 'Lot number', controller: _newLotNo, placeholder: 'As printed'),
          const SizedBox(height: 10),
          InventoryDateField(
            label: 'Expires',
            value: _newExpiry,
            onChanged: (v) => setState(() => _newExpiry = v),
          ),
          const SizedBox(height: 10),
          InventoryField(label: 'Cost each', number: true, controller: _newCost),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              HandoverButton(label: 'Cancel', onPressed: () => setState(() => _addingLot = false)),
              HandoverButton(
                key: const ValueKey('inventory-lot-save'),
                label: 'Record lot',
                filled: true,
                onPressed: _busy ? null : _recordLot,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _lotRow(InventoryStockController c, InventoryBatch b) {
    final days = b.daysLeft(now: widget.now);
    final tone = days == null
        ? null
        : days < 0 || days <= 7
            ? AttendanceTone.danger
            : days <= 30
                ? AttendanceTone.warning
                : AttendanceTone.neutral;
    return InventoryRow(
      key: ValueKey('inventory-lot-${b.id}'),
      title: '${InventoryLabels.qty(b.quantity)} $_unit${b.batchNo != null ? ' · lot ${b.batchNo}' : ''}',
      subtitle: '${b.expiryDay != null ? 'Expires ${b.expiryDay}' : 'No expiry date'}'
          '${b.unitCost != null ? ' · cost ${InventoryLabels.qty(b.unitCost)}' : ''}',
      trailing: [
        if (days != null && tone != null)
          AttendancePill(label: days < 0 ? '${days.abs()}d past its date' : '${days}d left', tone: tone),
        if (c.canAdjust && _editingLot != b.id)
          InventoryIconButton(
            key: ValueKey('inventory-lot-edit-${b.id}'),
            icon: Icons.edit_outlined,
            tooltip: 'Correct the lot number or date',
            onPressed: () => setState(() {
              _editingLot = b.id;
              _lotNo.text = b.batchNo ?? '';
              _lotExpiry = b.expiryDay ?? '';
            }),
          ),
      ],
      below: _editingLot != b.id
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InventoryField(label: 'Lot number', controller: _lotNo),
                  const SizedBox(height: 10),
                  InventoryDateField(
                    label: 'Expires',
                    value: _lotExpiry,
                    helper: 'Blank means this lot is not dated.',
                    onChanged: (v) => setState(() => _lotExpiry = v),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      HandoverButton(label: 'Cancel', onPressed: () => setState(() => _editingLot = null)),
                      HandoverButton(
                        key: const ValueKey('inventory-lot-correct'),
                        label: 'Save',
                        filled: true,
                        onPressed: _busy ? null : () => _correctLot(b.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _historySection() {
    final history = _history;
    return InventorySection(
      key: const ValueKey('inventory-detail-history'),
      title: 'Stock history',
      icon: Icons.history_rounded,
      children: [
        if (history == null)
          const InventoryNote('Loading…')
        else if (history.isEmpty)
          const InventoryNote(
            'Nothing has moved yet. Every stock change appears here with the balance either side of it.',
          )
        else
          for (final m in history)
            InventoryRow(
              title: '${InventoryLabels.movement(m.type)}${m.reason != null ? ' · ${m.reason}' : ''}',
              subtitle: '${InventoryLabels.dateTime(m.createdAt)}'
                  '${m.performedByName != null ? ' · ${m.performedByName}' : ''}',
              trailing: [
                if (m.previousQty != null && m.newQty != null)
                  Text(
                    '${InventoryLabels.qty(m.previousQty)} → ${InventoryLabels.qty(m.newQty)}',
                    style: handoverText(context, 12, color: AppColors.textMuted),
                  ),
                AttendancePill(
                  label: '${m.changeQty >= 0 ? '+' : ''}${InventoryLabels.qty(m.changeQty)} $_unit',
                  tone: m.changeQty >= 0 ? AttendanceTone.success : AttendanceTone.warning,
                ),
              ],
            ),
      ],
    );
  }

  Widget _costSection() {
    final costs = _costs;
    final priced = [for (final e in costs ?? const <InventoryCostEntry>[]) if (e.unitCost != null) e];
    final change = priced.length >= 2 ? priced[0].unitCost! - priced[1].unitCost! : null;
    return InventorySection(
      key: const ValueKey('inventory-detail-cost'),
      title: 'What it has cost',
      icon: Icons.receipt_long_outlined,
      trailing: change != null && change != 0
          ? AttendancePill(
              label: '${change > 0 ? 'Up' : 'Down'} ${InventoryLabels.fixed2(change.abs())} since the delivery before',
              tone: change > 0 ? AttendanceTone.danger : AttendanceTone.success,
            )
          : null,
      children: [
        if (costs == null)
          const InventoryNote('Loading…')
        else if (costs.isEmpty)
          const InventoryNote(
            'Nothing bought through a purchase order yet. Prices appear here as orders are received.',
          )
        else
          for (final e in costs.take(_costShown))
            InventoryRow(
              title: e.supplierName ?? 'Supplier unknown',
              subtitle: '${e.reference ?? 'Order'}'
                  '${e.receivedAt != null ? ' · arrived ${InventoryLabels.day(e.receivedAt!)}' : e.orderedAt != null ? ' · ordered ${InventoryLabels.day(e.orderedAt!)}' : ''}'
                  ' · ${InventoryLabels.qty(e.receivedQuantity ?? e.quantity ?? 0)} ${e.unit ?? _unit}',
              trailing: [
                Text(
                  e.unitCost != null ? '${InventoryLabels.fixed2(e.unitCost!)} each' : 'Not priced',
                  style: handoverText(context, 12.5, weight: FontWeight.w500),
                ),
              ],
            ),
      ],
    );
  }

  Widget _supplierSection(InventoryStockController c) {
    final suppliers = _suppliers;
    return InventorySection(
      key: const ValueKey('inventory-detail-suppliers'),
      title: 'Who can supply this',
      icon: Icons.local_shipping_outlined,
      trailing: c.canWriteSuppliers && !_addingSupplier
          ? HandoverButton(
              key: const ValueKey('inventory-add-item-supplier'),
              label: 'Add a supplier',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: () => setState(() => _addingSupplier = true),
            )
          : null,
      children: [
        if (suppliers == null)
          const InventoryNote('Loading…')
        else if (suppliers.isEmpty)
          const InventoryNote(
            'Nobody is listed for this item yet. Adding suppliers here is what lets an order be '
            'priced, and gives somewhere to turn when the usual one is out of stock.',
          )
        else
          for (final s in suppliers)
            InventoryRow(
              key: ValueKey('inventory-item-supplier-${s.id}'),
              title: s.supplierName ?? 'Supplier',
              subtitle: '${s.unitCost != null ? '${InventoryLabels.qty(s.unitCost)} each' : 'No price on file'}'
                  '${s.supplierSku != null ? ' · their code ${s.supplierSku}' : ''}'
                  '${s.leadTimeDays != null ? ' · ${s.leadTimeDays}d lead' : ''}',
              trailing: [
                if (s.isPreferred) const AttendancePill(label: 'Preferred', tone: AttendanceTone.success),
                if (c.canWriteSuppliers)
                  InventoryIconButton(
                    key: ValueKey('inventory-item-supplier-remove-${s.id}'),
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _unlinkSupplier(s.id),
                  ),
              ],
            ),
        if (_addingSupplier) ...[
          const SizedBox(height: 8),
          InventorySelect(
            key: const ValueKey('inventory-item-supplier-pick'),
            label: 'Supplier',
            required: true,
            options: [
              for (final o in c.supplierOptionsFor(c.residenceId.value)) (o.value, o.label),
            ],
            value: _supplierId,
            placeholder: 'Who sells it',
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 10),
          InventoryField(
            label: 'Their code',
            controller: _supplierSku,
            placeholder: 'Ours means nothing to them',
          ),
          const SizedBox(height: 10),
          InventoryField(label: 'Price each', number: true, controller: _supplierCost),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              HandoverButton(label: 'Cancel', onPressed: () => setState(() => _addingSupplier = false)),
              HandoverButton(
                key: const ValueKey('inventory-item-supplier-save'),
                label: 'Add supplier',
                filled: true,
                onPressed: _busy ? null : _linkSupplier,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
