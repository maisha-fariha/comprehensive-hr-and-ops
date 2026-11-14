import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/entities/shift_request.dart';
import '../../domain/entities/shift_staff_option.dart';
import '../controllers/scheduling_controller.dart';
import 'request_card.dart';

/// Web Week | Month | All shifts control.
class ScheduleSpanSwitch extends StatelessWidget {
  final ScheduleSpan selected;
  final ValueChanged<ScheduleSpan> onSelected;

  const ScheduleSpanSwitch({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            for (final span in ScheduleSpan.values)
              Expanded(
                child: _SpanButton(
                  label: switch (span) {
                    ScheduleSpan.week => 'Week',
                    ScheduleSpan.month => 'Month',
                    ScheduleSpan.list => 'All shifts',
                  },
                  selected: selected == span,
                  onTap: () => onSelected(span),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpanButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SpanButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: selected ? AppColors.primaryNavy : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: ValueKey('schedule-span-${label.toLowerCase().replaceAll(' ', '-')}'),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool shiftCanBeSwapped(CalendarShift shift, String? staffId) {
  if (staffId == null || staffId.isEmpty) return false;
  if (!shift.staffIds.contains(staffId)) return false;
  final start = shift.startsAt;
  if (start == null || !start.isAfter(TenantClock.now())) return false;
  final status = shift.apiStatus.toLowerCase();
  return status != 'cancelled' && status != 'canceled' && status != 'declined';
}

/// Week sidebar from the web: shifts you can swap, then swap requests.
class WeekSwapRail extends StatelessWidget {
  final SchedulingController controller;
  final List<CalendarShift> shifts;
  final List<ShiftRequest> pending;

  const WeekSwapRail({
    super.key,
    required this.controller,
    required this.shifts,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final canBid = controller.canBid;
    final canWrite = controller.canWrite;
    final mine = canBid
        ? shifts
            .where((shift) => shiftCanBeSwapped(shift, controller.session?.staffId))
            .toList()
        : const <CalendarShift>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canBid) ...[
            _Panel(
              title: 'Shifts you can swap',
              child: mine.isEmpty
                  ? const Text('Nothing of yours this week is eligible for a swap.')
                  : Column(
                      children: [
                        for (final shift in mine) ...[
                          _SwapShiftRow(
                            shift: shift,
                            onRequest: () => showRequestSwapSheet(context, shift, controller),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 12),
          ],
          _Panel(
            title: canWrite ? 'Swap Requests' : 'Your swap requests',
            child: pending.isEmpty
                ? Text(
                    canWrite
                        ? 'No pending swap requests.'
                        : 'Nothing of yours is waiting on a manager.',
                  )
                : Column(
                    children: [
                      for (final request in pending)
                        RequestCard(
                          request: request,
                          onApprove: canWrite && request.canManagerDecide
                              ? () => controller.approveRequest(request)
                              : null,
                          onDecline: canWrite && request.canManagerDecide
                              ? () => controller.declineRequest(request)
                              : null,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ScheduleMonthView extends StatelessWidget {
  final SchedulingController controller;
  final List<CalendarShift> shifts;

  const ScheduleMonthView({
    super.key,
    required this.controller,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    final month = controller.monthOf.value;
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7;
    final cells = lead + days;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ScheduleSpanSwitch(
          selected: ScheduleSpan.month,
          onSelected: controller.selectSpan,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: controller.goToPreviousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  IsoDateRange.formatMonthYear(first),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.goToNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 52,
            ),
            itemBuilder: (context, index) {
              if (index < lead) return const SizedBox.shrink();
              final day = index - lead + 1;
              final date = DateTime(month.year, month.month, day);
              final count = shifts.where((shift) {
                final occurs = shift.occursOn;
                return occurs != null &&
                    occurs.year == date.year &&
                    occurs.month == date.month &&
                    occurs.day == date.day;
              }).length;
              return InkWell(
                onTap: count == 0 ? null : () => controller.openWeekOf(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day', style: const TextStyle(fontSize: 13)),
                    if (count > 0)
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScheduleAllShiftsView extends StatelessWidget {
  final SchedulingController controller;
  final List<CalendarShift> shifts;
  final WeekShiftCoverage coverage;
  final ValueChanged<String>? onOpenShift;

  const ScheduleAllShiftsView({
    super.key,
    required this.controller,
    required this.shifts,
    required this.coverage,
    this.onOpenShift,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _CoverageCards(coverage: coverage),
        ),
        ScheduleSpanSwitch(
          selected: ScheduleSpan.list,
          onSelected: controller.selectSpan,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: shifts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'No shifts match.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < shifts.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.cardBorder),
                        _AllShiftRow(
                          shift: shifts[i],
                          controller: controller,
                          onOpen: onOpenShift,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _CoverageCards extends StatelessWidget {
  final WeekShiftCoverage coverage;

  const _CoverageCards({required this.coverage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CoverageCard(
          background: AppColors.criticalBackgroundSoft,
          accent: AppColors.criticalRed,
          title: 'Shifts with nobody on',
          description: coverage.unstaffedDescription,
          value: '${coverage.unstaffed}',
          caption: 'unstaffed',
        ),
        const SizedBox(height: 10),
        _CoverageCard(
          background: AppColors.activeBackground,
          accent: AppColors.activeGreen,
          title: 'Covered',
          description: coverage.coveredDescription,
          value: coverage.coveredValue,
          caption: coverage.coveredCaption,
        ),
        const SizedBox(height: 10),
        _CoverageCard(
          background: AppColors.urgentBackgroundSoft,
          accent: AppColors.urgentAmber,
          title: 'Open for bidding',
          description: coverage.openDescription,
          value: '${coverage.openShifts}',
          caption: 'open shifts',
        ),
      ],
    );
  }
}

class _CoverageCard extends StatelessWidget {
  final Color background;
  final Color accent;
  final String title;
  final String description;
  final String value;
  final String caption;

  const _CoverageCard({
    required this.background,
    required this.accent,
    required this.title,
    required this.description,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                Text(
                  caption.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllShiftRow extends StatelessWidget {
  final CalendarShift shift;
  final SchedulingController controller;
  final ValueChanged<String>? onOpen;

  const _AllShiftRow({
    required this.shift,
    required this.controller,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final names = shift.staffNames;
    final canWrite = controller.canWrite;
    final status = shift.apiStatus.toLowerCase();
    final cancelled = status == 'cancelled' || status == 'canceled';
    final staffId = controller.session?.staffId;

    return InkWell(
      onTap: onOpen == null ? null : () => onOpen!(shift.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StaffCell(shift: shift)),
                const SizedBox(width: 8),
                _StatusPill(status: shift.apiStatus),
              ],
            ),
            const SizedBox(height: 8),
            _LabeledValue(label: 'Home', value: shift.residenceName ?? 'Unknown home'),
            _LabeledValue(label: 'Date', value: _shiftDate(shift)),
            _LabeledValue(label: 'Hours', value: _shiftHours(shift)),
            _LabeledValue(
              label: 'Shift',
              value: (shift.title ?? '').trim().isEmpty ? '—' : shift.title!,
            ),
            if (canWrite || controller.canBid) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (controller.canBid && shiftCanBeSwapped(shift, staffId))
                      _OutlineAction(
                        label: 'Request swap',
                        onPressed: () =>
                            showRequestSwapSheet(context, shift, controller),
                      ),
                    if (canWrite && names.isEmpty && !cancelled && status != 'open')
                      _OutlineAction(
                        label: 'Open for bids',
                        onPressed: () => controller.openShift(shift.id),
                      ),
                    if (canWrite && !cancelled)
                      _OutlineAction(
                        label: 'Cancel',
                        onPressed: () => controller.cancelShift(shift.id),
                      ),
                    if (canWrite)
                      _OutlineIconButton(
                        buttonKey: ValueKey('schedule-delete-${shift.id}'),
                        tooltip: 'Delete shift',
                        onPressed: () =>
                            _confirmDeleteShift(context, shift, controller),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.criticalRed,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffCell extends StatelessWidget {
  final CalendarShift shift;

  const _StaffCell({required this.shift});

  @override
  Widget build(BuildContext context) {
    final names = shift.staffNames;
    if (names.isEmpty) {
      return const Text(
        'Nobody assigned',
        style: TextStyle(
          color: AppColors.criticalRed,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final requiredCount = shift.requiredStaffCount;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.activeBackground,
          child: Text(
            _initials(names.first),
            style: const TextStyle(
              color: AppColors.secondaryTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                names.first,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (names.length > 1 || requiredCount != null)
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      if (names.length > 1)
                        TextSpan(
                          text: 'and ${names.length - 1} more',
                          style: const TextStyle(color: AppColors.infoBlue),
                        ),
                      if (names.length > 1 && requiredCount != null)
                        const TextSpan(text: '  '),
                      if (requiredCount != null)
                        TextSpan(
                          text: '${shift.filled}/$requiredCount',
                          style: TextStyle(
                            color: shift.filled < requiredCount
                                ? AppColors.criticalRed
                                : AppColors.infoBlue,
                            fontWeight: shift.filled < requiredCount
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final raw = status.trim().isEmpty ? 'scheduled' : status;
    final key = raw.toLowerCase();
    final label = key == 'draft'
        ? 'DRAFT'
        : raw
            .replaceAll('_', ' ')
            .replaceFirstMapped(
              RegExp(r'^.'),
              (match) => match.group(0)!.toUpperCase(),
            );
    final (Color color, Color background) = switch (key) {
      'open' => (AppColors.criticalRed, AppColors.criticalBackgroundSoft),
      'draft' => (AppColors.urgentAmber, AppColors.urgentBackgroundSoft),
      _ => (AppColors.textSecondary, const Color(0xFFF1F3F6)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

ButtonStyle _shiftActionStyle({EdgeInsetsGeometry? padding}) {
  return OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    foregroundColor: AppColors.textPrimary,
    side: const BorderSide(color: AppColors.cardBorder),
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 10),
    minimumSize: const Size(32, 32),
    fixedSize: const Size.fromHeight(32),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    alignment: Alignment.center,
  );
}

class _OutlineAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlineAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: _shiftActionStyle(),
      child: Text(label, style: const TextStyle(fontSize: 12, height: 1)),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  final Key? buttonKey;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  const _OutlineIconButton({
    this.buttonKey,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        key: buttonKey,
        onPressed: onPressed,
        style: _shiftActionStyle(padding: EdgeInsets.zero),
        child: icon,
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String _shiftDate(CalendarShift shift) {
  final date = shift.startsAt ?? shift.occursOn;
  if (date == null) return '—';
  // Settings → General date format (org timezone).
  return WebFormat.date(date);
}

String _shiftHours(CalendarShift shift) {
  final start = shift.startsAt;
  if (start == null) return shift.timeRange;
  // Settings → General time format (12h / 24h) — match web All Shifts Hours.
  final end = shift.endsAt;
  if (end == null) return WebFormat.time(start);
  final range = '${WebFormat.time(start)} – ${WebFormat.time(end)}';
  final duration = WebFormat.durationHours(start, end);
  if (duration == null) return range;
  return '$range ($duration)';
}

Future<void> _confirmDeleteShift(
  BuildContext context,
  CalendarShift shift,
  SchedulingController controller,
) async {
  final confirmed = await showAppBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    builder: (sheetContext) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete this shift?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'It comes off the rota. The shift and its assignments are kept rather than destroyed, so it can be restored.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.criticalRed,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
      );
    },
  );
  if (confirmed == true) await controller.deleteShift(shift.id);
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SwapShiftRow extends StatelessWidget {
  final CalendarShift shift;
  final VoidCallback onRequest;

  const _SwapShiftRow({required this.shift, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final when = shift.occursOn == null
        ? shift.timeRange
        : '${IsoDateRange.formatWeekdayDate(shift.occursOn!)} · ${shift.timeRange}';
    return Row(
      children: [
        Expanded(
          child: Text(when, style: const TextStyle(fontSize: 13)),
        ),
        TextButton(
          key: ValueKey('schedule-request-swap-${shift.id}'),
          onPressed: onRequest,
          child: const Text('Request swap'),
        ),
      ],
    );
  }
}

/// Web "Request a swap" — colleague, optional exchange, note (same as staff).
Future<void> showRequestSwapSheet(
  BuildContext context,
  CalendarShift shift,
  SchedulingController controller,
) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HrSwapRequestSheet(shift: shift, controller: controller),
  );
}

class _HrSwapRequestSheet extends StatefulWidget {
  final CalendarShift shift;
  final SchedulingController controller;

  const _HrSwapRequestSheet({
    required this.shift,
    required this.controller,
  });

  @override
  State<_HrSwapRequestSheet> createState() => _HrSwapRequestSheetState();
}

class _HrSwapRequestSheetState extends State<_HrSwapRequestSheet> {
  final _note = TextEditingController();
  List<ShiftStaffOption> _colleagues = const [];
  List<({String id, String label})> _exchanges = const [];
  String? _colleagueId;
  String? _exchangeId;
  bool _canSeeStaff = true;
  bool _loadingStaff = true;
  bool _loadingShifts = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadColleagues();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String? get _ownStaffId {
    if (!Get.isRegistered<UserSession>()) return null;
    return Get.find<UserSession>().staffId;
  }

  Future<void> _loadColleagues() async {
    final result = await widget.controller.repository.listSwapColleagues(
      residenceId: widget.shift.residenceId,
    );
    if (!mounted) return;
    result.when(
      success: (people) {
        final taken = widget.shift.staffIds.toSet();
        final own = _ownStaffId;
        setState(() {
          _canSeeStaff = true;
          _loadingStaff = false;
          _colleagues = [
            for (final person in people)
              if (person.id != own && !taken.contains(person.id)) person,
          ];
        });
      },
      failure: (_) {
        setState(() {
          _canSeeStaff = false;
          _loadingStaff = false;
        });
      },
    );
  }

  Future<void> _selectColleague(String? id) async {
    setState(() {
      _colleagueId = id;
      _exchangeId = null;
      _exchanges = const [];
      _error = null;
    });
    if (id == null || id.isEmpty) return;
    setState(() => _loadingShifts = true);
    final result = await widget.controller.repository.listColleagueShifts(id);
    if (!mounted) return;
    result.when(
      success: (shifts) {
        setState(() {
          _loadingShifts = false;
          _exchanges = [
            for (final item in shifts)
              if (item.id != widget.shift.id) item,
          ];
        });
      },
      failure: (_) => setState(() => _loadingShifts = false),
    );
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final colleague = _colleagueId;
    final message = await widget.controller.requestSwap(
      widget.shift.id,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      targetStaffId: colleague,
      toShiftId: colleague == null ? null : _exchangeId,
    );
    if (!mounted) return;
    if (message != null) {
      setState(() {
        _sending = false;
        _error = message;
      });
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.show(
      colleague == null
          ? 'Cover requested — a manager will decide'
          : 'Swap requested — your colleague has been asked',
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final when = _whenLabel(widget.shift.startsAt);
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Request a swap',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$when — ask a colleague to take it, or ask for cover.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.criticalBackgroundSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.criticalRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Who',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Ask a colleague', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String?>(
                  initialValue: _colleagueId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Anyone — put it out for cover'),
                    ),
                    for (final person in _colleagues)
                      DropdownMenuItem<String?>(
                        value: person.id,
                        child: Text(
                          person.detail.trim().isEmpty
                              ? person.name
                              : '${person.name} · ${person.detail}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: !_canSeeStaff || _loadingStaff
                      ? null
                      : _selectColleague,
                ),
                const SizedBox(height: 4),
                Text(
                  _canSeeStaff
                      ? 'Leave empty and the shift goes out for bids once a manager approves.'
                      : 'You cannot see the staff list here — ask for cover instead and a manager will place it.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_colleagueId != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Take one of theirs in exchange',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('hr-exchange-$_colleagueId'),
                    initialValue: _exchangeId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Nothing in exchange'),
                      ),
                      for (final item in _exchanges)
                        DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _loadingShifts
                        ? null
                        : (value) => setState(() => _exchangeId = value),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optional — leave empty to simply hand the shift over.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Note', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Why you need the swap…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _colleagueId == null
                          ? 'A manager decides. Nothing on the rota changes until they do.'
                          : 'Your colleague is asked first. If they agree, a manager still has to approve it before the rota changes.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _sending ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _sending ? null : _send,
                        child: Text(_sending ? 'Sending…' : 'Send request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _whenLabel(DateTime? start) {
  if (start == null) return 'This shift';
  // Settings → General date + time (org timezone / 12h–24h).
  return '${WebFormat.date(start, weekday: true)} ${WebFormat.time(start)}';
}
