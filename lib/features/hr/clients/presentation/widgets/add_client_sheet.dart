import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../client_form.dart';
import '../clients_labels.dart';
import '../controllers/clients_controller.dart';
import 'client_form_sections.dart';
import 'clients_common.dart';

Future<bool?> showAddClientSheet(BuildContext context, ClientsController controller) =>
    showClientSheet<bool>(context, AddClientSheet(controller: controller));

/// Web "Add New Client" wizard: Basic Information, Residence Assignment,
/// Family / Guardian, Medical Information and Care Planning.
class AddClientSheet extends StatefulWidget {
  final ClientsController controller;

  const AddClientSheet({super.key, required this.controller});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _form = ClientForm();
  final _scroll = ScrollController();
  ClientStep _step = ClientStep.basic;
  Map<String, String> _errors = {};
  String? _error;
  bool _submitting = false;

  ClientsController get _c => widget.controller;

  @override
  void dispose() {
    _form.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _goTo(ClientStep step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    final errors = _form.validateStep(_step);
    setState(() => _errors = {..._errors}
      ..removeWhere((k, _) => ClientForm.stepOf(k) == _step)
      ..addAll(errors));
    if (errors.isNotEmpty) return;
    if (_step.index < ClientStep.values.length - 1) {
      _goTo(ClientStep.values[_step.index + 1]);
    }
  }

  Future<void> _create() async {
    final errors = _form.validateAll();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      _goTo(ClientForm.stepOf(errors.keys.first));
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await _c.createClient(_form);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final limited = _c.isLimitReached;
    final cap = _c.clientLimit.value;
    final index = _step.index;
    final total = ClientStep.values.length;
    final percent = (((index + 1) / total) * 100).round();
    return ClientSheetFrame(
      icon: Icons.person_add_alt_1_outlined,
      title: 'Add New Client',
      description: ClientsLabels.addDescription,
      scrollController: _scroll,
      statusBar: const ClientStatusBar(
        TextSpan(
          children: [
            TextSpan(
              text: '*',
              style: TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' ${ClientsLabels.addStatusBar}'),
          ],
        ),
      ),
      top: ClientStepChips(
        current: _step.name,
        onTap: (id) => _goTo(ClientStep.values.byName(id)),
        steps: [
          for (final s in ClientStep.values)
            (s.name, s.label, s.description, _form.stepComplete(s)),
        ],
      ),
      footerLeft: Text.rich(
        const TextSpan(
          children: [
            TextSpan(text: '*', style: TextStyle(color: AppColors.criticalRed)),
            TextSpan(text: ' Required fields'),
          ],
        ),
        style: handoverText(context, 12, color: AppColors.textMuted),
      ),
      footer: [
        if (index == 0)
          HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop())
        else
          HandoverButton(
            key: const ValueKey('add-client-back'),
            label: 'Back',
            onPressed: () => _goTo(ClientStep.values[index - 1]),
          ),
        HandoverButton(
          key: const ValueKey('add-client-draft'),
          label: 'Save Draft',
          onPressed: _submitting || limited ? null : _submit,
        ),
        if (_step == ClientStep.care)
          HandoverButton(
            key: const ValueKey('add-client-create'),
            label: limited ? 'Limit Exceeded' : 'Create Client',
            filled: true,
            onPressed: _submitting || limited ? null : _create,
          )
        else
          HandoverButton(
            key: const ValueKey('add-client-next'),
            label: 'Next',
            filled: true,
            onPressed: _next,
          ),
      ],
      children: [
        ClientProgressCard(
          caption: 'Completion',
          trailing: 'Step ${index + 1} of $total',
          fraction: (index + 1) / total,
          line: '$percent% complete',
          lineAccent: true,
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[ClientBanner(_error!), const SizedBox(height: 12)],
        if (limited) ...[
          ClientBanner(
            'Plan limit reached${cap == null ? '' : ' (${_c.limitCount}/$cap clients)'}. '
            'You cannot create additional clients on your current plan.',
            warning: true,
          ),
          const SizedBox(height: 12),
        ],
        switch (_step) {
          ClientStep.basic => ClientBasicSection(
              form: _form,
              errors: _errors,
              enabled: true,
              onChanged: _changed,
            ),
          ClientStep.residence => ClientResidenceSection(
              form: _form,
              errors: _errors,
              enabled: true,
              residenceOptions: [
                for (final id in _c.residenceOptions) (id, _c.residenceLabel(id)),
              ],
              roomsFor: _c.roomsFor,
              onChanged: _changed,
            ),
          ClientStep.family => ClientGuardianSection(
              form: _form,
              errors: _errors,
              onChanged: _changed,
            ),
          ClientStep.medical => ClientMedicalSection(
              form: _form,
              enabled: true,
              onChanged: _changed,
            ),
          ClientStep.care => ClientCareSection(
              form: _form,
              enabled: true,
              onChanged: _changed,
            ),
        },
      ],
    );
  }
}
