import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../controllers/hr_appointments_controller.dart';
import '../hr_appointments_labels.dart';
import 'hr_appointment_day_log_panel.dart';
import 'hr_appointment_reason_dialog.dart';
import 'hr_appointments_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Opens the web's request modal. Resolves to `true` when the user chose
/// Edit, so the caller can open the form.
Future<bool> showHrAppointmentDetailSheet(
  BuildContext context, {
  required HrAppointmentsController controller,
  required HrAppointment appointment,
}) async {
  final edit = await showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HrAppointmentDetailSheet(controller: controller, appointment: appointment),
  );
  return edit == true;
}

class HrAppointmentDetailSheet extends StatefulWidget {
  final HrAppointmentsController controller;
  final HrAppointment appointment;

  const HrAppointmentDetailSheet({
    super.key,
    required this.controller,
    required this.appointment,
  });

  @override
  State<HrAppointmentDetailSheet> createState() => _HrAppointmentDetailSheetState();
}

class _HrAppointmentDetailSheetState extends State<HrAppointmentDetailSheet> {
  bool _saving = false;

  HrAppointmentsController get _c => widget.controller;

  Future<void> _approve() async {
    setState(() => _saving = true);
    final error = await _c.approve(widget.appointment);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(false);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _decide({required bool reject}) async {
    final done = await showHrAppointmentReasonDialog(
      context,
      controller: _c,
      appointment: widget.appointment,
      reject: reject,
    );
    if (done && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final reviewed = a.deciderName == null
        ? 'Not decided yet'
        : '${a.deciderName}${a.decidedAt == null ? '' : ' · ${WebFormat.dateTime(a.decidedAt)}'}';
    const gap = SizedBox(height: 16);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            HrAppointmentSheetHeader(
              title: (a.purpose?.isNotEmpty ?? false) ? a.purpose! : a.typeLabel,
              description: '${a.reference} · ${a.client}',
              badges: [
                HrAppointmentPill(label: a.statusLabel, tone: HrAppointmentsLabels.statusTone(a.status)),
                HrAppointmentPill(label: a.typeLabel, tone: HrAppointmentsLabels.typeTone(a.type)),
              ],
            ),
            Expanded(
              child: ListView(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 14),
                children: [
                  HrAppointmentSection(
                    title: 'Resident & Requester',
                    children: [
                      HrAppointmentInfoGrid(
                        children: [
                          HrAppointmentInfo('Resident', a.client),
                          HrAppointmentInfo('Residence', a.residence),
                          HrAppointmentInfo('Requested By', a.requestedBy),
                          HrAppointmentInfo('Relationship', a.relationshipLabel),
                          if (a.requesterEmail != null) HrAppointmentInfo('Contact', a.requesterEmail),
                        ],
                      ),
                    ],
                  ),
                  gap,
                  HrAppointmentSection(
                    title: 'When & Where',
                    children: [
                      HrAppointmentInfoGrid(
                        children: [
                          HrAppointmentInfo('Date', a.requestedDate),
                          HrAppointmentInfo('Time', a.time),
                          HrAppointmentInfo('Location', a.location ?? 'Not set'),
                          HrAppointmentInfo('Reviewed By', reviewed),
                        ],
                      ),
                      if (a.decisionReason != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.filterButtonBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            a.decisionReason!,
                            style: handoverText(context, 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (a.purpose != null || a.notes != null) ...[
                    gap,
                    HrAppointmentSection(
                      title: 'What was asked for',
                      children: [
                        if (a.purpose != null) Text(a.purpose!, style: handoverText(context, 13.5)),
                        if (a.purpose != null && a.notes != null) const SizedBox(height: 8),
                        if (a.notes != null)
                          Text(a.notes!, style: handoverText(context, 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                  gap,
                  HandoverPanel(
                    padding: const EdgeInsets.all(16),
                    child: HrAppointmentDayLogPanel(
                      controller: _c,
                      clientId: a.clientId,
                      residenceId: a.residenceId ?? '',
                      clientName: a.client,
                    ),
                  ),
                ],
              ),
            ),
            HrAppointmentSheetFooter(children: _footer(a)),
          ],
        ),
      ),
    );
  }

  List<Widget> _footer(HrAppointment a) {
    final canWrite = _c.canWrite;
    return [
      HandoverButton(label: 'Close', onPressed: () => Navigator.of(context).pop(false)),
      if (canWrite && a.isLive)
        HandoverButton(
          key: const ValueKey('appointment-detail-cancel'),
          label: 'Cancel',
          icon: Icons.block_rounded,
          foreground: AppColors.criticalRed,
          onPressed: _saving ? null : () => _decide(reject: false),
        ),
      if (canWrite && a.isDecidable) ...[
        HandoverButton(
          key: const ValueKey('appointment-detail-reject'),
          label: 'Reject',
          icon: Icons.close_rounded,
          foreground: AppColors.criticalRed,
          onPressed: _saving ? null : () => _decide(reject: true),
        ),
        HandoverButton(
          key: const ValueKey('appointment-detail-approve'),
          label: 'Approve',
          icon: Icons.check_rounded,
          filled: true,
          onPressed: _saving ? null : _approve,
        ),
      ] else if (canWrite && a.isLive)
        HandoverButton(
          key: const ValueKey('appointment-detail-edit'),
          label: 'Edit',
          icon: Icons.edit_outlined,
          filled: true,
          onPressed: _saving ? null : () => Navigator.of(context).pop(true),
        ),
    ];
  }
}
