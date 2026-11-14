import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_outing.dart';
import '../controllers/hr_appointments_controller.dart';
import 'hr_appointments_common.dart';

/// Web approve / decline outing modal (`POST /outings/:id/decide`).
Future<bool> showHrOutingDecideDialog(
  BuildContext context, {
  required HrAppointmentsController controller,
  required HrOuting outing,
  required bool approve,
}) async {
  final done = await showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HrOutingDecideDialog(
      controller: controller,
      outing: outing,
      approve: approve,
    ),
  );
  return done == true;
}

class HrOutingDecideDialog extends StatefulWidget {
  final HrAppointmentsController controller;
  final HrOuting outing;
  final bool approve;

  const HrOutingDecideDialog({
    super.key,
    required this.controller,
    required this.outing,
    required this.approve,
  });

  @override
  State<HrOutingDecideDialog> createState() => _HrOutingDecideDialogState();
}

class _HrOutingDecideDialogState extends State<HrOutingDecideDialog> {
  final _notes = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.controller.decideOuting(
      widget.outing,
      approve: widget.approve,
      notes: _notes.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final approve = widget.approve;
    final o = widget.outing;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HrAppointmentSheetHeader(
              title: approve ? 'Approve outing' : 'Decline outing',
              description: o.title,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Container(
                      key: const ValueKey('outing-decide-error'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.criticalBackgroundSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: handoverText(
                          context,
                          13.5,
                          color: AppColors.criticalRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  HandoverTextArea(
                    key: const ValueKey('outing-decide-notes'),
                    label: approve ? 'Conditions (optional)' : 'Reason',
                    controller: _notes,
                    required: !approve,
                    minLines: 3,
                    placeholder: approve
                        ? 'e.g. Back by 9pm; collect the medication pack at reception'
                        : 'e.g. GP review that afternoon — could we move it to Sunday?',
                    helper: approve
                        ? null
                        : 'Required — the family reads this.',
                  ),
                ],
              ),
            ),
            HrAppointmentSheetFooter(
              children: [
                HandoverButton(
                  label: 'Cancel',
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                ),
                HandoverButton(
                  key: const ValueKey('outing-decide-submit'),
                  label: _saving
                      ? 'Saving…'
                      : (approve ? 'Approve' : 'Decline'),
                  filled: true,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
