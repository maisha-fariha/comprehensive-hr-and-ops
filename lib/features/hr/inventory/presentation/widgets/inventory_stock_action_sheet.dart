import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../controllers/inventory_stock_controller.dart';
import '../inventory_labels.dart';
import 'inventory_common.dart';

enum InventoryStockMode { move, recount, loss }

/// Web "Stock" modal: Move, Recount and Loss, each behind its own permission.
Future<void> showInventoryStockAction(
  BuildContext context, {
  required InventoryStockController controller,
  required InventoryItem item,
}) =>
    showInventorySheet<void>(
      context,
      (_) => InventoryStockActionSheet(controller: controller, item: item),
    );

class InventoryStockActionSheet extends StatefulWidget {
  final InventoryStockController controller;
  final InventoryItem item;

  const InventoryStockActionSheet({super.key, required this.controller, required this.item});

  @override
  State<InventoryStockActionSheet> createState() => _InventoryStockActionSheetState();
}

class _InventoryStockActionSheetState extends State<InventoryStockActionSheet> {
  static const _directions = [
    ('out', 'Out — used or issued'),
    ('in', 'In — delivered or returned'),
  ];

  late final List<InventoryStockMode> _modes;
  late InventoryStockMode _mode;
  String _direction = 'out';
  String _lossType = 'waste';
  String _batchId = '';
  final _qty = TextEditingController();
  final _note = TextEditingController();
  List<InventoryBatch> _batches = const [];
  String? _error;
  bool _saving = false;

  InventoryItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _modes = [
      if (c.canMove) InventoryStockMode.move,
      if (c.canAdjust && !_item.tracksBatches) InventoryStockMode.recount,
      if (c.canWaste) InventoryStockMode.loss,
    ];
    _mode = _modes.isEmpty ? InventoryStockMode.move : _modes.first;
    if (_item.tracksBatches) _loadBatches();
  }

  Future<void> _loadBatches() async {
    final r = await widget.controller.repository.batches(_item.id);
    if (mounted) setState(() => _batches = r.when(success: (v) => v, failure: (_) => const []));
  }

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  num? get _value {
    final raw = _qty.text.trim();
    if (raw.isEmpty) return null;
    final v = num.tryParse(raw);
    return v == null || !v.isFinite ? null : v;
  }

  bool get _overShelf {
    final v = _value;
    if (v == null) return false;
    final takesOut = (_mode == InventoryStockMode.move && _direction == 'out') ||
        _mode == InventoryStockMode.loss;
    return takesOut && v > _item.quantity;
  }

  String get _overMessage {
    final q = '${InventoryLabels.qty(_item.quantity)} ${_item.unitLabel}';
    return _mode == InventoryStockMode.loss
        ? 'Only $q on the shelf. If more than that has gone, the record is already wrong — recount it.'
        : 'Only $q on the shelf.';
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final v = _value;
    if (v == null || v < 0) {
      setState(() => _error = 'Enter how many.');
      return;
    }
    if (_overShelf) {
      setState(() => _error = _overMessage);
      return;
    }
    final note = _note.text.trim();
    final c = widget.controller;
    Future<String?> Function() action;
    switch (_mode) {
      case InventoryStockMode.move:
        if (v == 0) {
          setState(() => _error = 'A movement of zero would not change anything.');
          return;
        }
        action = () => c.moveStock(_item, _direction == 'out' ? -v : v, note.isEmpty ? null : note);
      case InventoryStockMode.recount:
        if (note.isEmpty) {
          setState(() => _error = 'Say why the count differs — it goes on the record.');
          return;
        }
        action = () => c.recount(_item, v, note);
      case InventoryStockMode.loss:
        if (v <= 0) {
          setState(() => _error = 'Enter how many were lost.');
          return;
        }
        action = () => c.recordLoss(
              _item,
              type: _lossType,
              quantity: v,
              batchId: _batchId.isEmpty ? null : _batchId,
              notes: note.isEmpty ? null : note,
            );
    }
    setState(() => _saving = true);
    final error = await action();
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

  static String _modeLabel(InventoryStockMode m) => switch (m) {
        InventoryStockMode.move => 'Move',
        InventoryStockMode.recount => 'Recount',
        InventoryStockMode.loss => 'Loss',
      };

  static IconData _modeIcon(InventoryStockMode m) => switch (m) {
        InventoryStockMode.move => Icons.add_box_outlined,
        InventoryStockMode.recount => Icons.qr_code_scanner_rounded,
        InventoryStockMode.loss => Icons.delete_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final description = '${InventoryLabels.qty(_item.quantity)} ${_item.unitLabel} on hand'
        '${_item.reorderLevel != null ? ' · reorder at ${InventoryLabels.qty(_item.reorderLevel)}' : ''}';
    if (_modes.isEmpty) {
      return InventorySheet(
        icon: Icons.block_rounded,
        title: 'You cannot change stock',
        description: 'Moving, recounting and writing off stock are each granted separately. '
            'Ask an administrator if you need one of them.',
        actions: [HandoverButton(label: 'Close', onPressed: () => Navigator.of(context).pop())],
        children: const [],
      );
    }
    final recount = _mode == InventoryStockMode.recount;
    final over = _overShelf;
    return InventorySheet(
      icon: _mode == InventoryStockMode.loss ? Icons.indeterminate_check_box_outlined : Icons.add_box_outlined,
      title: _item.name,
      description: description,
      error: _error,
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('inventory-stock-save'),
          label: _saving ? 'Saving…' : 'Save',
          filled: true,
          onPressed: _saving || over ? null : _save,
        ),
      ],
      children: [
        if (_modes.length > 1) ...[
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                for (final m in _modes)
                  Expanded(
                    child: InkWell(
                      key: ValueKey('inventory-stock-mode-${m.name}'),
                      onTap: () => setState(() {
                        _mode = m;
                        _error = null;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: m == _mode ? AppColors.surfaceWhite : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _modeIcon(m),
                              size: 14,
                              color: m == _mode ? AppColors.textHeading : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _modeLabel(m),
                              style: handoverText(
                                context,
                                13,
                                weight: m == _mode ? FontWeight.w600 : FontWeight.w400,
                                color: m == _mode ? AppColors.textHeading : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          switch (_mode) {
            InventoryStockMode.move =>
              'Records that stock left or arrived. The quantity changes by this much.',
            InventoryStockMode.recount =>
              'Sets the quantity to what you actually counted. The difference is recorded with your reason.',
            InventoryStockMode.loss =>
              'Stock that left without being used. It comes off the count and stays on the record.',
          },
          style: handoverText(context, 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (_mode == InventoryStockMode.move) ...[
          InventorySelect(
            key: const ValueKey('inventory-stock-direction'),
            label: 'Direction',
            required: true,
            options: _directions,
            value: _direction,
            placeholder: '',
            onChanged: (v) => setState(() => _direction = v),
          ),
          const SizedBox(height: 12),
        ],
        if (_mode == InventoryStockMode.loss) ...[
          InventorySelect(
            key: const ValueKey('inventory-stock-loss-type'),
            label: 'What happened',
            required: true,
            options: InventoryLabels.lossKinds,
            value: _lossType,
            placeholder: '',
            onChanged: (v) => setState(() => _lossType = v),
          ),
          const SizedBox(height: 12),
          if (_item.tracksBatches) ...[
            InventorySelect(
              label: 'Which lot',
              options: [
                for (final b in _batches)
                  (
                    b.id,
                    [
                      b.batchNo ?? 'Unnumbered lot',
                      if (b.expiryDate != null) 'exp ${InventoryLabels.date(DateTime.tryParse(b.expiryDate!))}',
                      '${InventoryLabels.qty(b.quantity ?? 0)} left',
                    ].join(' · '),
                  ),
              ],
              value: _batchId,
              placeholder: 'Oldest expiry first',
              helper: 'Leave it for the oldest. Name a lot when that lot is the problem.',
              onChanged: (v) => setState(() => _batchId = v),
            ),
            const SizedBox(height: 12),
          ],
        ],
        InventoryField(
          key: const ValueKey('inventory-stock-qty'),
          label: recount ? 'Counted quantity' : 'How many',
          required: true,
          number: true,
          controller: _qty,
          error: over ? _overMessage : null,
          helper: _item.unitLabel.isNotEmpty ? 'In ${_item.unitLabel}' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        HandoverTextArea(
          key: const ValueKey('inventory-stock-note'),
          label: recount ? 'Why the count differs' : 'Note',
          required: recount,
          controller: _note,
          placeholder: recount ? 'Miscount at the last check, breakage not logged…' : 'Optional',
        ),
      ],
    );
  }
}
