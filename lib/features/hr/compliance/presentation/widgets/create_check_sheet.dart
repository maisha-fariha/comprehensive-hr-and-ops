import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/compliance.dart';
import '../controllers/compliance_controller.dart';
import 'compliance_common.dart';

Future<void> showCreateCheckSheet(
  BuildContext context, {
  required ComplianceController controller,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateCheckSheet(controller: controller),
  );
}

class CreateCheckSheet extends StatefulWidget {
  final ComplianceController controller;
  const CreateCheckSheet({super.key, required this.controller});

  @override
  State<CreateCheckSheet> createState() => _CreateCheckSheetState();
}

class _CreateCheckSheetState extends State<CreateCheckSheet> {
  String? _requirementId;
  String? _residenceId;
  DateTime? _dueAt;
  String? _error;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _error = null);
    if (_requirementId == null || _residenceId == null) {
      setState(() => _error = 'Pick a requirement and a home.');
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'requirementId': _requirementId,
      'residenceId': _residenceId,
      if (_dueAt != null) 'dueAt': _dueAt!.toUtc().toIso8601String(),
    };
    final err = await widget.controller.raiseCheck(body);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.show('Check raised', '', force: true);
  }

  @override
  Widget build(BuildContext context) {
    final requirements = widget.controller.requirements
        .where((r) => r.isActive)
        .toList();
    final residences = widget.controller.residences.toList();
    String reqLabel = 'Select requirement';
    for (final r in requirements) {
      if (r.id == _requirementId) reqLabel = r.name;
    }
    String homeLabel = 'Select residence';
    for (final r in residences) {
      if (r.id == _residenceId) homeLabel = r.name;
    }

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
                  child: Text(
                    'Raise a check',
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
                Text('Requirement *', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    if (requirements.isEmpty) {
                      setState(
                        () => _error =
                            'Add a requirement first before raising a check.',
                      );
                      return;
                    }
                    final picked =
                        await showCompliancePicker<ComplianceRequirement>(
                      context: context,
                      title: 'Requirement',
                      options: requirements,
                      labelOf: (o) => o.name,
                    );
                    if (picked != null) {
                      setState(() => _requirementId = picked.id);
                    }
                  },
                  child: ComplianceCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(reqLabel)),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Residence *', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked =
                        await showCompliancePicker<CompliancePersonOption>(
                      context: context,
                      title: 'Residence',
                      options: residences,
                      labelOf: (o) => o.name,
                    );
                    if (picked != null) {
                      setState(() => _residenceId = picked.id);
                    }
                  },
                  child: ComplianceCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(homeLabel)),
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
                    if (picked != null) {
                      setState(() => _dueAt = picked);
                    }
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
                      label: _saving ? 'Saving…' : 'Raise check',
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
