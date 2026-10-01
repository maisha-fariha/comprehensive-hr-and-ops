import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../controllers/inventory_stock_controller.dart';
import 'inventory_common.dart';

/// Web "Categories and units" modal.
Future<void> showInventoryCatalogueSheet(
  BuildContext context, {
  required InventoryStockController controller,
}) =>
    showInventorySheet<void>(context, (_) => InventoryCatalogueSheet(controller: controller));

class InventoryCatalogueSheet extends StatefulWidget {
  final InventoryStockController controller;

  const InventoryCatalogueSheet({super.key, required this.controller});

  @override
  State<InventoryCatalogueSheet> createState() => _InventoryCatalogueSheetState();
}

class _InventoryCatalogueSheetState extends State<InventoryCatalogueSheet> {
  bool _showRetired = false;
  String? _editingId;
  bool _busy = false;
  final _rename = TextEditingController();
  final _category = TextEditingController();
  final _unitCode = TextEditingController();
  final _unitName = TextEditingController();

  @override
  void dispose() {
    _rename.dispose();
    _category.dispose();
    _unitCode.dispose();
    _unitName.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action, {VoidCallback? onDone}) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _editingId = null;
        _rename.clear();
        onDone?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      final categories = [for (final e in c.categories) if (_showRetired || e.isActive) e];
      final units = [for (final e in c.unitTypes) if (_showRetired || e.isActive) e];
      return InventorySheet(
        icon: Icons.tune_rounded,
        title: 'Categories and units',
        description: 'What kinds of thing you stock, and what they are counted in. Retiring one '
            'keeps every item already filed under it.',
        actions: [HandoverButton(label: 'Close', onPressed: () => Navigator.of(context).pop())],
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: HandoverButton(
              key: const ValueKey('inventory-catalogue-retired'),
              label: _showRetired ? 'Hide retired' : 'Show retired',
              compact: true,
              onPressed: () => setState(() => _showRetired = !_showRetired),
            ),
          ),
          const SizedBox(height: 14),
          InventorySection(
            title: 'Categories',
            children: [
              for (final entry in categories) _entry(entry, unit: false),
              if (c.canWrite) ...[
                const SizedBox(height: 6),
                InventoryField(
                  key: const ValueKey('inventory-category-new'),
                  label: 'Add a category',
                  controller: _category,
                  placeholder: 'Continence supplies',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: HandoverButton(
                    key: const ValueKey('inventory-category-add'),
                    label: 'Add',
                    icon: Icons.add_rounded,
                    filled: true,
                    onPressed: _busy || _category.text.trim().isEmpty
                        ? null
                        : () => _run(
                              () => c.addCategory(_category.text.trim()),
                              onDone: _category.clear,
                            ),
                  ),
                ),
              ],
            ],
          ),
          InventorySection(
            title: 'Units',
            children: [
              for (final entry in units) _entry(entry, unit: true),
              if (c.canWrite) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: InventoryField(
                        key: const ValueKey('inventory-unit-code'),
                        label: 'Code',
                        controller: _unitCode,
                        placeholder: 'box',
                        helper: 'Stored on items',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InventoryField(
                        key: const ValueKey('inventory-unit-name'),
                        label: 'Name',
                        controller: _unitName,
                        placeholder: 'Box of 100',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: HandoverButton(
                    key: const ValueKey('inventory-unit-add'),
                    label: 'Add',
                    icon: Icons.add_rounded,
                    filled: true,
                    onPressed: _busy ||
                            _unitCode.text.trim().isEmpty ||
                            _unitName.text.trim().isEmpty
                        ? null
                        : () => _run(
                              () => c.addUnitType(_unitCode.text.trim(), _unitName.text.trim()),
                              onDone: () {
                                _unitCode.clear();
                                _unitName.clear();
                              },
                            ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                "A unit's code cannot change once items are counted in it. Its name can.",
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _entry(InventoryCatalogueEntry entry, {required bool unit}) {
    final c = widget.controller;
    final retired = !entry.isActive;
    if (_editingId == entry.id) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: InventoryField(
                key: ValueKey('inventory-rename-${entry.id}'),
                controller: _rename,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 6),
            HandoverButton(
              key: ValueKey('inventory-rename-save-${entry.id}'),
              label: '',
              icon: Icons.check_rounded,
              filled: true,
              compact: true,
              onPressed: _busy || _rename.text.trim().isEmpty
                  ? null
                  : () => _run(
                        () => unit
                            ? c.renameUnitType(entry.id, _rename.text.trim())
                            : c.renameCategory(entry.id, _rename.text.trim()),
                      ),
            ),
            const SizedBox(width: 6),
            InventoryIconButton(
              icon: Icons.close_rounded,
              onPressed: () => setState(() => _editingId = null),
            ),
          ],
        ),
      );
    }
    return InventoryRow(
      key: ValueKey('inventory-catalogue-${entry.id}'),
      title: entry.name,
      subtitle: entry.code,
      trailing: [
        if (retired) const AttendancePill(label: 'Retired', tone: AttendanceTone.neutral),
        if (c.canWrite) ...[
          InventoryIconButton(
            key: ValueKey('inventory-catalogue-edit-${entry.id}'),
            icon: Icons.edit_outlined,
            onPressed: () => setState(() {
              _editingId = entry.id;
              _rename.text = entry.name;
            }),
          ),
          InventoryIconButton(
            key: ValueKey('inventory-catalogue-archive-${entry.id}'),
            icon: retired ? Icons.unarchive_outlined : Icons.archive_outlined,
            tooltip: retired ? 'Offer it again' : 'Stop offering it',
            onPressed: _busy
                ? null
                : () => _run(() => unit ? c.archiveUnitType(entry) : c.archiveCategory(entry)),
          ),
        ],
      ],
    );
  }
}
