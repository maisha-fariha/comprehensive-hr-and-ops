import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_log.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

class _PanelHeader extends StatelessWidget {
  final String title;
  final Widget? badge;

  const _PanelHeader(this.title, this.badge);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: handoverText(context, 16, weight: FontWeight.w700, color: AppColors.primaryNavy),
            ),
          ),
          ?badge,
        ],
      );
}

class ShiftDocumentationPanel extends StatelessWidget {
  final List<DailyLogShiftRow> rows;
  final bool loading;
  final bool canWrite;
  final bool canReview;
  final String? busyId;
  final void Function(DailyLogShiftRow, Map<String, dynamic>, String) onUpdate;

  const ShiftDocumentationPanel({
    super.key,
    required this.rows,
    required this.loading,
    required this.canWrite,
    required this.canReview,
    required this.busyId,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final notStarted = rows.where((r) => r.status == 'open').length;
    return HandoverPanel(
      key: const ValueKey('dl-shift-docs'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            'Shift documentation',
            rows.isEmpty ? null : DailyLogPill('$notStarted not started'),
          ),
          const SizedBox(height: 14),
          if (loading)
            for (var i = 0; i < 2; i++)
              Container(
                height: 86,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
          else if (rows.isEmpty)
            Text(
              'No shift is running for this home today, so there is nothing to document '
              'yet. A record appears for each resident when a shift starts.',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            )
          else
            for (final r in rows) ...[
              _ShiftLogRow(
                key: ValueKey('dl-shift-${r.id}'),
                row: r,
                canWrite: canWrite,
                canReview: canReview,
                busy: busyId == r.id,
                onUpdate: onUpdate,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _ShiftLogRow extends StatefulWidget {
  final DailyLogShiftRow row;
  final bool canWrite;
  final bool canReview;
  final bool busy;
  final void Function(DailyLogShiftRow, Map<String, dynamic>, String) onUpdate;

  const _ShiftLogRow({
    super.key,
    required this.row,
    required this.canWrite,
    required this.canReview,
    required this.busy,
    required this.onUpdate,
  });

  @override
  State<_ShiftLogRow> createState() => _ShiftLogRowState();
}

class _ShiftLogRowState extends State<_ShiftLogRow> {
  late final TextEditingController _summary =
      TextEditingController(text: widget.row.summary ?? '');

  @override
  void didUpdateWidget(covariant _ShiftLogRow old) {
    super.didUpdateWidget(old);
    if (old.row.summary != widget.row.summary) _summary.text = widget.row.summary ?? '';
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final done = r.status == 'completed' || r.status == 'locked';
    final locked = r.status == 'locked';
    final time = r.shiftStartsAt == null || r.shiftEndsAt == null
        ? ''
        : '${WebFormat.time(r.shiftStartsAt)}–${WebFormat.time(r.shiftEndsAt)}';
    final subtitle = [r.shiftTitle ?? r.shiftType, time]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final text = _summary.text.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.clientName ?? 'Resident',
                      style: handoverText(context, 13, weight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: handoverText(context, 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              DailyLogPill(
                DailyLogLabels.shiftStatuses[r.status] ?? r.status,
                tone: DailyLogLabels.shiftStatusTones[r.status] ?? DailyLogTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (locked || !widget.canWrite)
            if (r.summary != null)
              Text(r.summary!, style: handoverText(context, 12.5, color: AppColors.textMuted))
            else
              const SizedBox.shrink()
          else
            HandoverTextArea(
              key: ValueKey('dl-shift-summary-${r.id}'),
              label: '',
              controller: _summary,
              minLines: 3,
              placeholder: 'Condition, important updates, anything still to follow up.',
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.canWrite && !locked)
                HandoverButton(
                  key: ValueKey('dl-shift-save-${r.id}'),
                  label: 'Save summary',
                  compact: true,
                  onPressed: widget.busy || text == (r.summary ?? '').trim()
                      ? null
                      : () => widget.onUpdate(r, {'summary': _summary.text}, 'Summary saved'),
                ),
              if (widget.canWrite && !done)
                HandoverButton(
                  key: ValueKey('dl-shift-complete-${r.id}'),
                  label: 'Complete shift',
                  icon: Icons.done_all_rounded,
                  filled: true,
                  compact: true,
                  onPressed: widget.busy || text.isEmpty
                      ? null
                      : () => widget.onUpdate(
                            r,
                            {'summary': _summary.text, 'status': 'completed'},
                            'Shift completed',
                          ),
                ),
              if (r.status == 'completed' && widget.canReview)
                HandoverButton(
                  key: ValueKey('dl-shift-signoff-${r.id}'),
                  label: 'Sign off',
                  icon: Icons.lock_outline_rounded,
                  compact: true,
                  onPressed: widget.busy
                      ? null
                      : () => widget.onUpdate(r, {'status': 'locked'}, 'Shift signed off'),
                ),
              if (r.completedByName != null)
                Text(
                  'Completed by ${r.completedByName}',
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
              if (r.lockedByName != null)
                Text(
                  '· Signed off by ${r.lockedByName}',
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PriorityNotesPanel extends StatelessWidget {
  final List<CareFlag> flags;
  final bool loading;
  final String? error;
  final bool canResolve;
  final void Function(CareFlag) onResolve;

  const PriorityNotesPanel({
    super.key,
    required this.flags,
    required this.loading,
    required this.error,
    required this.canResolve,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      key: const ValueKey('dl-priority-notes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            'Open flags',
            flags.isEmpty
                ? null
                : DailyLogPill('${flags.length}', tone: DailyLogTone.danger),
          ),
          const SizedBox(height: 14),
          for (final f in flags) ...[
            _FlagCard(
              key: ValueKey('dl-flag-${f.id}'),
              flag: f,
              canResolve: canResolve,
              onResolve: () => onResolve(f),
            ),
            const SizedBox(height: 12),
          ],
          if (flags.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                loading
                    ? 'Loading flags…'
                    : error ?? 'Nothing flagged at this home.',
                textAlign: TextAlign.center,
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final CareFlag flag;
  final bool canResolve;
  final VoidCallback onResolve;

  const _FlagCard({
    super.key,
    required this.flag,
    required this.canResolve,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final f = flag;
    final by = [f.raisedBy, f.residenceName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: DailyLogLabels.flagDots[f.category] ?? AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              DailyLogPill(
                DailyLogLabels.capitalise(f.category),
                tone: DailyLogLabels.flagTones[f.category] ?? DailyLogTone.neutral,
              ),
              const Spacer(),
              Text(
                DailyLogLabels.raised(f.raisedAt),
                style: handoverText(context, 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
          if (f.note != null) ...[
            const SizedBox(height: 8),
            Text(f.note!, style: handoverText(context, 12.5)),
          ],
          if (f.source case final source?) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${source.clientName ?? (source.kind == 'shift_handover' ? 'Handover' : 'Record')}'
                    '${source.logDate != null && source.logDate!.length >= 10 ? ' · ${source.logDate!.substring(0, 10)}' : ''}',
                    style: handoverText(context, 11.5, weight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(source.excerpt, style: handoverText(context, 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(by, style: handoverText(context, 11.5, color: AppColors.textMuted)),
              ),
              if (canResolve && f.resolvedAt == null)
                HandoverButton(
                  key: ValueKey('dl-flag-resolve-${f.id}'),
                  label: 'Resolve',
                  icon: Icons.done_all_rounded,
                  compact: true,
                  onPressed: onResolve,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Web Review right column: notes marked for next shift that never entered a
/// handover (`board.notHandedOver`).
class NotHandedOverPanel extends StatelessWidget {
  final List<DailyLogBoardNextNote> notes;
  final ValueChanged<DailyLogBoardNextNote>? onOpenDay;

  const NotHandedOverPanel({
    super.key,
    required this.notes,
    this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      key: const ValueKey('dl-not-handed-over'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            'Not in a handover',
            notes.isEmpty
                ? null
                : DailyLogPill('${notes.length}', tone: DailyLogTone.warning),
          ),
          const SizedBox(height: 4),
          Text(
            'Marked for the next shift but missed when a handover was posted.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Every next-shift note is in a handover.',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            )
          else
            for (final note in notes) ...[
              InkWell(
                key: ValueKey('dl-not-ho-${note.id}'),
                onTap: onOpenDay == null ? null : () => onOpenDay!(note),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.urgentAmber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.clientName,
                        style: handoverText(context, 13, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: handoverText(
                          context,
                          12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            [
                              WebFormat.time(note.occurredAt),
                              if ((note.author ?? '').isNotEmpty) note.author!,
                            ].join(' · '),
                            style: handoverText(
                              context,
                              11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          DailyLogPill(
                            'Not in a handover',
                            tone: DailyLogTone.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Web Review "Care given, by carer" — `/residence-activity` for the day.
class CareGivenPanel extends StatelessWidget {
  final List<ResidenceActivityRow> rows;
  final bool loading;
  final String? staffFilterLabel;
  final VoidCallback? onFilterStaff;
  final VoidCallback? Function(String? entityType, String? entityId)? openFor;

  const CareGivenPanel({
    super.key,
    required this.rows,
    required this.loading,
    this.staffFilterLabel,
    this.onFilterStaff,
    this.openFor,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      key: const ValueKey('dl-care-given'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader('Care given, by carer', null),
          const SizedBox(height: 4),
          Text(
            'Everything recorded at this home on this day, and by whom.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          if (onFilterStaff != null) ...[
            const SizedBox(height: 10),
            InkWell(
              key: const ValueKey('dl-care-given-staff'),
              onTap: onFilterStaff,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        staffFilterLabel?.isNotEmpty == true
                            ? staffFilterLabel!
                            : 'Everyone',
                        style: handoverText(context, 13),
                      ),
                    ),
                    const Icon(Icons.unfold_more_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Loading…',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                staffFilterLabel?.isNotEmpty == true
                    ? 'Nothing recorded by $staffFilterLabel on this day.'
                    : 'Nothing recorded on this day.',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            )
          else
            for (final row in rows) ...[
              Padding(
                key: ValueKey('dl-care-${row.id}'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        WebFormat.time(row.occurredAt),
                        style: handoverText(
                          context,
                          12.5,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.summary,
                            style: handoverText(context, 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if ((row.staffName ?? '').isNotEmpty) row.staffName!,
                              if ((row.clientName ?? '').isNotEmpty) row.clientName!,
                            ].join(' · '),
                            style: handoverText(
                              context,
                              12,
                              color: AppColors.secondaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}