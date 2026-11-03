import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../controllers/scheduling_controller.dart';

/// Web "Open shifts" rail: Upcoming vs Past unstaffed, with delete.
class OpenShiftsRail extends StatefulWidget {
  final SchedulingController controller;
  final List<CalendarShift> openShifts;
  final ValueChanged<String>? onOpenShift;

  const OpenShiftsRail({
    super.key,
    required this.controller,
    required this.openShifts,
    this.onOpenShift,
  });

  @override
  State<OpenShiftsRail> createState() => _OpenShiftsRailState();
}

class _OpenShiftsRailState extends State<OpenShiftsRail> {
  bool _past = true;

  @override
  Widget build(BuildContext context) {
    final now = TenantClock.now();
    final upcoming = <CalendarShift>[];
    final past = <CalendarShift>[];
    for (final shift in widget.openShifts) {
      final end = shift.endsAt ?? shift.startsAt;
      if (end == null || !end.isBefore(now)) {
        upcoming.add(shift);
      } else {
        past.add(shift);
      }
    }
    final rows = _past ? past : upcoming;
    final canWrite = widget.controller.canWrite;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Open shifts',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textHeading,
                    ),
                  ),
                  if (past.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${past.length} past',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Tab(
                    label: 'Upcoming (${upcoming.length})',
                    selected: !_past,
                    onTap: () => setState(() => _past = false),
                  ),
                  const SizedBox(width: 8),
                  _Tab(
                    label: 'Past unstaffed (${past.length})',
                    selected: _past,
                    onTap: () => setState(() => _past = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Text(
                  _past
                      ? 'No past unstaffed opens.'
                      : 'No upcoming open shifts.',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final shift in rows) ...[
                  _OpenShiftCard(
                    shift: shift,
                    canWrite: canWrite,
                    onOpen: widget.onOpenShift == null
                        ? null
                        : () => widget.onOpenShift!(shift.id),
                    onDelete: canWrite
                        ? () => _confirmDelete(context, shift)
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CalendarShift shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this open shift?'),
        content: Text(
          '${shift.title?.trim().isNotEmpty == true ? shift.title : shift.name}'
          ' will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.criticalRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deleteShift(shift.id);
    }
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryNavy : AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenShiftCard extends StatelessWidget {
  final CalendarShift shift;
  final bool canWrite;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const _OpenShiftCard({
    required this.shift,
    required this.canWrite,
    this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = (shift.title ?? '').trim().isEmpty ? 'SHIFT' : shift.title!;
    final when = [
      if (shift.startsAt != null) WebFormat.date(shift.startsAt),
      if (shift.timeRange.isNotEmpty) shift.timeRange,
    ].join(' · ');
    return Material(
      color: AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.activeBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.secondaryTeal,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'delete') onDelete!();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete shift',
                            style: TextStyle(color: AppColors.criticalRed),
                          ),
                        ),
                      ],
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                when,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textHeading,
                ),
              ),
              if ((shift.residenceName ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  shift.residenceName!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                shift.filled == 0
                    ? 'No bids yet'
                    : '${shift.filled} staff on this open shift',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web "Staff Rostered Hours" sidebar for the visible week.
class StaffRosteredHoursRail extends StatelessWidget {
  final List<StaffRosteredHours> rows;
  final DateTime weekStart;
  final VoidCallback? onViewBreakdown;

  const StaffRosteredHoursRail({
    super.key,
    required this.rows,
    required this.weekStart,
    this.onViewBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final end = weekStart.add(const Duration(days: 6));
    String d(DateTime v) =>
        '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}';
    final range = '${d(weekStart)} – ${d(end)}';
    final total = rows.fold<double>(0, (sum, row) => sum + row.hours);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Staff Rostered Hours',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                range,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_fmt(total)} hrs total',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Text(
                  'Nobody is rostered this week yet.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final row in rows) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      Text(
                        '${_fmt(row.hours)} hrs',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              if (onViewBreakdown != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onViewBreakdown,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.secondaryTeal,
                    ),
                    child: const Text(
                      'View weekly & monthly breakdown →',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double hours) {
    if ((hours - hours.roundToDouble()).abs() < 0.05) {
      return hours.round().toString();
    }
    return hours.toStringAsFixed(1);
  }
}
