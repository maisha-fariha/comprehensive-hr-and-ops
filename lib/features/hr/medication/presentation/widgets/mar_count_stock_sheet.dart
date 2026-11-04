import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/mar_medication_stock.dart';
import 'medication_common.dart';

/// Web "Count stock" modal — `PUT /medication-stock`.
Future<bool?> showMarCountStockSheet(
  BuildContext context, {
  required MarStockRow row,
  required Future<bool> Function(MarStockCountDraft draft) onSave,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MarCountStockSheet(row: row, onSave: onSave),
  );
}

class _MarCountStockSheet extends StatefulWidget {
  final MarStockRow row;
  final Future<bool> Function(MarStockCountDraft draft) onSave;

  const _MarCountStockSheet({required this.row, required this.onSave});

  @override
  State<_MarCountStockSheet> createState() => _MarCountStockSheetState();
}

class _MarCountStockSheetState extends State<_MarCountStockSheet> {
  static const _units = [
    'tablets',
    'capsules',
    'ml',
    'inhalers',
    'patches',
    'drops',
    'sachets',
    'vials',
  ];

  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _refill;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final stock = widget.row.stock;
    _quantity = TextEditingController(
      text: stock == null ? '' : _numText(stock.quantity),
    );
    _unit = TextEditingController(text: stock?.unit ?? '');
    _refill = TextEditingController(
      text: stock?.refillThreshold == null
          ? ''
          : _numText(stock!.refillThreshold!),
    );
  }

  @override
  void dispose() {
    _quantity.dispose();
    _unit.dispose();
    _refill.dispose();
    super.dispose();
  }

  static String _numText(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  bool get _canSave {
    final qty = num.tryParse(_quantity.text.trim());
    if (qty == null || qty < 0) return false;
    final refillRaw = _refill.text.trim();
    if (refillRaw.isNotEmpty) {
      final refill = num.tryParse(refillRaw);
      if (refill == null || refill < 0) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    final refillRaw = _refill.text.trim();
    final ok = await widget.onSave(
      MarStockCountDraft(
        residenceId: widget.row.residenceId,
        medicationId: widget.row.medicationId,
        prnMedicationId: widget.row.prnMedicationId,
        quantity: num.parse(_quantity.text.trim()),
        unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        refillThreshold: refillRaw.isEmpty ? null : num.parse(refillRaw),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MarSheetHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Count stock',
              description:
                  '${row.name} · ${row.resident}. What is on the shelf now replaces the running count.',
            ),
            const SizedBox(height: 16),
            MarTextField(
              label: 'On the shelf now',
              controller: _quantity,
              required: true,
              decimal: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            MarTextField(
              label: 'Counted in',
              controller: _unit,
              placeholder: 'tablets, inhalers, ml…',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick select:',
              style: handoverText(context, 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final unit in _units)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _unit.text = unit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _unit.text.toLowerCase() == unit.toLowerCase()
                            ? AppColors.primaryNavy
                            : AppColors.filterButtonBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        unit,
                        style: handoverText(
                          context,
                          11,
                          weight: FontWeight.w600,
                          color: _unit.text.toLowerCase() == unit.toLowerCase()
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            MarTextField(
              label: 'Refill when at or below',
              controller: _refill,
              decimal: true,
              helper: 'Blank for no refill alert.',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: HandoverButton(
                    label: 'Cancel',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.getResponsiveWidth(context, 10),
                ),
                Expanded(
                  child: HandoverButton(
                    label: _saving ? 'Saving…' : 'Save count',
                    filled: true,
                    onPressed: _canSave && !_saving ? _submit : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
