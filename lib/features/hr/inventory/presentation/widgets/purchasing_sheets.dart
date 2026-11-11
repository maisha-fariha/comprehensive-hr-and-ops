import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/json_codec.dart';
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

/// Web "Add supplier" / "Edit supplier" modal.
Future<void> showAddSupplierSheet(
  BuildContext context, {
  required PurchasingController controller,
  InventorySupplier? supplier,
}) =>
    showInventorySheet<void>(
      context,
      (_) => AddSupplierSheet(controller: controller, supplier: supplier),
    );

class AddSupplierSheet extends StatefulWidget {
  final PurchasingController controller;
  final InventorySupplier? supplier;

  const AddSupplierSheet({super.key, required this.controller, this.supplier});

  @override
  State<AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<AddSupplierSheet> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _contact;
  late final TextEditingController _address;
  late final TextEditingController _accountRef;
  late final TextEditingController _notes;
  late String _category;
  late String _residenceId;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _name = TextEditingController(text: s?.name ?? '');
    _email = TextEditingController(text: s?.email ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _contact = TextEditingController(text: s?.contactName ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _accountRef = TextEditingController(text: s?.accountRef ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
    _category = s?.category?.isNotEmpty == true ? s!.category! : 'general';
    _residenceId = s?.residenceId ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _contact.dispose();
    _address.dispose();
    _accountRef.dispose();
    _notes.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _body {
    final residence = _residenceId.trim();
    return {
      'name': _name.text.trim(),
      'category': _category,
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'contactName': _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'accountRef': _accountRef.text.trim().isEmpty ? null : _accountRef.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      // Web: include residenceId when set; on edit, clear with null.
      if (residence.isNotEmpty)
        'residenceId': residence
      else if (_editing)
        'residenceId': null,
    };
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'A name is required.');
      return;
    }
    if (_email.text.trim().isEmpty && _phone.text.trim().isEmpty) {
      setState(() => _error = 'Give an email or a phone number to reach this supplier by');
      return;
    }
    setState(() => _saving = true);
    final error = _editing
        ? await widget.controller.updateSupplier(widget.supplier!.id, _body)
        : await widget.controller.addSupplier(_body);
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
        title: _editing ? 'Edit supplier' : 'Add supplier',
        description: 'Orders are emailed to the supplier\'s address, or placed by phone.',
        error: _error,
        actions: [
          HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          HandoverButton(
            key: const ValueKey('supplier-add-save'),
            label: _saving
                ? (_editing ? 'Saving…' : 'Adding…')
                : (_editing ? 'Save changes' : 'Add supplier'),
            filled: true,
            onPressed: _saving ? null : _save,
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
            key: const ValueKey('supplier-add-category'),
            label: 'Category',
            options: InventoryLabels.supplierCategories,
            value: _category,
            placeholder: '',
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          InventoryField(
            key: const ValueKey('supplier-add-email'),
            label: 'Email',
            controller: _email,
            placeholder: 'orders@supplier.com',
            helper: 'Purchase orders are emailed here.',
          ),
          const SizedBox(height: 12),
          InventoryField(
            key: const ValueKey('supplier-add-phone'),
            label: 'Phone',
            controller: _phone,
            helper: 'An email or a phone is required.',
          ),
          const SizedBox(height: 12),
          InventoryField(
            key: const ValueKey('supplier-add-contact'),
            label: 'Contact person',
            controller: _contact,
          ),
          const SizedBox(height: 12),
          HandoverTextArea(
            key: const ValueKey('supplier-add-address'),
            label: 'Address',
            controller: _address,
          ),
          const SizedBox(height: 12),
          InventoryField(
            key: const ValueKey('supplier-add-account-ref'),
            label: 'Our account number with them',
            controller: _accountRef,
            helper: 'Printed on purchase orders, so the supplier can match them.',
          ),
          const SizedBox(height: 12),
          InventorySelect(
            key: const ValueKey('supplier-add-home'),
            label: 'Home',
            options: [
              ('', 'Every home'),
              for (final r in widget.controller.residences) (r.value, r.label),
            ],
            value: _residenceId,
            placeholder: 'Select the home this supplier serves',
            helper:
                'Leave empty for a supplier every home uses — only if you work across every home.',
            onChanged: (v) => setState(() => _residenceId = v),
          ),
          const SizedBox(height: 12),
          HandoverTextArea(
            key: const ValueKey('supplier-add-notes'),
            label: 'Notes',
            controller: _notes,
          ),
        ],
      );
}

/// Web "View" purchase order — read-only details.
Future<void> showPurchaseOrderViewSheet(
  BuildContext context, {
  required PurchasingController controller,
  required PurchaseOrder order,
}) =>
    showInventorySheet<void>(
      context,
      (_) => PurchaseOrderViewSheet(controller: controller, order: order),
    );

class PurchaseOrderViewSheet extends StatefulWidget {
  final PurchasingController controller;
  final PurchaseOrder order;

  const PurchaseOrderViewSheet({
    super.key,
    required this.controller,
    required this.order,
  });

  @override
  State<PurchaseOrderViewSheet> createState() => _PurchaseOrderViewSheetState();
}

class _PurchaseOrderViewSheetState extends State<PurchaseOrderViewSheet> {
  late PurchaseOrder _order = widget.order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.controller.loadOrder(widget.order.id);
    if (!mounted) return;
    result.when(
      success: (order) => setState(() {
        _order = order;
        _loading = false;
        _error = null;
      }),
      failure: (error) => setState(() {
        _loading = false;
        _error = error.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final total = order.total;
    final lineCount = order.items.length;
    final arrivedRatio = order.orderedUnits <= 0
        ? 0.0
        : (order.receivedUnits / order.orderedUnits).clamp(0.0, 1.0);
    final expectedAt = JsonCodec.dateTime(order.expectedAt);
    final expected =
        expectedAt == null ? null : InventoryLabels.date(expectedAt);
    return InventorySheet(
      icon: Icons.receipt_long_outlined,
      title: 'Purchase Order: ${order.displayReference}',
      description: [
        InventoryLabels.humanise(order.status),
        if (order.createdAt != null) 'Created on ${InventoryLabels.date(order.createdAt)}',
      ].join(' · '),
      error: _error,
      actions: [
        HandoverButton(
          key: ValueKey('order-view-close-${order.id}'),
          label: 'Close',
          filled: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal)),
          )
        else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ViewFact(
                label: 'Supplier',
                title: order.supplierName ?? 'No supplier',
                lines: [
                  if (order.supplierEmail != null && order.supplierEmail!.trim().isNotEmpty)
                    order.supplierEmail!,
                  if (order.supplierPhone != null && order.supplierPhone!.trim().isNotEmpty)
                    order.supplierPhone!,
                ],
              ),
              _ViewFact(
                label: 'Delivering to',
                title: order.residenceName ?? '—',
                lines: const ['Destination inventory'],
              ),
              _ViewFact(
                label: 'Fulfillment',
                title:
                    '${InventoryLabels.qty(order.receivedUnits)} of ${InventoryLabels.qty(order.orderedUnits)} items arrived',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: arrivedRatio,
                    minHeight: 6,
                    backgroundColor: AppColors.cardBorder,
                    color: arrivedRatio >= 1
                        ? AppColors.activeGreen
                        : AppColors.secondaryTeal,
                  ),
                ),
              ),
              _ViewFact(
                label: 'Total value',
                title: total == null ? 'Not priced' : InventoryLabels.money(total),
                lines: [
                  '$lineCount line product${lineCount == 1 ? '' : 's'}',
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.urgentAmber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.sendStatusLabel,
                  style: handoverText(context, 12.5, color: AppColors.urgentAmber),
                ),
              ),
              if (expected != null && expected != '—') ...[
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Expected: $expected',
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Notes', style: handoverText(context, 12, color: AppColors.textMuted)),
            Text(order.notes!, style: handoverText(context, 13)),
          ],
          const SizedBox(height: 16),
          Text(
            'Ordered items',
            style: handoverText(context, 13.5, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (order.items.isEmpty)
            Text(
              'No products on this order.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            )
          else ...[
            for (final line in order.items) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.inventoryItem?.name ?? line.description ?? 'Item',
                      style: handoverText(context, 13.5, weight: FontWeight.w600),
                    ),
                    if ((line.unit ?? line.inventoryItem?.unit)?.trim().isNotEmpty ==
                        true)
                      Text(
                        'Unit: ${line.unit ?? line.inventoryItem?.unit}',
                        style: handoverText(context, 12, color: AppColors.textMuted),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _miniStat(context, 'Ordered', InventoryLabels.qty(line.quantity ?? 0)),
                        _miniStat(
                          context,
                          'Arrived',
                          '${InventoryLabels.qty(line.receivedQuantity ?? 0)} of ${InventoryLabels.qty(line.quantity ?? 0)}',
                        ),
                        _miniStat(
                          context,
                          'Unit cost',
                          line.unitCost == null
                              ? '—'
                              : InventoryLabels.money(line.unitCost!),
                        ),
                        _miniStat(
                          context,
                          'Line total',
                          line.lineTotal == null
                              ? '—'
                              : InventoryLabels.money(line.lineTotal!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Ordered ${InventoryLabels.qty(order.orderedUnits)} · Arrived ${InventoryLabels.qty(order.receivedUnits)}${total == null ? '' : ' · Subtotal ${InventoryLabels.money(total)}'}',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ],
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: handoverText(context, 11, color: AppColors.textMuted)),
        Text(value, style: handoverText(context, 12.5, weight: FontWeight.w600)),
      ],
    );
  }
}

class _ViewFact extends StatelessWidget {
  final String label;
  final String title;
  final List<String> lines;
  final Widget? child;

  const _ViewFact({
    required this.label,
    required this.title,
    this.lines = const [],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: handoverText(context, 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(title, style: handoverText(context, 13.5, weight: FontWeight.w600)),
            for (final line in lines) ...[
              const SizedBox(height: 2),
              Text(line, style: handoverText(context, 12, color: AppColors.textMuted)),
            ],
            if (child != null) ...[
              const SizedBox(height: 8),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Web "Send to supplier" modal after Submit / Resend.
Future<void> showSendOrderSheet(
  BuildContext context, {
  required PurchasingController controller,
  required PurchaseOrder order,
}) =>
    showInventorySheet<void>(
      context,
      (_) => SendOrderSheet(controller: controller, order: order),
    );

class SendOrderSheet extends StatefulWidget {
  final PurchasingController controller;
  final PurchaseOrder order;

  const SendOrderSheet({super.key, required this.controller, required this.order});

  @override
  State<SendOrderSheet> createState() => _SendOrderSheetState();
}

class _SendOrderSheetState extends State<SendOrderSheet> {
  /// Web options: `email` | `manual`.
  String _via = 'email';
  final _message = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    final error = await widget.controller.sendOrder(
      widget.order,
      via: _via,
      message: _message.text,
    );
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
    final email = widget.order.supplierEmail?.trim();
    final canEmail = email != null && email.isNotEmpty;
    final primaryLabel = _via == 'email'
        ? (_saving ? 'Emailing…' : 'Email the order')
        : (_saving ? 'Saving…' : 'Mark as placed');
    return InventorySheet(
      icon: Icons.send_outlined,
      title: 'Send to supplier',
      description:
          '${widget.order.displayReference}${widget.order.supplierName == null ? '' : ' · ${widget.order.supplierName}'}',
      error: _error,
      actions: [
        HandoverButton(
          key: const ValueKey('order-send-not-now'),
          label: 'Not now',
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        HandoverButton(
          key: const ValueKey('order-send-confirm'),
          label: primaryLabel,
          filled: true,
          onPressed: _saving || (_via == 'email' && !canEmail) ? null : _send,
        ),
      ],
      children: [
        _SendViaCard(
          selected: _via == 'email',
          icon: Icons.mail_outline,
          title: 'Email it to the supplier',
          subtitle: canEmail
              ? 'The order goes to $email as a PDF. Their reply comes to you.'
              : 'This supplier has no email on file.',
          onTap: canEmail ? () => setState(() => _via = 'email') : null,
        ),
        const SizedBox(height: 8),
        _SendViaCard(
          selected: _via == 'manual',
          icon: Icons.phone_outlined,
          title: 'I placed it by phone or on their website',
          subtitle: 'Nothing is sent. The order is marked as placed, so everyone can see it went.',
          onTap: () => setState(() => _via = 'manual'),
        ),
        const SizedBox(height: 12),
        HandoverTextArea(
          key: const ValueKey('order-send-message'),
          label: 'Message to the supplier (optional)',
          controller: _message,
          placeholder: 'Deliveries before noon, please.',
        ),
      ],
    );
  }
}

class _SendViaCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SendViaCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.activeBackground : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.secondaryTeal : AppColors.cardBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.secondaryTeal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: handoverText(context, 13.5, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: handoverText(context, 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
