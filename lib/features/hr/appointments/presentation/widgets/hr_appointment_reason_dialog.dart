import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../controllers/hr_appointments_controller.dart';
import 'hr_appointments_common.dart';

/// "Decline this visit?" / "Cancel this appointment?" with the optional
/// reason. Resolves true once the request went through.
Future<bool> showHrAppointmentReasonDialog(
  BuildContext context, {
  required HrAppointmentsController controller,
  required HrAppointment appointment,
  required bool reject,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HrAppointmentReasonDialog(
      controller: controller,
      appointment: appointment,
      reject: reject,
    ),
  );
  return done == true;
}

class HrAppointmentReasonDialog extends StatefulWidget {
  final HrAppointmentsController controller;
  final HrAppointment appointment;
  final bool reject;

  const HrAppointmentReasonDialog({
    super.key,
    required this.controller,
    required this.appointment,
    required this.reject,
  });

  @override
  State<HrAppointmentReasonDialog> createState() => _HrAppointmentReasonDialogState();
}

class _HrAppointmentReasonDialogState extends State<HrAppointmentReasonDialog> {
  final _reason = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.controller.decide(
      widget.appointment,
      reject: widget.reject,
      reason: _reason.text,
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
    final a = widget.appointment;
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
              title: widget.reject ? 'Decline this visit?' : 'Cancel this appointment?',
              description: '${a.client} · ${a.requestedDate} ${a.time}',
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Container(
                      key: const ValueKey('appointment-reason-error'),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.criticalBackgroundSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: handoverText(context, 13.5, color: AppColors.criticalRed),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  HandoverTextArea(
                    key: const ValueKey('appointment-reason'),
                    label: 'Reason',
                    controller: _reason,
                    minLines: 3,
                    placeholder: 'The family reads this — say why in plain words.',
                    helper:
                        'Kept beside the request rather than over it, so what was asked for is still on file.',
                  ),
                ],
              ),
            ),
            HrAppointmentSheetFooter(
              children: [
                HandoverButton(
                  label: 'Keep it',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                HandoverButton(
                  key: const ValueKey('appointment-reason-submit'),
                  label: _saving
                      ? 'Saving…'
                      : widget.reject
                          ? 'Decline visit'
                          : 'Cancel appointment',
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
