import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../../domain/entities/compliance.dart';
import '../controllers/compliance_controller.dart';

Future<void> showSubmitCheckSheet(
  BuildContext context, {
  required ComplianceController controller,
  required ComplianceCheck check,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SubmitCheckSheet(controller: controller, check: check),
  );
}

class SubmitCheckSheet extends StatefulWidget {
  final ComplianceController controller;
  final ComplianceCheck check;

  const SubmitCheckSheet({
    super.key,
    required this.controller,
    required this.check,
  });

  @override
  State<SubmitCheckSheet> createState() => _SubmitCheckSheetState();
}

class _SubmitCheckSheetState extends State<SubmitCheckSheet> {
  final _notes = TextEditingController();
  final _evidence = TextEditingController();
  String _result = 'compliant';
  bool _raiseFinding = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    _evidence.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    final body = <String, dynamic>{
      'result': _result,
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      if (_evidence.text.trim().isNotEmpty)
        'evidence': [
          {'label': _evidence.text.trim()},
        ],
      if (ComplianceMapper.raiseFindingResults.contains(_result) &&
          _raiseFinding)
        'raiseFinding': true,
    };
    final err = await widget.controller.submitCheck(widget.check.id, body);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.show('Check recorded', '', force: true);
  }

  @override
  Widget build(BuildContext context) {
    final canRaise =
        ComplianceMapper.raiseFindingResults.contains(_result);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carry out check',
                        style: handoverText(context, 16, weight: FontWeight.w700),
                      ),
                      Text(
                        widget.check.requirementName ?? 'Check',
                        style: handoverText(
                          context,
                          12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: handoverText(context, 12.5, color: AppColors.criticalRed),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text('Result *', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in ComplianceMapper.checkResults)
                      ChoiceChip(
                        label: Text(r.$2),
                        selected: _result == r.$1,
                        onSelected: (_) => setState(() {
                          _result = r.$1;
                          if (!ComplianceMapper.raiseFindingResults
                              .contains(_result)) {
                            _raiseFinding = false;
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _evidence,
                  decoration: InputDecoration(
                    labelText: 'Evidence',
                    hintText: 'Photo of door 12',
                    helperText: widget.check.evidenceRequired
                        ? 'This requirement cannot be signed off without evidence'
                        : 'Optional for this requirement',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                if (canRaise)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Raise a finding'),
                    subtitle: const Text(
                      'Opens a compliance finding from this failing check',
                    ),
                    value: _raiseFinding,
                    onChanged: (v) => setState(() => _raiseFinding = v),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: HandoverButton(
                      label: 'Cancel',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HandoverButton(
                      label: _saving ? 'Saving…' : 'Record check',
                      filled: true,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
