import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';

Future<void> showCreateRequirementSheet(
  BuildContext context, {
  required ComplianceController controller,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateRequirementSheet(controller: controller),
  );
}

class CreateRequirementSheet extends StatefulWidget {
  final ComplianceController controller;
  const CreateRequirementSheet({super.key, required this.controller});

  @override
  State<CreateRequirementSheet> createState() => _CreateRequirementSheetState();
}

class _CreateRequirementSheetState extends State<CreateRequirementSheet> {
  final _name = TextEditingController();
  final _standard = TextEditingController();
  final _category = TextEditingController();
  final _frequencyNote = TextEditingController();
  final _instructions = TextEditingController();
  String _frequency = 'quarterly';
  String _priority = 'medium';
  bool _evidenceRequired = false;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _standard.dispose();
    _category.dispose();
    _frequencyNote.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the requirement a name.');
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'frequency': _frequency,
      'priority': _priority,
      'evidenceRequired': _evidenceRequired,
      if (_standard.text.trim().isNotEmpty) 'standard': _standard.text.trim(),
      if (_category.text.trim().isNotEmpty) 'category': _category.text.trim(),
      if (_frequencyNote.text.trim().isNotEmpty)
        'frequencyNote': _frequencyNote.text.trim(),
      if (_instructions.text.trim().isNotEmpty)
        'instructions': _instructions.text.trim(),
    };
    final err = await widget.controller.createRequirement(body);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.show('Requirement added', '', force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
                  child: Text(
                    'Add requirement',
                    style: handoverText(context, 16, weight: FontWeight.w700),
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
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _standard,
                  decoration: InputDecoration(
                    labelText: 'Standard (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _category,
                  decoration: InputDecoration(
                    labelText: 'Applies to / category (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('How often', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in ComplianceMapper.frequencies)
                      ChoiceChip(
                        label: Text(f.$2),
                        selected: _frequency == f.$1,
                        onSelected: (_) => setState(() => _frequency = f.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _frequencyNote,
                  decoration: InputDecoration(
                    labelText: 'Frequency note (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Priority', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in ComplianceMapper.priorities)
                      ChoiceChip(
                        label: Text(p.$2),
                        selected: _priority == p.$1,
                        onSelected: (_) => setState(() => _priority = p.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Evidence required'),
                  value: _evidenceRequired,
                  onChanged: (v) => setState(() => _evidenceRequired = v),
                ),
                TextField(
                  controller: _instructions,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Instructions (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HandoverButton(
                      label: _saving ? 'Saving…' : 'Add requirement',
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
