import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_log.dart';
import '../controllers/daily_logs_controller.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

/// Web Today hub: shifts/handover strip, resident chips, resident table,
/// and "For the next shift" notes.
class TodayBoardSection extends StatelessWidget {
  final DailyLogsController controller;
  final VoidCallback? onWriteNote;
  final ValueChanged<DailyLogBoardResident>? onOpenResident;
  final VoidCallback? onOpenHandover;

  const TodayBoardSection({
    super.key,
    required this.controller,
    this.onWriteNote,
    this.onOpenResident,
    this.onOpenHandover,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      if (!c.hasResidence) {
        return const DailyLogEmptyCard(
          title: 'Choose a home',
          description: 'Pick a residence to see who needs a note today.',
        );
      }
      if (c.boardLoading.value && c.board.value == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal)),
        );
      }
      if (c.boardError.value case final error?) {
        return DailyLogFormError(error);
      }
      final board = c.board.value;
      if (board == null) {
        return const DailyLogEmptyCard(
          title: 'Nothing on the board',
          description: 'No residents for this home and date.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShiftsStrip(board: board, onOpenHandover: onOpenHandover),
          const SizedBox(height: 14),
          _ResidentFilterChips(controller: c),
          const SizedBox(height: 10),
          _ResidentsTable(
            controller: c,
            residents: c.filteredResidents,
            forNextShift: board.forNextShift,
            canWrite: c.canWrite,
            onOpen: onOpenResident,
            onWrite: (r) {
              c.openDay(r.clientId, c.logDate.value, name: r.name);
              onWriteNote?.call();
            },
          ),
          const SizedBox(height: 14),
          _NextShiftPanel(notes: board.forNextShift),
        ],
      );
    });
  }
}

class _ShiftsStrip extends StatelessWidget {
  final DailyLogBoard board;
  final VoidCallback? onOpenHandover;

  const _ShiftsStrip({required this.board, this.onOpenHandover});

  @override
  Widget build(BuildContext context) {
    if (board.shifts.isEmpty && board.handovers.isEmpty) {
      return const SizedBox.shrink();
    }
    final handover = board.handovers.isEmpty ? null : board.handovers.last;
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final shift in board.shifts) ...[
            Text(
              _shiftTitle(shift),
              style: handoverText(context, 13.5, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final staff in shift.onDuty) _StaffChip(staff: staff),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (handover != null)
            _HandoverRow(handover: handover, onOpen: onOpenHandover),
        ],
      ),
    );
  }

  String _shiftTitle(DailyLogBoardShift shift) {
    final title = (shift.title ?? '').trim();
    final range =
        '${WebFormat.time(TenantClock.wallOf(shift.startsAt))}–${WebFormat.time(TenantClock.wallOf(shift.endsAt))}';
    if (title.isEmpty) return range;
    return '$title · $range';
  }
}

class _StaffChip extends StatelessWidget {
  final DailyLogBoardOnDuty staff;

  const _StaffChip({required this.staff});

  @override
  Widget build(BuildContext context) {
    final warn = staff.notClockedIn || staff.late;
    final status = staff.notClockedIn
        ? 'not clocked in'
        : 'in ${WebFormat.time(TenantClock.wallOf(staff.clockedInAt!))}'
            '${staff.late ? ' · late' : ''}';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: warn ? AppColors.urgentBackground : AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: warn ? AppColors.urgentAmber.withValues(alpha: 0.35) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: warn ? AppColors.urgentAmber : AppColors.secondaryTeal,
            child: Text(
              _initials(staff.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff.name,
                style: handoverText(context, 12, weight: FontWeight.w700),
              ),
              Text(
                status,
                style: handoverText(
                  context,
                  10.5,
                  color: warn ? AppColors.urgentAmber : AppColors.activeGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _HandoverRow extends StatelessWidget {
  final DailyLogBoardHandover handover;
  final VoidCallback? onOpen;

  const _HandoverRow({required this.handover, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final given = handover.submittedAt == null
        ? ''
        : WebFormat.time(TenantClock.wallOf(handover.submittedAt!));
    final status = handover.notTakenYet
        ? 'Given $given by ${handover.givenBy ?? '—'} · not taken yet'
        : 'Given $given by ${handover.givenBy ?? '—'} · taken'
            '${handover.takenBy.isEmpty ? '' : ' by ${handover.takenBy.join(', ')}'}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            'HANDOVER',
            style: handoverText(
              context,
              11,
              weight: FontWeight.w800,
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status,
              style: handoverText(context, 12.5, color: AppColors.textSecondary),
            ),
          ),
          if (onOpen != null)
            HandoverButton(
              key: const ValueKey('dl-board-handover-open'),
              label: 'Open',
              compact: true,
              onPressed: onOpen,
            ),
        ],
      ),
    );
  }
}

class _ResidentFilterChips extends StatelessWidget {
  final DailyLogsController controller;

  const _ResidentFilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      Widget chip(DailyLogsResidentFilter filter, String label) {
        final selected = c.residentFilter.value == filter;
        final count = c.countFor(filter);
        return InkWell(
          key: ValueKey('dl-resident-filter-$filter'),
          onTap: () => c.setResidentFilter(filter),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.secondaryTeal : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.secondaryTeal : AppColors.cardBorder,
              ),
            ),
            child: Text(
              '$label $count',
              style: handoverText(
                context,
                12.5,
                weight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textHeading,
              ),
            ),
          ),
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip(DailyLogsResidentFilter.all, 'All'),
          chip(DailyLogsResidentFilter.owed, 'Needs something'),
          chip(DailyLogsResidentFilter.flagged, 'Flagged'),
        ],
      );
    });
  }
}

class _ResidentsTable extends StatelessWidget {
  final DailyLogsController controller;
  final List<DailyLogBoardResident> residents;
  final List<DailyLogBoardNextNote> forNextShift;
  final bool canWrite;
  final ValueChanged<DailyLogBoardResident>? onOpen;
  final ValueChanged<DailyLogBoardResident>? onWrite;

  const _ResidentsTable({
    required this.controller,
    required this.residents,
    required this.forNextShift,
    required this.canWrite,
    this.onOpen,
    this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    if (residents.isEmpty) {
      return const DailyLogEmptyCard(
        title: 'No residents match',
        description: 'Try another filter or clear the search.',
      );
    }
    return HandoverPanel(
      child: Column(
        children: [
          for (var i = 0; i < residents.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.cardBorder),
            _ResidentRow(
              resident: residents[i],
              nextShiftCount: forNextShift
                  .where((n) => n.clientId == residents[i].clientId)
                  .length,
              canWrite: canWrite,
              onOpen: onOpen,
              onWrite: onWrite,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResidentRow extends StatelessWidget {
  final DailyLogBoardResident resident;
  final int nextShiftCount;
  final bool canWrite;
  final ValueChanged<DailyLogBoardResident>? onOpen;
  final ValueChanged<DailyLogBoardResident>? onWrite;

  const _ResidentRow({
    required this.resident,
    required this.nextShiftCount,
    required this.canWrite,
    this.onOpen,
    this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    final noNote = resident.notes == 0;
    return InkWell(
      key: ValueKey('dl-board-${resident.clientId}'),
      onTap: onOpen == null ? null : () => onOpen!(resident),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
              child: Text(
                _residentInitials(resident.name),
                style: const TextStyle(
                  color: AppColors.secondaryTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resident.name,
                    style: handoverText(context, 14, weight: FontWeight.w700),
                  ),
                  if ((resident.room ?? '').isNotEmpty)
                    Text(
                      'Room ${resident.room}',
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    noNote
                        ? 'No note yet'
                        : '${resident.notes} note${resident.notes == 1 ? '' : 's'}'
                            '${resident.lastNoteBy == null ? '' : ' · ${resident.lastNoteBy}'}',
                    style: handoverText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: noNote ? const Color(0xFF9A5B13) : AppColors.textSecondary,
                    ),
                  ),
                  if (resident.gaps.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final gap in resident.gaps)
                          DailyLogPill(
                            DailyLogLabels.gapLabels[gap.type] ?? gap.detail,
                            tone: DailyLogTone.warning,
                          ),
                      ],
                    ),
                  ],
                  if (resident.flags.isNotEmpty || nextShiftCount > 0) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final flag in resident.flags)
                          DailyLogPill(
                            'Flag - ${DailyLogLabels.capitalise(flag.category).toLowerCase()}',
                            tone: DailyLogLabels.flagTones[flag.category] ??
                                DailyLogTone.danger,
                          ),
                        if (nextShiftCount > 0)
                          DailyLogPill(
                            '$nextShiftCount for next shift',
                            tone: DailyLogTone.warning,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (canWrite)
              HandoverButton(
                key: ValueKey('dl-write-${resident.clientId}'),
                label: 'Write note',
                icon: Icons.edit_note_rounded,
                compact: true,
                filled: true,
                onPressed: onWrite == null ? null : () => onWrite!(resident),
              ),
          ],
        ),
      ),
    );
  }
}

String _residentInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final s = parts.first;
    return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class _NextShiftPanel extends StatelessWidget {
  final List<DailyLogBoardNextNote> notes;

  const _NextShiftPanel({required this.notes});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notes.isEmpty
                      ? 'For the next shift'
                      : 'For the next shift · ${notes.length}',
                  style: handoverText(context, 14, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notes.isEmpty
                ? 'Nothing marked for the next shift.'
                : 'Stays here until the handover holding it is taken.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final note in notes) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(10),
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
                      style: handoverText(context, 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          [
                            WebFormat.time(TenantClock.wallOf(note.occurredAt)),
                            if ((note.author ?? '').isNotEmpty) note.author!,
                          ].join(' · '),
                          style: handoverText(
                            context,
                            11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        DailyLogPill(
                          note.inHandover ? 'In handover' : 'Not in a handover',
                          tone: note.inHandover
                              ? DailyLogTone.neutral
                              : DailyLogTone.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
