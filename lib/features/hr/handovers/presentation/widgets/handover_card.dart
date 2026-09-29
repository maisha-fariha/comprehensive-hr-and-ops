import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../domain/entities/shift_handover.dart';
import '../handover_labels.dart';
import 'handover_common.dart';

/// One handover on the web list: header pills, summary, residents, jobs,
/// who has taken it and the row actions.
class HandoverCard extends StatelessWidget {
  final ShiftHandover handover;
  final bool busy;
  final bool canSubmit;
  final bool canTake;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onSubmit;
  final VoidCallback onTake;
  final VoidCallback onDelete;

  const HandoverCard({
    super.key,
    required this.handover,
    required this.busy,
    required this.canSubmit,
    required this.canTake,
    required this.canDelete,
    required this.onOpen,
    required this.onSubmit,
    required this.onTake,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final h = handover;
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8));
    final acknowledgements = h.acknowledgements.isEmpty
        ? 'Nobody has confirmed picking this up yet.'
        : h.acknowledgements
            .map((a) =>
                '${a.staffFirstName ?? a.userName ?? 'Someone'}'
                '${a.createdAt == null ? '' : ' at ${WebFormat.time(a.createdAt)}'}')
            .join(' · ');

    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                h.residenceName ?? 'Unknown residence',
                style: handoverText(
                  context,
                  13.5,
                  weight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
              AttendancePill(
                label: HandoverLabels.status(h.status),
                tone: HandoverLabels.statusTone(h.status),
              ),
              if (h.alertingCount > 0)
                AttendancePill(
                  label: '${h.alertingCount} needing attention',
                  tone: AttendanceTone.danger,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${h.authorName ?? 'Unknown'}'
            '${h.createdAt == null ? '' : ' · ${WebFormat.dateTime(h.createdAt)}'}',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          gap,
          InkWell(
            key: ValueKey('handover-open-${h.id}'),
            onTap: onOpen,
            child: Text(
              h.summary,
              style: handoverText(context, 13.5, decoration: TextDecoration.underline)
                  .copyWith(decorationColor: AppColors.cardBorder),
            ),
          ),
          if (h.clientUpdates.isNotEmpty) ...[
            gap,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final update in h.clientUpdates)
                  AttendancePill(
                    label: update.clientName ?? 'Client',
                    tone: HandoverLabels.clientTone(update.status),
                  ),
              ],
            ),
          ],
          if (h.incidents.isNotEmpty) ...[
            gap,
            Text(
              'Incidents on this shift: '
              '${h.incidents.map((i) => i.reference ?? i.title ?? 'one').join(', ')}',
              style: handoverText(context, 12.5, color: AppColors.criticalRed),
            ),
          ],
          if (h.tasks.isNotEmpty) ...[
            gap,
            for (final task in h.tasks) _TaskRow(task: task),
          ] else if (h.pendingActions.isNotEmpty) ...[
            gap,
            for (final action in h.pendingActions)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $action',
                  style: handoverText(context, 13, color: AppColors.textSecondary),
                ),
              ),
          ],
          gap,
          const Divider(height: 1, color: AppColors.cardBorder),
          gap,
          Text(
            acknowledgements,
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          if (canSubmit || canTake || canDelete) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (canSubmit)
                  HandoverButton(
                    key: ValueKey('handover-submit-${h.id}'),
                    label: 'Submit handover',
                    filled: true,
                    compact: true,
                    onPressed: busy ? null : onSubmit,
                  )
                else if (canTake)
                  HandoverButton(
                    key: ValueKey('handover-take-${h.id}'),
                    label: "I've read and taken this",
                    compact: true,
                    onPressed: busy ? null : onTake,
                  ),
                if (canDelete)
                  HandoverButton(
                    key: ValueKey('handover-delete-${h.id}'),
                    label: '',
                    icon: Icons.delete_outline_rounded,
                    foreground: AppColors.criticalRed,
                    compact: true,
                    onPressed: busy ? null : onDelete,
                  ),
              ],
            ),
          ],
          if (h.flagCategory != null) ...[
            gap,
            AttendancePill(
              label: 'Flagged: ${WebFormat.humanise(h.flagCategory)}',
              tone: AttendanceTone.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final HandoverTask task;

  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final who = task.assigneeFirstNames.join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: handoverText(
                context,
                13,
                color: task.done ? AppColors.textMuted : AppColors.textHeading,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            who.isEmpty ? 'nobody yet' : who,
            style: handoverText(context, 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          AttendancePill(
            label: WebFormat.humanise(task.status),
            tone: task.done ? AttendanceTone.success : AttendanceTone.warning,
          ),
        ],
      ),
    );
  }
}
