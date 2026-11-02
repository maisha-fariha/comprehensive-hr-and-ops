import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/compliance.dart';
import '../controllers/compliance_controller.dart';
import 'compliance_common.dart';

Future<void> showCreateActionSheet(
  BuildContext context, {
  required ComplianceController controller,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateActionSheet(controller: controller),
  );
}

class CreateActionSheet extends StatefulWidget {
  final ComplianceController controller;
  const CreateActionSheet({super.key, required this.controller});

  @override
  State<CreateActionSheet> createState() => _CreateActionSheetState();
}

class _CreateActionSheetState extends State<CreateActionSheet> {
  final _description = TextEditingController();
  String? _incidentId;
  String? _ownerId;
  DateTime? _dueAt;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final missing = <String>[];
    if (_incidentId == null || _incidentId!.isEmpty) missing.add('incidentId');
    if (_description.text.trim().isEmpty) missing.add('description');
    if (missing.isNotEmpty) {
      setState(() {
        _error =
            '${missing.length} fields still need attention — ${missing.join(', ')}';
      });
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'incidentId': _incidentId,
      'description': _description.text.trim(),
      if (_ownerId != null && _ownerId!.isNotEmpty) 'ownerId': _ownerId,
      if (_dueAt != null) 'dueAt': _dueAt!.toUtc().toIso8601String(),
    };
    final err = await widget.controller.createAction(body);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.show('Corrective action added', '', force: true);
  }

  @override
  Widget build(BuildContext context) {
    final findings = widget.controller.findings.toList();
    final staff = widget.controller.staffOptions.toList();
    String findingLabel = 'Link finding / incident *';
    for (final f in findings) {
      if (f.id == _incidentId) findingLabel = f.title;
    }
    String ownerLabel = 'Owner (optional)';
    for (final s in staff) {
      if (s.id == _ownerId) ownerLabel = s.name;
    }

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
                    'New corrective action',
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
                Text(
                  'Linked finding / incident *',
                  style: handoverText(context, 12.5),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    if (findings.isEmpty) {
                      setState(
                        () => _error =
                            'Raise a finding first, then link the action to it.',
                      );
                      return;
                    }
                    final picked =
                        await showCompliancePicker<ComplianceFinding>(
                      context: context,
                      title: 'Finding',
                      options: findings,
                      labelOf: (o) => o.title,
                    );
                    if (picked != null) {
                      setState(() => _incidentId = picked.id);
                    }
                  },
                  child: ComplianceCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(findingLabel)),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'What will be done *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Owner', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked =
                        await showCompliancePicker<CompliancePersonOption>(
                      context: context,
                      title: 'Owner',
                      options: [
                        const CompliancePersonOption(id: '', name: 'Unassigned'),
                        ...staff,
                      ],
                      labelOf: (o) => o.name,
                    );
                    if (picked != null) {
                      setState(
                        () => _ownerId =
                            picked.id.isEmpty ? null : picked.id,
                      );
                    }
                  },
                  child: ComplianceCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(ownerLabel)),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Due date (optional)', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueAt ?? now,
                      firstDate: now.subtract(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) setState(() => _dueAt = picked);
                  },
                  child: ComplianceCard(
                    child: Text(
                      _dueAt == null
                          ? 'Pick a due date'
                          : '${_dueAt!.year}-${_dueAt!.month.toString().padLeft(2, '0')}-${_dueAt!.day.toString().padLeft(2, '0')}',
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
                      label: _saving ? 'Saving…' : 'Create action',
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
