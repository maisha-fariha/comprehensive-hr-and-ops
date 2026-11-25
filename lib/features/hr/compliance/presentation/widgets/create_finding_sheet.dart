import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../../domain/entities/compliance.dart';
import '../controllers/compliance_controller.dart';
import 'compliance_common.dart';

Future<void> showCreateFindingSheet(
  BuildContext context, {
  required ComplianceController controller,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateFindingSheet(controller: controller),
  );
}

class CreateFindingSheet extends StatefulWidget {
  final ComplianceController controller;
  const CreateFindingSheet({super.key, required this.controller});

  @override
  State<CreateFindingSheet> createState() => _CreateFindingSheetState();
}

class _CreateFindingSheetState extends State<CreateFindingSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _risk = TextEditingController();
  final _corrective = TextEditingController();
  String _severity = 'medium';
  String? _residenceId;
  String? _clientId;
  String? _issueOrigin;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _risk.dispose();
    _corrective.dispose();
    super.dispose();
  }

  Future<void> _save({bool resolved = false}) async {
    setState(() => _error = null);
    final missing = <String>[];
    if (_title.text.trim().isEmpty) missing.add('title');
    if (_residenceId == null || _residenceId!.isEmpty) missing.add('residenceId');
    if (_notes.text.trim().isEmpty) missing.add('description');
    if (missing.isNotEmpty) {
      setState(() {
        _error =
            '${missing.length} fields still need attention — ${missing.join(', ')}';
      });
      return;
    }
    setState(() => _saving = true);
    await widget.controller.loadClientsForResidence(_residenceId);
    final body = <String, dynamic>{
      'residenceId': _residenceId,
      'title': _title.text.trim(),
      'severity': _severity,
      'notes': _notes.text.trim(),
      if (_clientId != null && _clientId!.isNotEmpty) 'clientId': _clientId,
      if (_issueOrigin != null && _issueOrigin!.isNotEmpty)
        'issueOrigin': _issueOrigin,
      if (_risk.text.trim().isNotEmpty) 'riskContext': _risk.text.trim(),
    };
    final err = await widget.controller.raiseFinding(
      body,
      status: resolved ? 'resolved' : 'open',
      correctiveActionDescription: _corrective.text.trim().isEmpty
          ? null
          : _corrective.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.show(
      resolved ? 'Finding saved as resolved' : 'Finding raised',
      '',
      force: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final residences = widget.controller.residences.toList();
    String residenceLabel = 'Select residence';
    for (final r in residences) {
      if (r.id == _residenceId) residenceLabel = r.name;
    }
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
                const Icon(Icons.shield_outlined, color: AppColors.secondaryTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Compliance Finding',
                        style: handoverText(context, 16, weight: FontWeight.w700),
                      ),
                      Text(
                        'Record compliance issues, assign corrective actions, and track resolution progress.',
                        style: handoverText(
                          context,
                          12,
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
              child: ComplianceCard(
                child: Text(
                  _error!,
                  style: handoverText(context, 12.5, color: AppColors.criticalRed),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  'What was found, and which home it concerns',
                  style: handoverText(context, 14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text('Title *', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    hintText: 'e.g. Fire door inspection — not met',
                    errorText: _title.text.isEmpty && _error != null
                        ? 'Give the finding a title'
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Residence *', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showCompliancePicker<CompliancePersonOption>(
                      context: context,
                      title: 'Residence',
                      options: residences,
                      labelOf: (o) => o.name,
                    );
                    if (picked != null) {
                      setState(() {
                        _residenceId = picked.id;
                        _clientId = null;
                      });
                      await widget.controller.loadClientsForResidence(picked.id);
                      if (mounted) setState(() {});
                    }
                  },
                  child: ComplianceCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(residenceLabel)),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                if (_residenceId == null && _error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Residence is required',
                      style: handoverText(
                        context,
                        12,
                        color: AppColors.criticalRed,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Standard (optional)',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                ComplianceCard(
                  child: Text(
                    'No standards configured yet — add them in Settings',
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Related resident (optional)', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _residenceId == null
                      ? null
                      : () async {
                          final clients = widget.controller.clients.toList();
                          final picked =
                              await showCompliancePicker<CompliancePersonOption>(
                            context: context,
                            title: 'Resident',
                            options: [
                              const CompliancePersonOption(id: '', name: 'None'),
                              ...clients,
                            ],
                            labelOf: (o) => o.name,
                          );
                          if (picked != null) {
                            setState(() => _clientId =
                                picked.id.isEmpty ? null : picked.id);
                          }
                        },
                  child: ComplianceCard(
                    child: Text(
                      () {
                        if (_clientId == null) {
                          return 'Search related resident (optional)';
                        }
                        for (final c in widget.controller.clients) {
                          if (c.id == _clientId) return c.name;
                        }
                        return 'Resident';
                      }(),
                      style: handoverText(context, 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('How it surfaced', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final options = ComplianceMapper.issueOrigins;
                    final picked = await showCompliancePicker<(String, String)>(
                      context: context,
                      title: 'How it surfaced',
                      options: options,
                      labelOf: (o) => o.$2,
                    );
                    if (picked != null) {
                      setState(() => _issueOrigin = picked.$1);
                    }
                  },
                  child: ComplianceCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _issueOrigin == null
                                ? 'Select how this came to light'
                                : ComplianceMapper.label(_issueOrigin!),
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Severity *', style: handoverText(context, 13, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final s in ComplianceMapper.severities) ...[
                  _SeverityTile(
                    value: s.$1,
                    label: s.$2,
                    hint: s.$3,
                    selected: _severity == s.$1,
                    onTap: () => setState(() => _severity = s.$1),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Text('Why it matters / what was found *', style: handoverText(context, 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: _notes,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'The risk this creates, in your own words...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _risk,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Risk context (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Corrective action (optional)',
                  style: handoverText(context, 12.5),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _corrective,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'What will be done',
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
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  HandoverButton(
                    label: 'Cancel',
                    compact: true,
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                  HandoverButton(
                    label: _saving ? 'Saving…' : 'Save as resolved',
                    compact: true,
                    icon: Icons.check_circle_outline,
                    onPressed: _saving ? null : () => _save(resolved: true),
                  ),
                  HandoverButton(
                    label: _saving ? 'Saving…' : 'Raise finding',
                    filled: true,
                    compact: true,
                    onPressed: _saving ? null : () => _save(),
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

class _SeverityTile extends StatelessWidget {
  final String value;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _SeverityTile({
    required this.value,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.secondaryTeal.withValues(alpha: 0.08)
          : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.urgentAmber : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: handoverText(context, 14, weight: FontWeight.w700)),
                    Text(hint, style: handoverText(context, 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.activeGreen),
            ],
          ),
        ),
      ),
    );
  }
}
