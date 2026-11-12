import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../controllers/scheduling_controller.dart';

/// Web "Open shifts" rail: Upcoming vs Past unstaffed + Bid / manager actions.
class OpenShiftsRail extends StatefulWidget {
  final SchedulingController controller;
  final List<CalendarShift> openShifts;
  final ValueChanged<CalendarShift>? onOpenShift;
  final ValueChanged<CalendarShift>? onEditShift;
  final ValueChanged<CalendarShift>? onCancelShift;
  final ValueChanged<CalendarShift>? onDeleteShift;
  final Future<void> Function(CalendarShift shift)? onBid;

  const OpenShiftsRail({
    super.key,
    required this.controller,
    required this.openShifts,
    this.onOpenShift,
    this.onEditShift,
    this.onCancelShift,
    this.onDeleteShift,
    this.onBid,
  });

  @override
  State<OpenShiftsRail> createState() => _OpenShiftsRailState();
}

class _OpenShiftsRailState extends State<OpenShiftsRail> {
  bool _past = true;
  String? _biddingId;

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
    final canBid = widget.controller.canBid;
    final ownStaffId =
        widget.controller.session?.staffId ?? widget.controller.session?.userId;

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
                      ? 'No past unstaffed shifts.'
                      : canWrite
                          ? 'Nothing is open for bidding. Opening a shift lets staff put their name forward for it.'
                          : 'Nothing is open to bid for at the moment.',
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
                    canBid: canBid,
                    ownStaffId: ownStaffId,
                    bidding: _biddingId == shift.id,
                    onOpen: canWrite && widget.onOpenShift != null
                        ? () => widget.onOpenShift!(shift)
                        : null,
                    onEdit: canWrite && widget.onEditShift != null
                        ? () => widget.onEditShift!(shift)
                        : null,
                    onCancel: canWrite && widget.onCancelShift != null
                        ? () => widget.onCancelShift!(shift)
                        : null,
                    onDelete: canWrite && widget.onDeleteShift != null
                        ? () => widget.onDeleteShift!(shift)
                        : null,
                    onBid: canBid && widget.onBid != null
                        ? () => _bid(shift)
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

  Future<void> _bid(CalendarShift shift) async {
    if (_biddingId != null || widget.onBid == null) return;
    setState(() => _biddingId = shift.id);
    try {
      await widget.onBid!(shift);
    } finally {
      if (mounted) setState(() => _biddingId = null);
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
  final bool canBid;
  final String? ownStaffId;
  final bool bidding;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onBid;

  const _OpenShiftCard({
    required this.shift,
    required this.canWrite,
    required this.canBid,
    this.ownStaffId,
    this.bidding = false,
    this.onOpen,
    this.onEdit,
    this.onCancel,
    this.onDelete,
    this.onBid,
  });

  static String _bidSummary(CalendarShift shift) {
    final bids = shift.pendingBids.length;
    if (bids <= 0) return 'No bids yet';
    return '$bids staff ${bids == 1 ? 'has' : 'have'} bid for this shift. '
        'Click for actions.';
  }

  bool get _ownBidPending {
    final id = ownStaffId;
    if (id == null || id.isEmpty) return false;
    return shift.pendingBids.any((b) => b.staffId == id);
  }

  bool get _ownAssigned {
    final id = ownStaffId;
    if (id == null || id.isEmpty) return false;
    return shift.staffIds.contains(id);
  }

  @override
  Widget build(BuildContext context) {
    final title = (shift.title ?? '').trim().isEmpty ? 'SHIFT' : shift.title!;
    final duration = WebFormat.durationHours(shift.startsAt, shift.endsAt);
    final when = [
      if (shift.startsAt != null) WebFormat.date(shift.startsAt),
      if (shift.startsAt != null && shift.endsAt != null)
        '${WebFormat.time(shift.startsAt)} – ${WebFormat.time(shift.endsAt)}'
      else if (shift.timeRange.isNotEmpty)
        shift.timeRange,
    ].join(' · ');
    final open = (shift.total - shift.filled).clamp(0, 999);
    final meta = [
      if ((shift.residenceName ?? '').isNotEmpty) shift.residenceName!,
      if (open > 0) '$open open',
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
                  if (canWrite &&
                      (onEdit != null ||
                          onCancel != null ||
                          onDelete != null))
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                          case 'cancel':
                            onCancel?.call();
                          case 'delete':
                            onDelete?.call();
                        }
                      },
                      itemBuilder: (_) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit shift'),
                          ),
                        if (onCancel != null)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Text(
                              'Cancel shift',
                              style: TextStyle(color: AppColors.urgentAmber),
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
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
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textHeading,
                  ),
                  children: [
                    TextSpan(text: when),
                    if (duration != null)
                      TextSpan(
                        text: ' ($duration)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (canWrite) ...[
                const SizedBox(height: 4),
                Text(
                  _bidSummary(shift),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ],
              if (canBid && !_ownAssigned && onBid != null) ...[
                const SizedBox(height: 8),
                if (_ownBidPending)
                  const Text(
                    'Your bid is in — waiting on a manager',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: AppColors.secondaryTeal,
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: bidding ? null : onBid,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textHeading,
                      side: const BorderSide(color: AppColors.textHeading),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: bidding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Bid for this shift',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                  ),
              ],
              if (canBid && _ownAssigned) ...[
                const SizedBox(height: 8),
                const Text(
                  'You are assigned to this shift',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
                '${_fmtTotal(total)} hrs total',
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
                        '${_fmtRow(row.hours)} hrs',
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

  /// Web modal Total Rostered uses one decimal (`26.2 hrs`).
  static String _fmtTotal(double hours) {
    if ((hours - hours.roundToDouble()).abs() < 0.05) {
      return hours.round().toString();
    }
    return hours.toStringAsFixed(1);
  }

  static String _fmtRow(double hours) {
    if ((hours - hours.roundToDouble()).abs() < 0.005) {
      return hours.round().toString();
    }
    final two = hours.toStringAsFixed(2);
    if (two.endsWith('0')) return hours.toStringAsFixed(1);
    return two;
  }
}
