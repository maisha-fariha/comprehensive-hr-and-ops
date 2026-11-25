import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../controllers/hr_appointments_controller.dart';

const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

/// Web `?view=calendar` — a month grid of bookings with holidays. Tapping a
/// day lists its appointments; tapping one opens it.
class HrAppointmentsCalendar extends StatelessWidget {
  final HrAppointmentsController controller;
  final ValueChanged<HrAppointment> onView;
  final ValueChanged<DateTime>? onBook;

  const HrAppointmentsCalendar({
    super.key,
    required this.controller,
    required this.onView,
    this.onBook,
  });

  // The ListView builds children lazily, outside the page's Obx, so the
  // calendar must observe the controller itself or it never leaves "loading".
  @override
  Widget build(BuildContext context) =>
      Obx(() => _buildCalendar(context));

  Widget _buildCalendar(BuildContext context) {
    final c = controller;
    final month = c.calendarMonth.value;
    final (start, end) = c.calendarWindow;
    final days = end.difference(start).inDays + 1;
    final today = DateTime.now();
    return HandoverPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('appointments-calendar-prev'),
                onPressed: () => c.shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: handoverText(context, 15, weight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
              ),
              IconButton(
                key: const ValueKey('appointments-calendar-next'),
                onPressed: () => c.shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(onPressed: c.goToThisMonth, child: const Text('Today')),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: const [
              _Legend(AppColors.secondaryTeal, 'Family visit'),
              _Legend(Color(0xFF3B82F6), 'External'),
              _Legend(AppColors.urgentAmber, 'Pending'),
              _Legend(AppColors.textMuted, 'Cancelled / rejected'),
            ],
          ),
          if (c.calendarTruncated.value) ...[
            const SizedBox(height: 8),
            Text(
              'This month has more appointments than one view can load. Narrow it with the filters or use the list.',
              style: handoverText(context, 12, color: AppColors.urgentAmber),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (c.calendarLoading.value && c.calendarLoaded.value)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (!c.calendarLoaded.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 84,
              ),
              itemBuilder: (context, i) {
                final day = DateTime(start.year, start.month, start.day + i);
                final inMonth = day.month == month.month;
                final isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;
                final entries = c.calendarOn(day);
                final holiday = c.holidayName(day);
                return InkWell(
                  key: ValueKey('appointments-day-${day.year}-${day.month}-${day.day}'),
                  onTap: () => _openDay(context, day),
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: holiday != null
                          ? AppColors.urgentBackgroundSoft
                          : isToday
                              ? AppColors.secondaryTeal.withValues(alpha: 0.08)
                              : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${day.day}',
                              style: handoverText(
                                context,
                                12.5,
                                weight: FontWeight.w700,
                                color: !inMonth
                                    ? AppColors.textMuted.withValues(alpha: 0.5)
                                    : holiday != null
                                        ? AppColors.urgentAmber
                                        : isToday
                                            ? AppColors.secondaryTeal
                                            : AppColors.textHeading,
                              ),
                            ),
                            if (onBook != null && inMonth)
                              GestureDetector(
                                key: ValueKey('appointments-add-${day.day}'),
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onBook!(day),
                                child: const Icon(
                                  Icons.add,
                                  size: 15,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        if (holiday != null && inMonth)
                          const Icon(
                            Icons.celebration_outlined,
                            size: 11,
                            color: AppColors.urgentAmber,
                          ),
                        const Spacer(),
                        for (final a in entries.take(2))
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _dot(a).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              a.time.replaceAll(' ', '').toLowerCase(),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: _dot(a),
                              ),
                            ),
                          ),
                        if (entries.length > 2)
                          Text(
                            '+${entries.length - 2} more',
                            maxLines: 1,
                            style: handoverText(context, 8.5, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static Color _dot(HrAppointment a) {
    if (!a.isLive) return AppColors.textMuted;
    if (a.status == 'pending') return AppColors.urgentAmber;
    return a.isFamilyVisit ? AppColors.secondaryTeal : const Color(0xFF3B82F6);
  }

  Future<void> _openDay(BuildContext context, DateTime day) async {
    final entries = controller.calendarOn(day);
    final holiday = controller.holidayName(day);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day.weekday - 1]} ${day.day} ${_monthNames[day.month - 1]} ${day.year}',
                style: handoverText(sheet, 16, weight: FontWeight.w700, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 2),
              Text(
                entries.isEmpty
                    ? 'Nothing booked'
                    : '${entries.length} appointment${entries.length == 1 ? '' : 's'}',
                style: handoverText(sheet, 13, color: AppColors.textMuted),
              ),
              if (holiday != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.celebration_outlined, size: 16, color: AppColors.urgentAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        holiday,
                        style: handoverText(sheet, 13, weight: FontWeight.w600, color: AppColors.urgentAmber),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              for (final a in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    key: ValueKey('appointments-entry-${a.id}'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      onView(a);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a.time} · ${a.client}',
                            style: handoverText(sheet, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              a.typeLabel,
                              a.statusLabel,
                              if (a.purpose != null && a.purpose!.isNotEmpty) a.purpose!,
                              if (a.assigneeNames.isNotEmpty) 'Going: ${a.assigneeNames.join(', ')}',
                            ].join(' · '),
                            style: handoverText(sheet, 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (onBook != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: HandoverButton(
                    key: const ValueKey('appointments-book-day'),
                    label: 'Book an appointment',
                    icon: Icons.add_rounded,
                    filled: true,
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      onBook!(day);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 5),
          Text(label, style: handoverText(context, 11.5, color: AppColors.textMuted)),
        ],
      );
}
