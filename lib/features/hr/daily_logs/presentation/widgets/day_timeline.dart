import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_log.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

/// Entries and recurring checks for one resident on one day, by time.
class DayTimeline extends StatelessWidget {
  final DailyLogDay? day;
  final bool loading;
  final bool canWrite;
  final void Function(DailyLogEntry) onOpen;
  final void Function(DailyLogEntry) onAmend;
  final void Function(DailyLogEntry) onDelete;
  final void Function(DailyLogEntry)? onMedication;

  const DayTimeline({
    super.key,
    required this.day,
    required this.loading,
    required this.canWrite,
    required this.onOpen,
    required this.onAmend,
    required this.onDelete,
    this.onMedication,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 92,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      );
    }
    final entries = day?.entries ?? const <DailyLogEntry>[];
    final checks = day?.checks ?? const <DailyLogCheck>[];
    if (entries.isEmpty && checks.isEmpty) {
      return const DailyLogEmptyCard(
        title: 'Nothing recorded for this day',
        description: 'Entries added for this resident and date will appear here.',
      );
    }
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final items = <(DateTime, Widget)>[
      for (final e in entries)
        (
          e.at ?? epoch,
          DailyLogEntryCard(
            key: ValueKey('dl-entry-${e.id}'),
            entry: e,
            canWrite: canWrite,
            onOpen: () => onOpen(e),
            onAmend: () => onAmend(e),
            onDelete: () => onDelete(e),
            onMedication: onMedication == null ? null : () => onMedication!(e),
          ),
        ),
      for (final c in checks)
        (c.checkedAt, DailyLogCheckCard(key: ValueKey('dl-check-${c.id}'), check: c)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          items[i].$2,
        ],
      ],
    );
  }
}

class DailyLogEntryCard extends StatelessWidget {
  final DailyLogEntry entry;
  final bool canWrite;
  final VoidCallback onOpen;
  final VoidCallback onAmend;
  final VoidCallback onDelete;
  final VoidCallback? onMedication;

  const DailyLogEntryCard({
    super.key,
    required this.entry,
    required this.canWrite,
    required this.onOpen,
    required this.onAmend,
    required this.onDelete,
    this.onMedication,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final superseded = e.isSuperseded;
    final observations = e.observations.entries
        .where((o) => o.value != null && o.value != '' && o.value != false)
        .toList();
    final hasChecks = e.wellnessCheckCompleted != null;
    final medication = e.logType == 'medication' ? DailyLogLabels.medication(e.body) : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: superseded ? AppColors.filterButtonBackground : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: superseded ? AppColors.searchBorder : AppColors.cardBorder,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                e.authorName ?? 'Unknown author',
                style: handoverText(context, 13, weight: FontWeight.w600, color: AppColors.primaryNavy),
              ),
              Text(
                DailyLogLabels.dateTime(e.at),
                style: handoverText(context, 12, color: AppColors.textMuted),
              ),
              if (e.shift != null) DailyLogPill(e.shift!),
              if (superseded) const DailyLogPill('Superseded', tone: DailyLogTone.warning),
              if (e.amendsEntryId != null)
                const DailyLogPill('Correction', tone: DailyLogTone.info),
              if (e.source == 'system' && e.logType != 'medication')
                DailyLogPill('Recorded${e.logType != null ? ' · ${e.logType}' : ''}'),
              if (medication != null) DailyLogPill(medication.$2, tone: medication.$1),
              if (e.recordedAfterLock)
                const DailyLogPill('After sign-off', tone: DailyLogTone.warning),
              if (e.flag case final flag?)
                DailyLogPill(
                  flag.resolvedAt != null
                      ? '${flag.category} · resolved'
                      : '${flag.category} · flagged',
                  tone: flag.resolvedAt != null ? DailyLogTone.neutral : DailyLogTone.danger,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (medication != null && e.clientId != null && onMedication != null)
                HandoverButton(
                  label: 'MAR chart',
                  icon: Icons.medication_outlined,
                  compact: true,
                  foreground: AppColors.secondaryTeal,
                  onPressed: onMedication,
                ),
              HandoverButton(
                key: ValueKey('dl-entry-view-${e.id}'),
                label: 'View',
                icon: Icons.visibility_outlined,
                compact: true,
                onPressed: onOpen,
              ),
              if (canWrite && !superseded)
                HandoverButton(
                  key: ValueKey('dl-entry-amend-${e.id}'),
                  label: 'Amend',
                  icon: Icons.edit_outlined,
                  compact: true,
                  onPressed: onAmend,
                ),
              if (canWrite)
                Semantics(
                  label: 'Delete entry',
                  child: HandoverButton(
                    key: ValueKey('dl-entry-delete-${e.id}'),
                    label: '',
                    icon: Icons.delete_outline_rounded,
                    compact: true,
                    foreground: AppColors.criticalRed,
                    onPressed: onDelete,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            e.body,
            style: handoverText(
              context,
              13.5,
              color: superseded ? AppColors.textMuted : AppColors.textHeading,
              decoration: superseded ? TextDecoration.lineThrough : null,
            ),
          ),
          if (e.amendmentReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reason for correction: ${e.amendmentReason}',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ],
          if (observations.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in observations)
                  DailyLogPill(
                    '${DailyLogLabels.camel(o.key)}: ${o.value == true ? 'yes' : o.value}',
                  ),
              ],
            ),
          ],
          if (hasChecks || e.remindAt != null || e.attachments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (hasChecks) ...[
                  DailyLogPill(
                    'Wellness check ${e.wellnessCheckCompleted! ? 'done' : 'not done'}',
                    tone: e.wellnessCheckCompleted! ? DailyLogTone.success : DailyLogTone.warning,
                  ),
                  DailyLogPill(
                    'Bed check ${e.bedCheckCompleted == true ? 'done' : 'not done'}',
                    tone: e.bedCheckCompleted == true ? DailyLogTone.success : DailyLogTone.warning,
                  ),
                ],
                if (e.remindAt != null)
                  DailyLogPill(
                    'Reminder ${DailyLogLabels.dateTime(e.remindAt)}',
                    tone: DailyLogTone.info,
                  ),
                for (final a in e.attachments)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(a.fileName, style: handoverText(context, 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DailyLogCheckCard extends StatelessWidget {
  final DailyLogCheck check;

  const DailyLogCheckCard({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    final c = check;
    final readings = c.result.entries.where((r) => !r.key.endsWith('Unit')).toList();
    final abnormal = c.outcome != null && c.outcome != 'normal';
    return HandoverPanel(
      borderColor: AppColors.searchBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const DailyLogPill('Check', tone: DailyLogTone.cyan),
              Text(
                c.checkName ?? 'Recurring check',
                style: handoverText(context, 13, weight: FontWeight.w600, color: AppColors.primaryNavy),
              ),
              Text(
                '${DailyLogLabels.dateTime(c.checkedAt)}'
                '${c.recordedBy != null ? ' · ${c.recordedBy}' : ''}',
                style: handoverText(context, 12, color: AppColors.textMuted),
              ),
              if (abnormal)
                DailyLogPill(
                  c.outcome!.replaceAll('_', ' '),
                  tone: c.outcome == 'urgent' ? DailyLogTone.danger : DailyLogTone.warning,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.note, style: handoverText(context, 13.5)),
          if (readings.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in readings)
                  DailyLogPill(
                    '${r.key}: ${r.value}'
                    '${c.result['${r.key}Unit'] is String ? ' ${c.result['${r.key}Unit']}' : ''}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
