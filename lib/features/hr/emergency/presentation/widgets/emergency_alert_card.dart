import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/emergency_alert.dart';
import '../emergency_labels.dart';

/// One alarm row on the web board: pills, who raised it and where, the note,
/// house line, acknowledgement, resolution and the row actions.
class EmergencyAlertCard extends StatelessWidget {
  final EmergencyAlert alert;
  final bool busy;
  final bool canRespond;
  final VoidCallback onOpen;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onDelete;

  const EmergencyAlertCard({
    super.key,
    required this.alert,
    required this.busy,
    required this.canRespond,
    required this.onOpen,
    required this.onAcknowledge,
    required this.onResolve,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final a = alert;
    final muted = handoverText(context, 13, color: AppColors.textMuted);
    final small = handoverText(context, 12.5, color: AppColors.textMuted);
    final raisedBy = [
      'Raised by ${a.raiser?.name ?? 'unknown'}',
      if (a.raiser?.phone != null) a.raiser!.phone!,
      if (a.createdAt != null) WebFormat.dateTime(a.createdAt),
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: a.isActive
            ? AppColors.criticalBackgroundSoft
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: a.isActive ? AppColors.criticalRed : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AttendancePill(
                label: EmergencyLabels.status(a.status),
                tone: EmergencyLabels.statusTone(a.status),
                dot: true,
              ),
              if (a.priority != null && a.priority != 'standard')
                AttendancePill(
                  label: EmergencyLabels.priority(a.priority!),
                  tone: EmergencyLabels.priorityTone(a.priority!),
                ),
              AttendancePill(
                label: EmergencyLabels.type(a.type),
                tone: AttendanceTone.neutral,
              ),
              Text(
                a.residenceName ?? 'Unknown residence',
                style: handoverText(
                  context,
                  13.5,
                  weight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(raisedBy, style: muted),
          if (a.clientName != null) Text('Resident: ${a.clientName}', style: muted),
          if (a.locationNote != null) Text('Where: ${a.locationNote}', style: muted),
          if (a.assignee?.name != null)
            Text('Assigned to ${a.assignee!.name}', style: muted),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HandoverButton(
                key: ValueKey('emergency-open-${a.id}'),
                label: 'Open',
                compact: true,
                onPressed: onOpen,
              ),
              if (canRespond && a.isOpen) ...[
                if (a.isActive)
                  HandoverButton(
                    key: ValueKey('emergency-acknowledge-${a.id}'),
                    label: 'Acknowledge',
                    compact: true,
                    onPressed: busy ? null : onAcknowledge,
                  ),
                HandoverButton(
                  key: ValueKey('emergency-resolve-${a.id}'),
                  label: 'Resolve',
                  compact: true,
                  filled: true,
                  onPressed: busy ? null : onResolve,
                ),
              ],
              if (canRespond)
                Semantics(
                  label: 'Delete alert',
                  button: true,
                  child: HandoverButton(
                    key: ValueKey('emergency-delete-${a.id}'),
                    label: '',
                    icon: Icons.delete_outline_rounded,
                    foreground: AppColors.criticalRed,
                    compact: true,
                    onPressed: busy ? null : onDelete,
                  ),
                ),
            ],
          ),
          if (a.note != null) ...[
            const SizedBox(height: 10),
            Text(a.note!, style: handoverText(context, 13.5)),
          ],
          if (a.houseLine != null) ...[
            const SizedBox(height: 6),
            Text('House line: ${a.houseLine}', style: small),
          ],
          if (a.acknowledger?.name != null)
            Text(
              'Acknowledged by ${a.acknowledger!.name}'
              '${a.acknowledgedAt == null ? '' : ' · ${WebFormat.dateTime(a.acknowledgedAt)}'}',
              style: small,
            ),
          if (a.resolutionNote != null)
            Text('Resolution: ${a.resolutionNote}', style: small),
        ],
      ),
    );
  }
}
