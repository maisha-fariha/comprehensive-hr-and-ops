import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/purchasing.dart';
import '../controllers/purchasing_controller.dart';
import '../inventory_labels.dart';
import 'inventory_common.dart';

/// Web "Book in the delivery" modal.
Future<void> showReceiveOrderSheet(
  BuildContext context, {
  required PurchasingController controller,
  required PurchaseOrder order,
}) =>
    showInventorySheet<void>(
      context,
      (_) => ReceiveOrderSheet(controller: controller, order: order),
    );

class _Arrival {
  final TextEditingController arrived;
  final TextEditingController batchNo = TextEditingController();
  String expiryDate = '';

  _Arrival(String value) : arrived = TextEditingController(text: value);

  void dispose() {
    arrived.dispose();
    batchNo.dispose();
  }
}

class ReceiveOrderSheet extends StatefulWidget {
  final PurchasingController controller;
  final PurchaseOrder order;

  const ReceiveOrderSheet({super.key, required this.controller, required this.order});

  @override
  State<ReceiveOrderSheet> createState() => _ReceiveOrderSheetState();
}

class _ReceiveOrderSheetState extends State<ReceiveOrderSheet> {
  late final Map<String, _Arrival> _arrivals;
  final _notes = TextEditingController();
  String? _error;
  bool _saving = false;

  static num _ordered(PurchaseOrderLine l) => l.quantity ?? 0;
  static num _already(PurchaseOrderLine l) => l.receivedQuantity ?? 0;
  static num _outstanding(PurchaseOrderLine l) {
    final left = _ordered(l) - _already(l);
    return left > 0 ? left : 0;
  }

  @override
  void initState() {
    super.initState();
    _arrivals = {
      for (final l in widget.order.items)
        l.id: _Arrival(_outstanding(l) > 0 ? InventoryLabels.qty(_outstanding(l)) : '0'),
    };
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final a in _arrivals.values) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _book() async {
    setState(() => _error = null);
    final items = <Map<String, dynamic>>[];
    for (final line in widget.order.items) {
      final entry = _arrivals[line.id]!;
      final value = num.tryParse(entry.arrived.text.trim()) ?? 0;
      if (!value.isFinite || value <= 0) continue;
      final outstanding = _outstanding(line);
      if (value > outstanding) {
        setState(() => _error = 'More ${line.description ?? 'of one product'} arrived than was '
            'outstanding (${InventoryLabels.qty(outstanding)}).');
        return;
      }
      items.add({
        'itemId': line.id,
        'receivedQuantity': value,
        if (entry.batchNo.text.trim().isNotEmpty) 'batchNo': entry.batchNo.text.trim(),
        if (entry.expiryDate.isNotEmpty) 'expiryDate': entry.expiryDate,
      });
    }
    if (items.isEmpty) {
      setState(() => _error = 'Enter how much arrived for at least one product.');
      return;
    }
    setState(() => _saving = true);
    final notes = _notes.text.trim();
    final error = await widget.controller.receive(widget.order.id, {
      'items': items,
      if (notes.isNotEmpty) 'notes': notes,
    });
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final anyOutstanding = order.items.any((l) => _outstanding(l) > 0);
    return InventorySheet(
      icon: Icons.inventory_outlined,
      title: 'Book in the delivery',
      description: '${order.reference ?? 'This order'} — enter what actually turned up. Stock goes '
          'up by what you enter here, not by what was ordered.',
      error: _error,
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('order-receive-save'),
          label: _saving ? 'Booking in…' : 'Book in',
          filled: true,
          onPressed: _saving || !anyOutstanding ? null : _book,
        ),
      ],
      children: [
        if (!anyOutstanding) ...[
          const InventoryNote('Everything on this order has already been booked in.'),
          const SizedBox(height: 12),
        ],
        for (final line in order.items) _line(line),
        const SizedBox(height: 4),
        HandoverTextArea(
          label: 'Note about this delivery',
          controller: _notes,
          placeholder: 'Two boxes crushed, driver took them back…',
        ),
      ],
    );
  }

  Widget _line(PurchaseOrderLine line) {
    final entry = _arrivals[line.id]!;
    final outstanding = _outstanding(line);
    final already = _already(line);
    final closed = outstanding == 0;
    final batches = line.inventoryItem?.tracksBatches ?? false;
    return InventoryRow(
      key: ValueKey('order-receive-line-${line.id}'),
      title: line.description ?? 'Product',
      subtitle: '${InventoryLabels.qty(_ordered(line))} ordered'
          '${already > 0 ? ' · ${InventoryLabels.qty(already)} already in' : ''}'
          ' · ${InventoryLabels.qty(outstanding)} still to come'
          '${line.unit != null ? ' (${line.unit})' : ''}',
      trailing: [
        line.inventoryItem != null
            ? AttendancePill(
                label: 'Restocks ${line.inventoryItem!.name}',
                tone: AttendanceTone.success,
              )
            : const AttendancePill(label: 'One-off — no stock change', tone: AttendanceTone.neutral),
      ],
      below: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventoryField(
              key: ValueKey('order-receive-qty-${line.id}'),
              label: 'Arrived now',
              number: true,
              enabled: !closed,
              controller: entry.arrived,
            ),
            if (batches) ...[
              const SizedBox(height: 10),
              InventoryField(
                label: 'Batch number',
                placeholder: 'As printed on the box',
                enabled: !closed,
                controller: entry.batchNo,
              ),
              const SizedBox(height: 10),
              InventoryDateField(
                label: 'Expiry date',
                value: entry.expiryDate,
                enabled: !closed,
                helper: 'This is what the expiry warnings watch.',
                onChanged: (v) => setState(() => entry.expiryDate = v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Web "Reject order" modal.
Future<void> showRejectOrderSheet(
  BuildContext context, {
  required PurchasingController controller,
  required PurchaseOrder order,
}) =>
    showInventorySheet<void>(
      context,
      (_) => RejectOrderSheet(controller: controller, order: order),
    );

class RejectOrderSheet extends StatefulWidget {
  final PurchasingController controller;
  final PurchaseOrder order;

  const RejectOrderSheet({super.key, required this.controller, required this.order});

  @override
  State<RejectOrderSheet> createState() => _RejectOrderSheetState();
}

class _RejectOrderSheetState extends State<RejectOrderSheet> {
  final _reason = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reject() async {
    setState(() => _error = null);
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Say why this order is rejected.');
      return;
    }
    setState(() => _saving = true);
    final error = await widget.controller.reject(widget.order, _reason.text.trim());
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => InventorySheet(
        icon: Icons.local_shipping_outlined,
        title: 'Reject order',
        description: widget.order.supplierName != null ? 'From ${widget.order.supplierName}' : null,
        error: _error,
        actions: [
          HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          HandoverButton(
            key: const ValueKey('order-reject-save'),
            label: _saving ? 'Rejecting…' : 'Reject order',
            filled: true,
            onPressed: _saving ? null : _reject,
          ),
        ],
        children: [
          HandoverTextArea(
            key: const ValueKey('order-reject-reason'),
            label: 'Why is this rejected',
            required: true,
            controller: _reason,
            placeholder: 'Too expensive, wrong supplier, not needed…',
          ),
        ],
      );
}

/// Web "Add supplier" modal.
Future<void> showAddSupplierSheet(
  BuildContext context, {
  required PurchasingController controller,
}) =>
    showInventorySheet<void>(context, (_) => AddSupplierSheet(controller: controller));

class AddSupplierSheet extends StatefulWidget {
  final PurchasingController controller;

  const AddSupplierSheet({super.key, required this.controller});

  @override
  State<AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<AddSupplierSheet> {
  final _name = TextEditingController();
  String _category = 'general';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'A name is required.');
      return;
    }
    setState(() => _saving = true);
    final error = await widget.controller.addSupplier(_name.text.trim(), _category);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => InventorySheet(
        icon: Icons.local_shipping_outlined,
        title: 'Add supplier',
        error: _error,
        actions: [
          HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          HandoverButton(
            key: const ValueKey('supplier-add-save'),
            label: _saving ? 'Adding…' : 'Add supplier',
            filled: true,
            onPressed: _saving ? null : _add,
          ),
        ],
        children: [
          InventoryField(
            key: const ValueKey('supplier-add-name'),
            label: 'Name',
            required: true,
            controller: _name,
          ),
          const SizedBox(height: 12),
          InventorySelect(
            label: 'Category',
            options: InventoryLabels.supplierCategories,
            value: _category,
            placeholder: '',
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 10),
          Text(
            'Contact details can be filled in once the supplier exists.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
        ],
      );
}
