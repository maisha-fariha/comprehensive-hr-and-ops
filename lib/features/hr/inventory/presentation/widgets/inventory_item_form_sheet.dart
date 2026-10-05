import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../controllers/inventory_stock_controller.dart';
import 'inventory_common.dart';

/// Web "Add item" / "Edit {name}" modal.
Future<void> showInventoryItemForm(
  BuildContext context, {
  required InventoryStockController controller,
  InventoryItem? item,
}) =>
    showInventorySheet<void>(
      context,
      (_) => InventoryItemFormSheet(controller: controller, item: item),
    );

class InventoryItemFormSheet extends StatefulWidget {
  final InventoryStockController controller;
  final InventoryItem? item;

  const InventoryItemFormSheet({super.key, required this.controller, this.item});

  @override
  State<InventoryItemFormSheet> createState() => _InventoryItemFormSheetState();
}

class _InventoryItemFormSheetState extends State<InventoryItemFormSheet> {
  late String _residenceId;
  late String _categoryId;
  late String _unit;
  late String _supplier;
  late bool _tracksBatches;
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _quantity;
  late final TextEditingController _reorder;
  late final TextEditingController _remark;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _residenceId = item?.residenceId ?? widget.controller.residenceId.value ?? '';
    _categoryId = item?.categoryId ?? '';
    _unit = item?.unit ?? '';
    _supplier = item?.supplierName ?? '';
    _tracksBatches = item?.tracksBatches ?? false;
    _name = TextEditingController(text: item?.name ?? '');
    _sku = TextEditingController(text: item?.sku ?? '');
    _quantity = TextEditingController(text: '0');
    _reorder = TextEditingController(
      text: item?.reorderLevel == null ? '' : _plain(item!.reorderLevel!),
    );
    _remark = TextEditingController();
  }

  static String _plain(num v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _quantity.dispose();
    _reorder.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty || _categoryId.isEmpty) {
      setState(() => _error = 'A name and a category are required.');
      return;
    }
    if (!_editing && _residenceId.isEmpty) {
      setState(() => _error = 'Choose which residence holds this stock.');
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'categoryId': _categoryId,
      if (_unit.isNotEmpty) 'unit': _unit,
      if (_sku.text.trim().isNotEmpty) 'sku': _sku.text.trim(),
      if (_supplier.trim().isNotEmpty) 'supplierName': _supplier.trim(),
      'reorderLevel': _reorder.text.trim().isEmpty ? null : num.tryParse(_reorder.text.trim()),
      'tracksBatches': _tracksBatches,
    };
    final error = _editing
        ? await widget.controller.updateItem(widget.item!.id, body)
        : await widget.controller.createItem({
            ...body,
            'residenceId': _residenceId,
            'quantity': num.tryParse(_quantity.text.trim()) ?? 0,
            if (_remark.text.trim().isNotEmpty) 'remark': _remark.text.trim(),
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
      final suppliers = c.supplierNamesFor(_residenceId, current: _supplier);
      return InventorySheet(
        icon: Icons.inventory_2_outlined,
        title: _editing ? 'Edit ${widget.item!.name}' : 'Add item',
        description: 'Items belong to one residence and one category.',
        error: _error,
        actions: [
          HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          HandoverButton(
            key: const ValueKey('inventory-item-save'),
            label: _saving ? 'Saving…' : (_editing ? 'Save changes' : 'Add item'),
            filled: true,
            onPressed: _saving ? null : _save,
          ),
        ],
        children: [
          InventorySection(
            title: 'Item',
            children: [
              if (!_editing) ...[
                InventorySelect(
                  key: const ValueKey('inventory-item-residence'),
                  label: 'Residence',
                  required: true,
                  options: [for (final r in c.residences) (r.value, r.label)],
                  value: _residenceId,
                  placeholder: 'Where is this held',
                  onChanged: (v) => setState(() => _residenceId = v),
                ),
                const SizedBox(height: 12),
              ],
              InventoryField(
                key: const ValueKey('inventory-item-name'),
                label: 'Name',
                required: true,
                controller: _name,
                placeholder: 'Barrier cream, gloves, bin liners…',
              ),
              const SizedBox(height: 12),
              InventorySelect(
                key: const ValueKey('inventory-item-category'),
                label: 'Category',
                required: true,
                options: [for (final o in c.categoryOptions) (o.value, o.label)],
                value: _categoryId,
                placeholder: c.categoriesLoading.value ? 'Loading categories…' : 'Choose a category',
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              InventorySelect(
                label: 'Unit',
                options: [for (final o in c.unitOptions) (o.value, o.label)],
                value: _unit,
                placeholder: 'Choose a unit',
                onChanged: (v) => setState(() => _unit = v),
              ),
              const SizedBox(height: 12),
              InventoryField(label: 'SKU', controller: _sku, placeholder: 'Optional'),
            ],
          ),
          InventorySection(
            title: 'Stock',
            children: [
              if (!_editing)
                InventoryField(
                  key: const ValueKey('inventory-item-quantity'),
                  label: 'Opening quantity',
                  controller: _quantity,
                  number: true,
                  enabled: !_tracksBatches,
                  helper: _tracksBatches
                      ? 'A batch-tracked item starts empty — record its stock as dated lots once it exists.'
                      : 'How many are on the shelf right now',
                )
              else
                Text(
                  'Quantity is not edited here. Use Move, Recount or Loss on the item so the '
                  'change is recorded with a reason and an author.',
                  style: handoverText(context, 13, color: AppColors.textMuted),
                ),
              const SizedBox(height: 12),
              InventoryField(
                label: 'Reorder level',
                controller: _reorder,
                number: true,
                placeholder: 'Optional',
                helper: 'Flagged as low stock at or below this',
              ),
              const SizedBox(height: 12),
              InventoryCheckbox(
                key: const ValueKey('inventory-item-batches'),
                label: 'Arrives in batches with expiry dates',
                value: _tracksBatches,
                onChanged: (v) => setState(() {
                  _tracksBatches = v;
                  if (v) _quantity.text = '0';
                }),
              ),
              if (_tracksBatches) ...[
                const SizedBox(height: 6),
                Text(
                  'Each delivery is recorded as a lot with its own expiry date, and stock is '
                  'used oldest-first. Expiry warnings watch those dates.',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 12),
              InventorySelect(
                label: 'Supplier',
                options: [for (final s in suppliers) (s, s)],
                value: _supplier,
                placeholder: suppliers.isNotEmpty ? 'Optional' : 'No suppliers added yet',
                enabled: suppliers.isNotEmpty,
                helper: suppliers.isNotEmpty ? null : 'Add one under Purchasing → Suppliers first.',
                onChanged: (v) => setState(() => _supplier = v),
              ),
              if (!_editing) ...[
                const SizedBox(height: 12),
                HandoverTextArea(label: 'Remark', controller: _remark, placeholder: 'Optional'),
              ],
            ],
          ),
        ],
      );
    });
  }
}
