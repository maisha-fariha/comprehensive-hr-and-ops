import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchasing.dart';
import '../controllers/purchasing_controller.dart';
import '../inventory_labels.dart';
import 'inventory_common.dart';

/// Web "New purchase order" / "Edit {reference}" modal.
Future<void> showPurchaseOrderForm(
  BuildContext context, {
  required PurchasingController controller,
  PurchaseOrder? order,
}) =>
    showInventorySheet<void>(
      context,
      (_) => PurchaseOrderFormSheet(controller: controller, order: order),
    );

/// The stock item a draft line restocks.
class _LineItem {
  final String id;
  final String name;
  final String? unit;
  final String? supplierName;
  final num? lastUnitCost;

  const _LineItem({
    required this.id,
    required this.name,
    this.unit,
    this.supplierName,
    this.lastUnitCost,
  });
}

class _DraftLine {
  final String key;
  _LineItem? item;
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController unitCost;

  _DraftLine(
    this.key, {
    this.item,
    String description = '',
    String quantity = '1',
    String unit = '',
    String unitCost = '',
  })  : description = TextEditingController(text: description),
        quantity = TextEditingController(text: quantity),
        unit = TextEditingController(text: unit),
        unitCost = TextEditingController(text: unitCost);

  /// Web `K`: quantity × price, zero unless both are numbers.
  num get lineTotal {
    final q = num.tryParse(quantity.text.trim());
    final c = num.tryParse(unitCost.text.trim());
    return q != null && c != null ? q * c : 0;
  }

  void dispose() {
    description.dispose();
    quantity.dispose();
    unit.dispose();
    unitCost.dispose();
  }
}

class PurchaseOrderFormSheet extends StatefulWidget {
  final PurchasingController controller;
  final PurchaseOrder? order;

  const PurchaseOrderFormSheet({super.key, required this.controller, this.order});

  @override
  State<PurchaseOrderFormSheet> createState() => _PurchaseOrderFormSheetState();
}

class _PurchaseOrderFormSheetState extends State<PurchaseOrderFormSheet> {
  late String _residenceId;
  late String _supplierId;
  late String _expected;
  late final TextEditingController _notes;
  late List<_DraftLine> _lines;
  int _nextKey = 0;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.order != null;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _residenceId = order?.residenceId ?? '';
    _supplierId = order?.supplierId ?? '';
    _expected = order?.expectedAt == null ? '' : InventoryLabels.day(order!.expectedAt!);
    _notes = TextEditingController(text: order?.notes ?? '');
    _lines = order != null && order.items.isNotEmpty
        ? [
            for (final l in order.items)
              _DraftLine(
                l.id,
                item: l.inventoryItem == null
                    ? null
                    : _LineItem(
                        id: l.inventoryItem!.id,
                        name: l.inventoryItem!.name,
                        unit: l.inventoryItem!.unit,
                      ),
                description: l.description ?? l.inventoryItem?.name ?? '',
                quantity: l.quantity == null ? '1' : InventoryLabels.qty(l.quantity),
                unit: l.unit ?? '',
                unitCost: l.unitCost == null ? '' : InventoryLabels.qty(l.unitCost),
              ),
          ]
        : [_newLine()];
  }

  _DraftLine _newLine() => _DraftLine('new-${_nextKey++}');

  @override
  void dispose() {
    _notes.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _disposeLater(List<_DraftLine> lines) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final l in lines) {
        l.dispose();
      }
    });
  }

  void _chooseResidence(String value) {
    final dropped = _lines;
    setState(() {
      _residenceId = value;
      _supplierId = '';
      _lines = [_newLine()];
    });
    _disposeLater(dropped);
  }

  Future<void> _pickItem(_DraftLine line) async {
    final picked = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockPicker(
        controller: widget.controller,
        residenceId: _residenceId,
        selectedId: line.item?.id,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      line.item = _LineItem(
        id: picked.id,
        name: picked.name,
        unit: picked.unit,
        supplierName: picked.supplierName,
        lastUnitCost: picked.lastUnitCost,
      );
      line.description.text = picked.name;
      line.unit.text = picked.unit ?? '';
      final cost = picked.lastUnitCost ?? picked.averageUnitCost;
      line.unitCost.text = cost == null ? '' : InventoryLabels.qty(cost);
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_residenceId.isEmpty) {
      setState(() => _error = 'Choose which house this is for.');
      return;
    }
    final filled = [for (final l in _lines) if (l.description.text.trim().isNotEmpty) l];
    if (filled.isEmpty) {
      setState(() => _error = 'Add at least one product.');
      return;
    }
    for (final l in filled) {
      final q = num.tryParse(l.quantity.text.trim());
      if (q == null || q <= 0) {
        setState(() => _error = 'How many ${l.description.text.trim()}? It has to be more than zero.');
        return;
      }
    }
    final items = [
      for (final l in filled)
        {
          if (l.item != null) 'inventoryItemId': l.item!.id,
          'description': l.description.text.trim(),
          'quantity': num.parse(l.quantity.text.trim()),
          if (l.unit.text.trim().isNotEmpty) 'unit': l.unit.text.trim(),
          'unitCost': ?num.tryParse(l.unitCost.text.trim()),
        },
    ];
    setState(() => _saving = true);
    final notes = _notes.text.trim();
    final error = _editing
        ? await widget.controller.updateOrder(widget.order!.id, {
            'supplierId': _supplierId.isEmpty ? null : _supplierId,
            'expectedAt': _expected.isEmpty ? null : _expected,
            'notes': notes.isEmpty ? null : notes,
            'items': items,
          })
        : await widget.controller.createOrder({
            'residenceId': _residenceId,
            if (_supplierId.isNotEmpty) 'supplierId': _supplierId,
            if (_expected.isNotEmpty) 'expectedAt': _expected,
            if (notes.isNotEmpty) 'notes': notes,
            'items': items,
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
    final c = widget.controller;
    return Obx(() {
      final suppliers = [for (final o in c.supplierOptionsFor(_residenceId)) (o.value, o.label)];
      final supplierLabel = suppliers.where((s) => s.$1 == _supplierId).map((s) => s.$2).firstOrNull ?? '';
      final total = _lines.fold<num>(0, (sum, l) => sum + l.lineTotal);
      final priced = _lines.any((l) => l.unitCost.text.trim().isNotEmpty);
      final named = _lines.where((l) => l.description.text.trim().isNotEmpty).length;
      return InventorySheet(
        icon: Icons.local_shipping_outlined,
        title: _editing ? 'Edit ${widget.order!.reference ?? 'draft'}' : 'New purchase order',
        description: _editing
            ? 'Still a draft, so everything here can be changed. Submitting is what sends it.'
            : 'Starts as a draft. Nothing is sent until you submit it, and everything here can be '
                'changed until then.',
        error: _error,
        footerLeft: Text(
          '$named product${named == 1 ? '' : 's'}${priced ? ' · ${InventoryLabels.money(total)}' : ''}',
          key: const ValueKey('order-footer'),
          style: handoverText(context, 12.5, color: AppColors.textMuted),
        ),
        actions: [
          HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          HandoverButton(
            key: const ValueKey('order-save'),
            label: _saving
                ? (_editing ? 'Saving…' : 'Creating…')
                : (_editing ? 'Save changes' : 'Create draft'),
            filled: true,
            onPressed: _saving ? null : _save,
          ),
        ],
        children: [
          InventorySelect(
            key: const ValueKey('order-residence'),
            label: 'For which house',
            required: true,
            enabled: !_editing,
            options: [for (final r in c.residences) (r.value, r.label)],
            value: _residenceId,
            placeholder: 'Where it is going',
            onChanged: _chooseResidence,
          ),
          const SizedBox(height: 12),
          InventorySelect(
            key: const ValueKey('order-supplier'),
            label: 'Supplier',
            options: suppliers,
            value: _supplierId,
            enabled: suppliers.isNotEmpty,
            placeholder: suppliers.isNotEmpty ? 'Who is it from' : 'No suppliers for this house',
            helper: 'Needed before the order can be sent.',
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 12),
          InventoryDateField(
            label: 'Expected',
            value: _expected,
            helper: 'When you are told it will arrive.',
            onChanged: (v) => setState(() => _expected = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'What are you ordering',
                  style: handoverText(context, 14, weight: FontWeight.w600),
                ),
              ),
              if (priced)
                Text(
                  'Order total ${InventoryLabels.money(total)}',
                  key: const ValueKey('order-total'),
                  style: handoverText(context, 12.5, weight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _lines.length; i++) _line(_lines[i], i, supplierLabel),
          Align(
            alignment: Alignment.centerLeft,
            child: HandoverButton(
              key: const ValueKey('order-add-line'),
              label: 'Add another product',
              icon: Icons.add_rounded,
              onPressed: () => setState(() => _lines.add(_newLine())),
            ),
          ),
          const SizedBox(height: 12),
          HandoverTextArea(
            label: 'Note for the supplier',
            controller: _notes,
            placeholder: 'Deliver to the back entrance before noon…',
          ),
        ],
      );
    });
  }

  Widget _line(_DraftLine line, int index, String supplierLabel) {
    final item = line.item;
    final usual = item?.supplierName;
    final mismatch = usual != null &&
        supplierLabel.isNotEmpty &&
        usual.trim().toLowerCase() != supplierLabel.trim().toLowerCase();
    final hasCost = line.unitCost.text.trim().isNotEmpty;
    return Container(
      key: ValueKey('order-line-$index'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Product ${index + 1}',
                  style: handoverText(context, 12.5, weight: FontWeight.w600),
                ),
              ),
              if (_lines.length > 1)
                InventoryIconButton(
                  key: ValueKey('order-line-remove-$index'),
                  icon: Icons.delete_outline_rounded,
                  onPressed: () {
                    setState(() => _lines.remove(line));
                    _disposeLater([line]);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text("From this house's stock", style: handoverText(context, 13, weight: FontWeight.w500)),
          const SizedBox(height: 6),
          Opacity(
            opacity: _residenceId.isEmpty ? 0.6 : 1,
            child: InkWell(
              key: ValueKey('order-line-pick-$index'),
              onTap: _residenceId.isEmpty ? null : () => _pickItem(line),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.searchBorder),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.manage_search_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item?.name ??
                            (_residenceId.isEmpty ? 'Choose a house first' : "Search this house's stock…"),
                        style: handoverText(
                          context,
                          13.5,
                          color: item != null ? AppColors.textHeading : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item != null
                ? "The delivery will be added to this item's stock."
                : 'Pick one so the delivery restocks the shelf. Leave it for a one-off purchase.',
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          if (mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Usually bought from $usual. This order goes to $supplierLabel.',
                style: handoverText(context, 12, color: AppColors.urgentAmber),
              ),
            ),
          const SizedBox(height: 10),
          InventoryField(
            key: ValueKey('order-line-description-$index'),
            label: 'Description',
            required: true,
            controller: line.description,
            placeholder: 'Gloves, size M',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InventoryField(
                  key: ValueKey('order-line-qty-$index'),
                  label: 'How many',
                  required: true,
                  number: true,
                  controller: line.quantity,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InventoryField(
                  label: 'Unit',
                  controller: line.unit,
                  placeholder: 'box, pack',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InventoryField(
            key: ValueKey('order-line-cost-$index'),
            label: 'Price each',
            number: true,
            controller: line.unitCost,
            helper: item?.lastUnitCost != null
                ? 'Last paid ${InventoryLabels.money(item!.lastUnitCost!)}'
                : 'Optional',
            onChanged: (_) => setState(() {}),
          ),
          if (hasCost)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${line.quantity.text.isEmpty ? '0' : line.quantity.text} × ${line.unitCost.text} = '
                '${InventoryLabels.money(line.lineTotal)}',
                style: handoverText(context, 12.5, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Web stock combobox: searches the chosen house's shelf.
class _StockPicker extends StatefulWidget {
  final PurchasingController controller;
  final String residenceId;
  final String? selectedId;

  const _StockPicker({required this.controller, required this.residenceId, this.selectedId});

  @override
  State<_StockPicker> createState() => _StockPickerState();
}

class _StockPickerState extends State<_StockPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<InventoryItem> _items = const [];
  bool _loading = true;
  int _serial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final serial = ++_serial;
    setState(() => _loading = true);
    final result = await widget.controller.searchStock(widget.residenceId, _search.text);
    if (!mounted || serial != _serial) return;
    setState(() {
      _loading = false;
      _items = result.when(success: (v) => v, failure: (_) => const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.75),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: InventoryField(
                  key: const ValueKey('order-stock-search'),
                  controller: _search,
                  placeholder: 'Search by name or code…',
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), _load);
                  },
                ),
              ),
              Flexible(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: InventoryNote('Looking…'),
                      )
                    : _items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: InventoryNote(
                              'Nothing on this shelf matches. You can still type it in as a one-off purchase.',
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final item in _items)
                                ListTile(
                                  key: ValueKey('order-stock-option-${item.id}'),
                                  leading: Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: item.id == widget.selectedId
                                        ? AppColors.secondaryTeal
                                        : Colors.transparent,
                                  ),
                                  title: Text(item.name, style: handoverText(context, 14)),
                                  subtitle: Text(
                                    '${InventoryLabels.qty(item.quantity)} ${item.unit ?? ''} on hand'
                                    '${item.sku != null ? ' · ${item.sku}' : ''}',
                                    style: handoverText(context, 12, color: AppColors.textMuted),
                                  ),
                                  onTap: () => Navigator.of(context).pop(item),
                                ),
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
