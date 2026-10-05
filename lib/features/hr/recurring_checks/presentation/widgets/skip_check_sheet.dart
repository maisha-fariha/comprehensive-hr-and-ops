import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/recurring_check.dart';
import '../controllers/recurring_checks_controller.dart';
import 'check_common.dart';

Future<void> showSkipCheckSheet(
  BuildContext context, {
  required RecurringChecksController controller,
  required CheckInstance instance,
}) =>
    showCheckSheet<void>(
      context,
      (_) => _SkipCheckSheet(controller: controller, instance: instance),
    );

class _SkipCheckSheet extends StatefulWidget {
  final RecurringChecksController controller;
  final CheckInstance instance;

  const _SkipCheckSheet({required this.controller, required this.instance});

  @override
  State<_SkipCheckSheet> createState() => _SkipCheckSheetState();
}

class _SkipCheckSheetState extends State<_SkipCheckSheet> {
  final _why = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final note = _why.text.trim();
    if (note.isEmpty) {
      setState(() => _error = 'Say why the check could not be done.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.skipInstance(widget.instance, note);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.instance;
    return CheckSheetScaffold(
      icon: Icons.skip_next_outlined,
      title: 'Skip this check',
      description: '${i.checkName ?? 'Check'} · ${i.clientName ?? 'Resident'}',
      primaryKey: const ValueKey('skip-check-submit'),
      primaryLabel: _saving ? 'Saving…' : 'Skip check',
      onPrimary: _saving ? null : _submit,
      children: [
        if (_error != null)
          CheckNotice(
            child: Text(
              _error!,
              style: handoverText(context, 13.5, color: AppColors.criticalRed),
            ),
          ),
        HandoverTextArea(
          key: const ValueKey('skip-check-why'),
          label: 'Why',
          required: true,
          controller: _why,
          placeholder: 'e.g. Resident was out at a hospital appointment',
        ),
      ],
    );
  }
}
