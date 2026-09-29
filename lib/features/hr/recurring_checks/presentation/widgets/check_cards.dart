import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/recurring_check.dart';
import '../recurring_checks_labels.dart';

/// One occurrence on the Due tab.
class DueCheckCard extends StatelessWidget {
  final CheckInstance instance;
  final bool late;
  final bool locked;
  final bool canComplete;
  final bool busy;
  final VoidCallback onAssign;
  final VoidCallback onRecord;
  final VoidCallback onSkip;

  const DueCheckCard({
    super.key,
    required this.instance,
    required this.late,
    required this.locked,
    required this.canComplete,
    required this.busy,
    required this.onAssign,
    required this.onRecord,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final i = instance;
    final muted = handoverText(context, 12.5, color: AppColors.textMuted);
    final warning = handoverText(context, 12, color: AppColors.urgentAmber);
    final assignee = i.assignedStaffName != null
        ? 'Assigned to ${i.assignedStaffName}'
        : i.assignedRole != null
            ? '${CheckLabels.humanise(i.assignedRole!)} on shift'
            : 'Whoever is on shift';
    final showActions = canComplete && i.open;
    return HandoverPanel(
      borderColor: late ? AppColors.urgentAmber.withValues(alpha: 0.4) : AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                i.checkName ?? 'Check',
                style: handoverText(context, 14, weight: FontWeight.w600,
                    color: AppColors.primaryNavy),
              ),
              AttendancePill(
                label: CheckLabels.humanise(i.status),
                tone: CheckLabels.statusTone(i.status),
              ),
              if (late) const AttendancePill(label: 'Late', tone: AttendanceTone.warning),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${i.clientName ?? 'Resident'}'
            '${i.roomNumber != null ? ' · Room ${i.roomNumber}' : ''}'
            ' · due ${WebFormat.dateTime(i.dueAt.toLocal())}',
            style: muted,
          ),
          const SizedBox(height: 2),
          Text(assignee, style: handoverText(context, 12, color: AppColors.textMuted)),
          if (i.status == 'needs_assignment')
            Text(
              i.assignedStaffName != null
                  ? '${i.assignedStaffName} is not on shift when this falls due.'
                  : 'Nobody is on shift when this falls due.',
              style: warning,
            ),
          if (locked)
            Text(
              'Assigned to ${i.assignedStaffName ?? 'somebody else'}'
              ' — reassign it before recording or skipping.',
              style: warning,
            ),
          if (showActions) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (i.status == 'needs_assignment' || locked)
                  HandoverButton(
                    key: ValueKey('check-assign-${i.id}'),
                    label: 'Assign',
                    icon: Icons.person_add_alt_1_outlined,
                    filled: true,
                    compact: true,
                    onPressed: busy ? null : onAssign,
                  ),
                HandoverButton(
                  key: ValueKey('check-record-${i.id}'),
                  label: 'Record',
                  icon: Icons.assignment_turned_in_outlined,
                  filled: true,
                  compact: true,
                  onPressed: locked || busy ? null : onRecord,
                ),
                HandoverButton(
                  key: ValueKey('check-skip-${i.id}'),
                  label: 'Skip',
                  icon: Icons.skip_next_outlined,
                  compact: true,
                  onPressed: locked || busy ? null : onSkip,
                ),
              ],
            ),
          ],
          if (i.entry != null) ...[
            const SizedBox(height: 10),
            _EntryBox(entry: i.entry!),
          ],
          if (i.statusNote != null && i.statusNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: '${CheckLabels.humanise(i.status)}: ${i.statusNote}',
                children: [
                  if (i.statusOnDuty == false)
                    TextSpan(
                      text: '  (off duty)',
                      style: handoverText(context, 12.5,
                          weight: FontWeight.w600, color: AppColors.criticalRed),
                    ),
                ],
              ),
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryBox extends StatelessWidget {
  final CheckEntry entry;

  const _EntryBox({required this.entry});

  @override
  Widget build(BuildContext context) {
    final readings = entry.result.entries.where((e) => !e.key.endsWith('Unit'));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.note, style: handoverText(context, 12.5)),
          const SizedBox(height: 2),
          Text(
            '${entry.staffName ?? 'Unknown'}'
            '${entry.checkedAt != null ? ' · ${WebFormat.dateTime(entry.checkedAt!.toLocal())}' : ''}',
            style: handoverText(context, 11.5, color: AppColors.textMuted),
          ),
          if (readings.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in readings)
                  AttendancePill(
                    label: '${r.key}: ${r.value}'
                        '${entry.result['${r.key}Unit'] is String ? ' ${entry.result['${r.key}Unit']}' : ''}',
                    tone: AttendanceTone.neutral,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One recorded check on the Checks tab.
class RecordedCheckCard extends StatelessWidget {
  final CheckEntry entry;

  const RecordedCheckCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final outcome = e.outcome ?? 'normal';
    final readings = e.result.entries
        .where((r) => r.value != null && r.value != '')
        .map((r) => '${r.key.replaceAll('_', ' ')}: ${r.value}')
        .join(' · ');
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                e.checkName ?? 'Check',
                style: handoverText(context, 14, weight: FontWeight.w600,
                    color: AppColors.primaryNavy),
              ),
              AttendancePill(
                label: CheckLabels.outcome(outcome),
                tone: CheckLabels.outcomeTone(outcome),
              ),
              if (e.recordedOnDuty == false)
                const AttendancePill(label: 'Off duty', tone: AttendanceTone.warning),
              if (e.coveredForName != null)
                AttendancePill(
                  label: 'Covered for ${e.coveredForName}',
                  tone: AttendanceTone.info,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${e.staffName ?? 'Unknown'}'
            '${e.checkedAt != null ? ' · ${WebFormat.dateTime(e.checkedAt!.toLocal())}' : ''}',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          if (readings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(readings, style: handoverText(context, 12.5)),
            ),
          ],
          if (e.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(e.note, style: handoverText(context, 12.5)),
          ],
          if (e.takeoverReason != null && e.takeoverReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Taken over: ${e.takeoverReason}',
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// One Schedules table row as a card: Check, How often, Who, Status, actions.
class ScheduleCard extends StatelessWidget {
  final CheckSchedule schedule;
  final bool canWrite;
  final bool busy;
  final VoidCallback onWho;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.canWrite,
    required this.busy,
    required this.onWho,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    final role = s.assignedRole?.replaceAll('_', ' ');
    final who = s.assignedStaffName ?? role;
    final label = handoverText(context, 11.5, weight: FontWeight.w600,
        color: AppColors.textMuted);
    return HandoverPanel(
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
                      s.name ?? 'Resident check',
                      style: handoverText(context, 14.5, weight: FontWeight.w600,
                          color: AppColors.primaryNavy),
                    ),
                    Text(
                      '${s.clientName ?? '—'} · ${s.residenceName ?? ''}',
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              AttendancePill(
                label: s.isActive ? 'Active' : 'Paused',
                tone: s.isActive ? AttendanceTone.success : AttendanceTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How often', style: label),
                    const SizedBox(height: 2),
                    Text(CheckLabels.describeFrequency(s), style: handoverText(context, 13)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Who', style: label),
                    const SizedBox(height: 2),
                    if (canWrite)
                      InkWell(
                        key: ValueKey('schedule-who-${s.id}'),
                        onTap: busy ? null : onWho,
                        child: Text(
                          who ?? 'Assign',
                          style: handoverText(context, 13, color: AppColors.secondaryTeal),
                        ),
                      )
                    else
                      Text(
                        who ?? 'Whoever is on shift',
                        style: handoverText(context, 13, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (canWrite) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                HandoverButton(
                  key: ValueKey('schedule-edit-${s.id}'),
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  compact: true,
                  onPressed: busy ? null : onEdit,
                ),
                const SizedBox(width: 8),
                HandoverButton(
                  key: ValueKey('schedule-toggle-${s.id}'),
                  label: s.isActive ? 'Pause' : 'Resume',
                  compact: true,
                  onPressed: busy ? null : onToggle,
                ),
                const SizedBox(width: 8),
                HandoverButton(
                  key: ValueKey('schedule-delete-${s.id}'),
                  label: '',
                  icon: Icons.delete_outline_rounded,
                  foreground: AppColors.criticalRed,
                  compact: true,
                  onPressed: busy ? null : onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
