import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/stock_ops.dart';
import '../controllers/stock_transfers_controller.dart';
import '../inventory_labels.dart';
import 'inventory_common.dart';

/// Web "Move stock to another house" modal.
Future<void> showTransferRequestSheet(
  BuildContext context, {
  required StockTransfersController controller,
}) =>
    showInventorySheet<void>(context, (_) => TransferRequestSheet(controller: controller));

class _DraftLine {
  final int key;
  InventoryItem? item;
  String batchId = '';
  final TextEditingController quantity = TextEditingController();
  List<InventoryBatch> lots = const [];
  bool lotsLoaded = false;

  _DraftLine(this.key);
}

class TransferRequestSheet extends StatefulWidget {
  final StockTransfersController controller;

  const TransferRequestSheet({super.key, required this.controller});

  @override
  State<TransferRequestSheet> createState() => _TransferRequestSheetState();
}

class _TransferRequestSheetState extends State<TransferRequestSheet> {
  String _from = '';
  String _to = '';
  final _notes = TextEditingController();
  List<InventoryItem> _shelf = const [];
  List<_DraftLine> _lines = [_DraftLine(0)];
  int _nextKey = 1;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    for (final l in _lines) {
      l.quantity.dispose();
    }
    super.dispose();
  }

  /// The removed fields still hold these controllers until the next frame.
  void _disposeLater(List<_DraftLine> lines) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final l in lines) {
        l.quantity.dispose();
      }
    });
  }

  Future<void> _chooseFrom(String value) async {
    final dropped = _lines;
    setState(() {
      _from = value;
      if (_to == value) _to = '';
      _lines = [_DraftLine(_nextKey++)];
      _shelf = const [];
    });
    _disposeLater(dropped);
    final result = await widget.controller.shelf(value);
    if (!mounted || _from != value) return;
    setState(() => _shelf = result.when(success: (v) => v, failure: (_) => const []));
  }

  Future<void> _chooseItem(_DraftLine line, String itemId) async {
    final item = _shelf.where((i) => i.id == itemId).firstOrNull;
    setState(() {
      line.item = item;
      line.batchId = '';
      line.lots = const [];
      line.lotsLoaded = false;
    });
    if (item == null || !item.tracksBatches) return;
    final result = await widget.controller.lots(item.id);
    if (!mounted || line.item?.id != item.id) return;
    setState(() {
      line.lots = result.when(success: (v) => v, failure: (_) => const []);
      line.lotsLoaded = true;
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    String? fail;
    if (_from.isEmpty || _to.isEmpty) {
      fail = 'Choose which house it leaves and which it goes to.';
    } else if (_from == _to) {
      fail = 'A transfer moves stock between two different houses.';
    }
    final filled = [for (final l in _lines) if (l.item != null && l.quantity.text.trim().isNotEmpty) l];
    if (fail == null && filled.isEmpty) fail = 'Add at least one product.';
    if (fail == null) {
      for (final l in filled) {
        final item = l.item!;
        final q = num.tryParse(l.quantity.text.trim());
        if (q == null || q <= 0) {
          fail = 'How many ${item.name}? It has to be more than zero.';
        } else if (q > item.quantity) {
          fail = 'Only ${InventoryLabels.qty(item.quantity)} ${item.unit ?? ''} of ${item.name} on that shelf.';
        } else if (item.tracksBatches && l.batchId.isEmpty) {
          fail = 'Which lot of ${item.name} is going?';
        }
        if (fail != null) break;
      }
    }
    if (fail != null) {
      setState(() => _error = fail);
      return;
    }
    setState(() => _saving = true);
    final error = await widget.controller.create({
      'fromResidenceId': _from,
      'toResidenceId': _to,
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      'lines': [
        for (final l in filled)
          {
            'fromItemId': l.item!.id,
            'quantity': num.parse(l.quantity.text.trim()),
            if (l.batchId.isNotEmpty) 'fromBatchId': l.batchId,
          },
      ],
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
    final residences = [for (final r in widget.controller.residences) (r.value, r.label)];
    return InventorySheet(
      icon: Icons.swap_horiz_rounded,
      title: 'Move stock to another house',
      description: 'Nothing leaves the shelf yet — it is approved, then dispatched, then received '
          'at the other end.',
      error: _error,
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('transfer-request-save'),
          label: _saving ? 'Creating…' : 'Request transfer',
          filled: true,
          onPressed: _saving ? null : _submit,
        ),
      ],
      children: [
        InventorySelect(
          key: const ValueKey('transfer-from'),
          label: 'From',
          required: true,
          options: residences,
          value: _from,
          placeholder: 'Which house is sending',
          onChanged: _chooseFrom,
        ),
        const SizedBox(height: 12),
        InventorySelect(
          key: const ValueKey('transfer-to'),
          label: 'To',
          required: true,
          options: [for (final r in residences) if (r.$1 != _from) r],
          value: _to,
          placeholder: 'Which house is receiving',
          onChanged: (v) => setState(() => _to = v),
        ),
        const SizedBox(height: 14),
        for (final line in _lines) _line(line),
        Align(
          alignment: Alignment.centerLeft,
          child: HandoverButton(
            key: const ValueKey('transfer-add-line'),
            label: 'Add another product',
            icon: Icons.add_rounded,
            onPressed: _from.isEmpty ? null : () => setState(() => _lines.add(_DraftLine(_nextKey++))),
          ),
        ),
        const SizedBox(height: 12),
        HandoverTextArea(
          label: 'Note',
          controller: _notes,
          placeholder: "Cedar is short until Thursday's delivery…",
        ),
      ],
    );
  }

  Widget _line(_DraftLine line) {
    final onHand = line.item?.quantity;
    final typed = num.tryParse(line.quantity.text.trim());
    final over = onHand != null && typed != null && typed > onHand;
    return Container(
      key: ValueKey('transfer-line-${line.key}'),
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
                child: Text('Product', style: handoverText(context, 12.5, weight: FontWeight.w600)),
              ),
              if (_lines.length > 1)
                InventoryIconButton(
                  icon: Icons.delete_outline_rounded,
                  onPressed: () {
                    setState(() => _lines.remove(line));
                    _disposeLater([line]);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          InventorySelect(
            key: ValueKey('transfer-item-${line.key}'),
            label: 'What is being moved',
            required: true,
            options: [
              for (final i in _shelf)
                (i.id, '${i.name} — ${InventoryLabels.qty(i.quantity)} ${i.unit ?? ''} on hand'),
            ],
            value: line.item?.id ?? '',
            enabled: _shelf.isNotEmpty,
            placeholder: _from.isEmpty
                ? 'Choose the sending house first'
                : _shelf.isEmpty
                    ? 'That house has nothing on its shelves'
                    : 'Pick from the sending house',
            onChanged: (v) => _chooseItem(line, v),
          ),
          const SizedBox(height: 10),
          InventoryField(
            key: ValueKey('transfer-qty-${line.key}'),
            label: 'How many',
            required: true,
            number: true,
            controller: line.quantity,
            error: over ? 'Only ${InventoryLabels.qty(onHand)} on hand' : null,
            onChanged: (_) => setState(() {}),
          ),
          if (line.item?.tracksBatches ?? false) ...[
            const SizedBox(height: 10),
            InventorySelect(
              key: ValueKey('transfer-lot-${line.key}'),
              label: 'Which lot',
              required: true,
              options: [
                for (final b in line.lots)
                  (
                    b.id,
                    '${b.batchNo ?? 'Undated lot'} — ${InventoryLabels.qty(b.quantity)} left'
                        '${b.expiryDay != null ? ', expires ${b.expiryDay}' : ''}',
                  ),
              ],
              value: line.batchId,
              placeholder: line.lots.isEmpty ? 'No lots on this shelf' : 'Pick the box',
              helper: 'A transfer is somebody carrying a physical box, so the sender names the date on it.',
              onChanged: (v) => setState(() => line.batchId = v),
            ),
          ],
        ],
      ),
    );
  }
}

/// Web dispatch ("What is going in the van") / receive ("What turned up") modal.
Future<void> showTransferStepSheet(
  BuildContext context, {
  required StockTransfersController controller,
  required StockTransfer transfer,
  required String step,
}) =>
    showInventorySheet<void>(
      context,
      (_) => TransferStepSheet(controller: controller, transfer: transfer, step: step),
    );

class TransferStepSheet extends StatefulWidget {
  final StockTransfersController controller;
  final StockTransfer transfer;
  final String step;

  const TransferStepSheet({
    super.key,
    required this.controller,
    required this.transfer,
    required this.step,
  });

  @override
  State<TransferStepSheet> createState() => _TransferStepSheetState();
}

class _TransferStepSheetState extends State<TransferStepSheet> {
  late final Map<String, TextEditingController> _qty;
  final Map<String, String> _reason = {};
  final Map<String, TextEditingController> _notes = {};
  String? _error;
  bool _saving = false;

  bool get _dispatch => widget.step == 'dispatch';

  num _expected(StockTransferLine line) {
    final dispatched = line.dispatchedQuantity ?? 0;
    return _dispatch ? line.quantity : (dispatched != 0 ? dispatched : line.quantity);
  }

  @override
  void initState() {
    super.initState();
    _qty = {
      for (final l in widget.transfer.lines)
        l.id: TextEditingController(text: InventoryLabels.qty(_expected(l))),
    };
  }

  @override
  void dispose() {
    for (final c in [..._qty.values, ..._notes.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _note(String id) => _notes.putIfAbsent(id, TextEditingController.new);

  Future<void> _confirm() async {
    setState(() => _error = null);
    final lines = <Map<String, dynamic>>[];
    for (final line in widget.transfer.lines) {
      final expected = _expected(line);
      final value = num.tryParse(_qty[line.id]!.text.trim());
      if (value == null || !value.isFinite || value < 0) {
        setState(() => _error = 'Enter a number for ${line.itemName ?? 'each product'}.');
        return;
      }
      if (value > expected) {
        setState(() => _error = '${line.itemName ?? 'That product'}: only ${InventoryLabels.qty(expected)} '
            '${_dispatch ? 'was requested' : 'left the other house'}.');
        return;
      }
      final short = expected - value;
      if (!_dispatch && short > 0 && (_reason[line.id] ?? '').isEmpty) {
        setState(() => _error = '${line.itemName ?? 'That product'}: ${InventoryLabels.qty(short)} did '
            'not arrive — say what happened to it.');
        return;
      }
      if (value > 0 || (!_dispatch && short > 0)) {
        final note = _notes[line.id]?.text.trim() ?? '';
        lines.add(
          _dispatch
              ? {'lineId': line.id, 'quantity': value}
              : {
                  'lineId': line.id,
                  'receivedQuantity': value,
                  if (short > 0) 'shortfallReason': _reason[line.id],
                  if (short > 0 && note.isNotEmpty) 'shortfallNotes': note,
                },
        );
      }
    }
    if (lines.isEmpty) {
      setState(() => _error = _dispatch
          ? 'Nothing is going in the van.'
          : 'Nothing arrived — cancel the transfer instead.');
      return;
    }
    setState(() => _saving = true);
    final error = _dispatch
        ? await widget.controller.dispatch(widget.transfer.id, lines)
        : await widget.controller.receive(widget.transfer.id, lines);
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
    final t = widget.transfer;
    return InventorySheet(
      icon: _dispatch ? Icons.local_shipping_outlined : Icons.inventory_outlined,
      title: _dispatch ? 'What is going in the van' : 'What turned up',
      description: _dispatch
          ? 'Leaves ${t.fromResidenceName ?? 'the sending house'} now. Stock comes off that shelf when you confirm.'
          : 'Arrived at ${t.toResidenceName ?? 'the receiving house'}. Stock goes onto that shelf as you enter it.',
      error: _error,
      actions: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        HandoverButton(
          key: const ValueKey('transfer-step-save'),
          label: _saving ? 'Saving…' : (_dispatch ? 'Send it' : 'Book it in'),
          filled: true,
          onPressed: _saving ? null : _confirm,
        ),
      ],
      children: [for (final line in t.lines) _line(line)],
    );
  }

  Widget _line(StockTransferLine line) {
    final expected = _expected(line);
    final dispatched = line.dispatchedQuantity ?? 0;
    final typed = num.tryParse(_qty[line.id]!.text.trim());
    final short = typed != null && typed < expected ? expected - typed : null;
    return InventoryRow(
      key: ValueKey('transfer-step-line-${line.id}'),
      title: line.itemName ?? 'Product',
      subtitle: '${InventoryLabels.qty(line.quantity)} requested'
          '${!_dispatch && dispatched > 0 ? ' · ${InventoryLabels.qty(dispatched)} left the other house' : ''}',
      trailing: [
        if (short != null)
          AttendancePill(label: '${InventoryLabels.qty(short)} short', tone: AttendanceTone.warning),
        SizedBox(
          width: 90,
          child: InventoryField(
            key: ValueKey('transfer-step-qty-${line.id}'),
            controller: _qty[line.id]!,
            number: true,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
      below: !_dispatch && short != null
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InventorySelect(
                    key: ValueKey('transfer-short-reason-${line.id}'),
                    label: 'What happened to the missing ${InventoryLabels.qty(short)}?',
                    required: true,
                    options: InventoryLabels.shortfallReasons,
                    value: _reason[line.id] ?? '',
                    placeholder: 'Choose a reason',
                    onChanged: (v) => setState(() => _reason[line.id] = v),
                  ),
                  const SizedBox(height: 8),
                  InventoryField(
                    controller: _note(line.id),
                    placeholder: 'Anything worth adding — parcel number, who signed for it…',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
