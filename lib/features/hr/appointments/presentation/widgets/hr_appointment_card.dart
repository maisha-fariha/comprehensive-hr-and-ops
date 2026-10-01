import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../hr_appointments_labels.dart';
import 'hr_appointments_common.dart';

enum HrAppointmentAction { view, approve, reject, edit, cancel, delete }

/// One register row: the web table's columns stacked into a card, with the
/// same "Row actions" menu.
class HrAppointmentCard extends StatelessWidget {
  final HrAppointment appointment;
  final bool canWrite;
  final bool busy;
  final ValueChanged<HrAppointmentAction> onAction;

  const HrAppointmentCard({
    super.key,
    required this.appointment,
    required this.canWrite,
    required this.busy,
    required this.onAction,
  });

  /// Menu entries in the web's order and gating.
  static List<HrAppointmentAction> actionsFor(HrAppointment a, {required bool canWrite}) => [
        HrAppointmentAction.view,
        if (canWrite && a.isDecidable) ...[
          HrAppointmentAction.approve,
          HrAppointmentAction.reject,
        ],
        if (canWrite && a.isLive) ...[
          HrAppointmentAction.edit,
          HrAppointmentAction.cancel,
        ],
        if (canWrite) HrAppointmentAction.delete,
      ];

  static (String, IconData?, bool) _menuItem(HrAppointmentAction action) => switch (action) {
        HrAppointmentAction.view => ('View Details', null, false),
        HrAppointmentAction.approve => ('Approve', Icons.check_rounded, false),
        HrAppointmentAction.reject => ('Reject', Icons.close_rounded, false),
        HrAppointmentAction.edit => ('Edit', Icons.edit_outlined, false),
        HrAppointmentAction.cancel => ('Cancel', Icons.block_rounded, true),
        HrAppointmentAction.delete => ('Delete', Icons.delete_outline_rounded, true),
      };

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final muted = handoverText(context, 12, color: AppColors.textMuted);
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey('appointment-row-${a.id}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => onAction(HrAppointmentAction.view),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 6, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.reference,
                            style: handoverText(context, 14, weight: FontWeight.w600, color: AppColors.primaryNavy),
                          ),
                          Text(a.residence, style: muted),
                        ],
                      ),
                    ),
                    PopupMenuButton<HrAppointmentAction>(
                      key: ValueKey('appointment-menu-${a.id}'),
                      tooltip: 'Row actions',
                      enabled: !busy,
                      color: AppColors.surfaceWhite,
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                      onSelected: onAction,
                      itemBuilder: (_) => [
                        for (final action in actionsFor(a, canWrite: canWrite))
                          PopupMenuItem(
                            value: action,
                            child: Builder(
                              builder: (context) {
                                final (label, icon, destructive) = _menuItem(action);
                                final color = destructive ? AppColors.criticalRed : AppColors.textHeading;
                                return Row(
                                  children: [
                                    if (icon != null) ...[
                                      Icon(icon, size: 14, color: color),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(label, style: handoverText(context, 13.5, color: color)),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          HrAppointmentPill(label: a.typeLabel, tone: HrAppointmentsLabels.typeTone(a.type)),
                          HrAppointmentPill(label: a.statusLabel, tone: HrAppointmentsLabels.statusTone(a.status)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      HrAppointmentInfoGrid(
                        children: [
                          HrAppointmentInfo('Resident', a.client),
                          _Stacked(label: 'Requested By', value: a.requestedBy, sub: a.relationshipLabel),
                          HrAppointmentInfo('Date', a.requestedDate),
                          HrAppointmentInfo('Time', a.time),
                          HrAppointmentInfo('Purpose', a.purposeColumn),
                          _Stacked(
                            label: 'Reviewed By',
                            value: a.deciderName ?? '—',
                            sub: a.decisionReason,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stacked extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _Stacked({required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HrAppointmentInfo(label, value),
        if (sub != null && sub!.isNotEmpty)
          Text(sub!, style: handoverText(context, 12, color: AppColors.textMuted)),
      ],
    );
  }
}
