import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/stock_ops.dart';
import '../controllers/stock_counts_controller.dart';
import '../inventory_labels.dart';
import 'inventory_common.dart';

/// Web "Start a stock count" modal. Resolves to the id of the count to show.
Future<String?> showStartCountSheet(
  BuildContext context, {
  required StockCountsController controller,
}) =>
    showInventorySheet<String>(context, (_) => StartCountSheet(controller: controller));

class StartCountSheet extends StatefulWidget {
  final StockCountsController controller;

  const StartCountSheet({super.key, required this.controller});

  @override
  State<StartCountSheet> createState() => _StartCountSheetState();
}

class _StartCountSheetState extends State<StartCountSheet> {
  String _residenceId = '';
  String _categoryId = '';
  String? _error;
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _error = null);
    if (_residenceId.isEmpty) {
      setState(() => _error = 'Choose which residence is being counted.');
      return;
    }
    setState(() => _busy = true);
    final result = await widget.controller.open(
      residenceId: _residenceId,
      categoryId: _categoryId.isEmpty ? null : _categoryId,
    );
    if (!mounted) return;
    result.when(
      success: (id) => Navigator.of(context).pop(id),
      failure: (error) => setState(() {
        _busy = false;
        _error = error.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return InventorySheet(
      icon: Icons.assignment_outlined,
      title: 'Start a stock count',
      description: 'A count can cover a whole residence or one category of it.',
      error: _error,
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('count-open'),
          label: _busy ? 'Opening…' : 'Open count',
          filled: true,
          onPressed: _busy ? null : _open,
        ),
      ],
      children: [
        InventorySelect(
          key: const ValueKey('count-residence'),
          label: 'Residence',
          required: true,
          options: [for (final r in c.residences) (r.value, r.label)],
          value: _residenceId,
          placeholder: 'Which residence',
          onChanged: (v) => setState(() => _residenceId = v),
        ),
        const SizedBox(height: 12),
        InventorySelect(
          label: 'Category',
          options: [for (final o in c.categories) (o.value, o.label)],
          value: _categoryId,
          placeholder: 'Everything',
          onChanged: (v) => setState(() => _categoryId = v),
        ),
      ],
    );
  }
}

/// Web count modal: shelf lines with counted inputs, filters and submit.
Future<void> showStockCountSheet(
  BuildContext context, {
  required StockCountsController controller,
  required String countId,
}) =>
    showInventorySheet<void>(
      context,
      (_) => StockCountSheet(controller: controller, countId: countId),
    );

class StockCountSheet extends StatefulWidget {
  final StockCountsController controller;
  final String countId;

  const StockCountSheet({super.key, required this.controller, required this.countId});

  @override
  State<StockCountSheet> createState() => _StockCountSheetState();
}

enum _CountFilter { all, todo, differences }

class _StockCountSheetState extends State<StockCountSheet> {
  StockCount? _count;
  String? _loadError;
  final Map<String, TextEditingController> _entries = {};
  _CountFilter _filter = _CountFilter.all;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _entries.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.controller.count(widget.countId);
    if (!mounted) return;
    setState(() {
      result.when(
        success: (count) {
          _count = count;
          _loadError = null;
        },
        failure: (error) => _loadError = error.message,
      );
    });
  }

  TextEditingController _entry(String lineId) =>
      _entries.putIfAbsent(lineId, TextEditingController.new);

  /// Web `ea`: the typed value wins over the saved one.
  (num?, num?) _state(StockCountLine line) {
    final typed = _entries[line.id]?.text ?? '';
    final value = typed.isNotEmpty ? num.tryParse(typed) : line.countedQty;
    if (value == null || !value.isFinite) return (null, null);
    return (value, value - line.systemQty);
  }

  Future<void> _save(StockCount count) async {
    final lines = [
      for (final line in count.lines)
        if ((_entries[line.id]?.text.trim() ?? '').isNotEmpty)
          {'lineId': line.id, 'countedQty': num.tryParse(_entries[line.id]!.text.trim()) ?? 0},
    ];
    if (lines.isEmpty) {
      AppSnackbar.show('Nothing counted yet.', '');
      return;
    }
    setState(() => _busy = true);
    final error = await widget.controller.saveLines(count.id, lines);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) await _load();
  }

  Future<void> _submit(StockCount count) async {
    setState(() => _busy = true);
    final error = await widget.controller.submit(count.id);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    if (count == null) {
      return InventorySheet(
        icon: Icons.assignment_outlined,
        title: 'Count',
        error: _loadError,
        actions: [HandoverButton(label: 'Close', onPressed: () => Navigator.of(context).pop())],
        children: [if (_loadError == null) const InventoryNote('Loading…')],
      );
    }
    final editable = widget.controller.canAdjust && count.isEditable;
    final states = {for (final l in count.lines) l.id: _state(l)};
    final done = states.values.where((s) => s.$1 != null).length;
    final differences = states.values.where((s) => s.$2 != null && s.$2 != 0).length;
    final shown = [
      for (final l in count.lines)
        if (switch (_filter) {
          _CountFilter.all => true,
          _CountFilter.todo => states[l.id]!.$1 == null,
          _CountFilter.differences => states[l.id]!.$2 != null && states[l.id]!.$2 != 0,
        })
          l,
    ];
    return InventorySheet(
      icon: Icons.assignment_outlined,
      title: 'Count · ${count.residenceName ?? ''}',
      description: InventoryLabels.humanise(count.status),
      footerLeft: count.isEditable
          ? Text(
              'Submitting applies every counted line as an adjustment.',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            )
          : null,
      actions: [
        HandoverButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
        if (editable) ...[
          HandoverButton(
            key: const ValueKey('count-save'),
            label: 'Save counts',
            onPressed: _busy ? null : () => _save(count),
          ),
          HandoverButton(
            key: const ValueKey('count-submit'),
            label: 'Submit count',
            filled: true,
            onPressed: _busy ? null : () => _submit(count),
          ),
        ],
      ],
      children: [
        if (count.lines.isEmpty)
          const InventoryNote(
            'Nothing to count here — this house has no stock in the chosen category.',
          )
        else ...[
          Text(
            '$done of ${count.lines.length} counted'
            '${differences > 0 ? ' · $differences ${differences == 1 ? 'difference' : 'differences'}' : done > 0 ? ' · everything matches so far' : ''}',
            key: const ValueKey('count-progress'),
            style: handoverText(context, 13, weight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (f, label) in const [
                (_CountFilter.all, 'All'),
                (_CountFilter.todo, 'Not counted'),
                (_CountFilter.differences, 'Differences'),
              ])
                HandoverButton(
                  key: ValueKey('count-filter-${f.name}'),
                  label: label,
                  compact: true,
                  filled: _filter == f,
                  onPressed: () => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            InventoryNote(
              _filter == _CountFilter.todo ? 'Every line has been counted.' : 'No differences so far.',
            ),
          for (final line in shown) _line(line, states[line.id]!.$2, editable),
        ],
      ],
    );
  }

  Widget _line(StockCountLine line, num? difference, bool editable) {
    final lot = line.hasBatch
        ? '${line.batchNo != null ? 'Lot ${line.batchNo}' : 'Undated lot'}'
            '${line.batchExpiry != null ? ' · expires ${InventoryLabels.day(line.batchExpiry!)}' : ''} · '
        : '';
    return InventoryRow(
      key: ValueKey('count-line-${line.id}'),
      title: line.itemName ?? 'Item',
      subtitle: '${lot}Record says ${InventoryLabels.qty(line.systemQty)}'
          '${line.itemUnit != null ? ' ${line.itemUnit}' : ''}',
      trailing: [
        if (difference != null && difference != 0)
          AttendancePill(
            label: difference > 0 ? '+${InventoryLabels.qty(difference)}' : InventoryLabels.qty(difference),
            tone: difference > 0 ? AttendanceTone.info : AttendanceTone.danger,
          ),
        if (difference == 0) const AttendancePill(label: 'Matches', tone: AttendanceTone.success),
        if (editable)
          SizedBox(
            width: 96,
            child: InventoryField(
              key: ValueKey('count-input-${line.id}'),
              controller: _entry(line.id),
              number: true,
              placeholder: 'Counted',
              onChanged: (_) => setState(() {}),
            ),
          )
        else
          Text(
            line.countedQty != null ? 'Counted ${InventoryLabels.qty(line.countedQty)}' : 'Not counted',
            style: handoverText(context, 12.5, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}
