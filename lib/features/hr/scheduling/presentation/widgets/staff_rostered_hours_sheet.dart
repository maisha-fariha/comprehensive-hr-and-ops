import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/repositories/scheduling_repository.dart';

/// Web modal summary totals use one decimal (`26.2 hrs`); per-shift rows keep
/// up to two (`9.75 hrs` / `0.25 hrs`).
String _fmtSummaryHours(double hours) {
  if ((hours - hours.roundToDouble()).abs() < 0.05) {
    return hours.round().toString();
  }
  return hours.toStringAsFixed(1);
}

String _fmtDetailHours(double hours) {
  if ((hours - hours.roundToDouble()).abs() < 0.005) {
    return hours.round().toString();
  }
  final two = hours.toStringAsFixed(2);
  if (two.endsWith('0')) return hours.toStringAsFixed(1);
  return two;
}

/// Web "Staff Hours" → "Staff Rostered Hours" breakdown modal.
Future<void> showStaffRosteredHoursSheet({
  required BuildContext context,
  required DateTime weekOf,
  required List<StaffRosteredHours> weekRows,
  String? residenceId,
  ShiftStatusFilter? status,
  bool mine = false,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StaffRosteredHoursSheet(
      weekOf: weekOf,
      weekRows: weekRows,
      residenceId: residenceId,
      status: status,
      mine: mine,
    ),
  );
}

class _StaffRosteredHoursSheet extends StatefulWidget {
  final DateTime weekOf;
  final List<StaffRosteredHours> weekRows;
  final String? residenceId;
  final ShiftStatusFilter? status;
  final bool mine;

  const _StaffRosteredHoursSheet({
    required this.weekOf,
    required this.weekRows,
    this.residenceId,
    this.status,
    this.mine = false,
  });

  @override
  State<_StaffRosteredHoursSheet> createState() =>
      _StaffRosteredHoursSheetState();
}

class _StaffRosteredHoursSheetState extends State<_StaffRosteredHoursSheet> {
  bool _monthly = false;
  bool _loadingMonth = false;
  String? _monthError;
  List<StaffRosteredHours> _monthRows = const [];
  final _search = TextEditingController();
  final Set<String> _expandedIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DateTime get _weekStart => IsoDateRange.startOfWeek(widget.weekOf);
  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));
  DateTime get _monthStart => DateTime(widget.weekOf.year, widget.weekOf.month, 1);
  int get _daysInMonth =>
      DateTime(widget.weekOf.year, widget.weekOf.month + 1, 0).day;

  List<StaffRosteredHours> get _rows => _monthly ? _monthRows : widget.weekRows;

  Future<void> _ensureMonth() async {
    if (_monthRows.isNotEmpty || _loadingMonth) return;
    setState(() {
      _loadingMonth = true;
      _monthError = null;
    });
    final result = await GetIt.instance<SchedulingRepository>().getOverview(
      weekOf: widget.weekOf,
      monthOf: _monthStart,
      span: ScheduleSpan.month,
      residenceId: widget.residenceId,
      status: widget.status,
      mine: widget.mine,
    );
    if (!mounted) return;
    result.when(
      success: (overview) {
        setState(() {
          _monthRows = overview.staffRosteredHours;
          _loadingMonth = false;
        });
      },
      failure: (error) {
        setState(() {
          _loadingMonth = false;
          _monthError = error.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final query = _search.text.trim().toLowerCase();
    final rows = [
      for (final row in _rows)
        if (query.isEmpty || row.name.toLowerCase().contains(query)) row,
    ];
    final total = rows.fold<double>(0, (s, r) => s + r.hours);
    final overtime = rows.fold<double>(
      0,
      (s, r) =>
          s +
          r.overtime(monthly: _monthly, daysInMonth: _daysInMonth),
    );
    final subtitle = _monthly
        ? 'Monthly view: ${_monthLabel(_monthStart)}'
        : 'Weekly view: ${_short(_weekStart)} – ${_short(_weekEnd)}';

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: media.size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Staff Rostered Hours',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: AppColors.textHeading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _PeriodChip(
                      label:
                          'Weekly (${_short(_weekStart)} – ${_short(_weekEnd)})',
                      selected: !_monthly,
                      onTap: () => setState(() => _monthly = false),
                    ),
                    _PeriodChip(
                      label: 'Monthly (${_monthLabel(_monthStart)})',
                      selected: _monthly,
                      onTap: () async {
                        setState(() => _monthly = true);
                        await _ensureMonth();
                      },
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search staff…',
                          isDense: true,
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          filled: true,
                          fillColor: AppColors.filterButtonBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Rostered',
                        value: '${_fmtSummaryHours(total)} hrs',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Scheduled Staff',
                        value: '${rows.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Overtime',
                        value: '${_fmtSummaryHours(overtime)} hrs',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              Expanded(
                child: _monthly && _loadingMonth
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        ),
                      )
                    : _monthly && _monthError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _monthError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : rows.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nobody is rostered in this period yet.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  24,
                                ),
                                itemCount: rows.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  final expanded =
                                      _expandedIds.contains(row.staffId);
                                  final fraction = row.capacityFraction(
                                    monthly: _monthly,
                                    daysInMonth: _daysInMonth,
                                  );
                                  final pct = (fraction * 100).round();
                                  final capacityLabel = _monthly
                                      ? '${_fmtSummaryHours(StaffRosteredHours.weeklyCapacityHours * (_daysInMonth / 7.0))}h'
                                      : '${StaffRosteredHours.weeklyCapacityHours.round()}h';
                                  return Material(
                                    color: AppColors.surfaceWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      key: ValueKey(
                                        'staff-rostered-row-${row.staffId}',
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => setState(() {
                                        if (expanded) {
                                          _expandedIds.remove(row.staffId);
                                        } else {
                                          _expandedIds.add(row.staffId);
                                        }
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          10,
                                          12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.cardBorder,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF102A43)
                                                  .withValues(alpha: 0.04),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _StaffInitialsAvatar(
                                                  name: row.name,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        row.name,
                                                        style: const TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 15,
                                                          color: AppColors
                                                              .textHeading,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${row.shiftCount} shift${row.shiftCount == 1 ? '' : 's'}',
                                                        style: const TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 12.5,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '${_fmtDetailHours(row.hours)} hrs',
                                                      style: const TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 15,
                                                        color: AppColors
                                                            .textHeading,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$pct% of $capacityLabel capacity',
                                                      style: const TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  expanded
                                                      ? Icons
                                                          .expand_more_rounded
                                                      : Icons
                                                          .chevron_right_rounded,
                                                  color: AppColors.textMuted,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: LinearProgressIndicator(
                                                value: fraction,
                                                minHeight: 4,
                                                backgroundColor:
                                                    AppColors.cardBorder,
                                                color: AppColors.primaryNavy,
                                              ),
                                            ),
                                            if (expanded)
                                              _ShiftBreakdownPanel(row: row),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _short(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static const _fullMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _monthLabel(DateTime d) =>
      '${_fullMonths[d.month - 1]} ${d.year}';
}

class _StaffInitialsAvatar extends StatelessWidget {
  final String name;

  const _StaffInitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = IsoDateRange.initials(name);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.filterButtonBackground,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Web expand panel under a staff row: labelled SHIFT BREAKDOWN + per-shift
/// cards (date · time · home, hours).
class _ShiftBreakdownPanel extends StatelessWidget {
  final StaffRosteredHours row;

  const _ShiftBreakdownPanel({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SHIFT BREAKDOWN',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.45,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${_fmtDetailHours(row.hours)} hrs total',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textHeading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (row.shifts.isEmpty)
                const Text(
                  'No shift details for this period.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (var i = 0; i < row.shifts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ShiftBreakdownLine(shift: row.shifts[i]),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftBreakdownLine extends StatelessWidget {
  final StaffRosteredShiftLine shift;

  const _ShiftBreakdownLine({required this.shift});

  @override
  Widget build(BuildContext context) {
    final date =
        '${shift.startsAt.day.toString().padLeft(2, '0')}/'
        '${shift.startsAt.month.toString().padLeft(2, '0')}/'
        '${shift.startsAt.year}';
    final range =
        '${TenantClock.formatTime(shift.startsAt)} – ${TenantClock.formatTime(shift.endsAt)}';
    final home = (shift.residenceName ?? '').trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppColors.textHeading,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            range,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                          if (home.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              home,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_fmtDetailHours(shift.hours)} hrs',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
