import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/attendance_week.dart';

TextStyle _outfit(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.textHeading,
}) =>
    TextStyle(
      fontFamily: 'Outfit',
      fontWeight: weight,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, size),
      color: color,
    );

/// Bordered 40-high control shared by the week button and the selects.
class _FilterShell extends StatelessWidget {
  final Widget leading;
  final String label;
  final VoidCallback? onTap;

  const _FilterShell({
    super.key,
    required this.leading,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius:
          BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 9)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 9),
        ),
        child: Container(
          height: ResponsiveHelper.getResponsiveHeight(context, 40),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.searchBorder),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 9),
            ),
          ),
          child: Row(
            children: [
              leading,
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _outfit(context, 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceWeekButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AttendanceWeekButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _FilterShell(
      key: const ValueKey('attendance-week'),
      leading: Icon(
        Icons.calendar_today_outlined,
        size: ResponsiveHelper.getResponsiveSize(context, 16),
        color: AppColors.textSecondary,
      ),
      label: label,
      onTap: onTap,
    );
  }
}

/// A select that opens a bottom-sheet list, like the web `<Select>`.
class AttendanceSelectField<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const AttendanceSelectField({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FilterShell(
      leading: Icon(
        Icons.unfold_more_rounded,
        size: ResponsiveHelper.getResponsiveSize(context, 16),
        color: AppColors.textSecondary,
      ),
      label: labelOf(value),
      onTap: () async {
        final picked = await showAttendanceOptionSheet<T>(
          context,
          title: title,
          options: options,
          labelOf: labelOf,
          selected: value,
        );
        if (picked != null && picked.value != value) onChanged(picked.value);
      },
    );
  }
}

/// Wraps a picked value so `null` options stay distinguishable from dismiss.
class PickedOption<T> {
  final T value;
  const PickedOption(this.value);
}

Future<PickedOption<T>?> showAttendanceOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  T? selected,
}) {
  return showModalBottomSheet<PickedOption<T>>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: _outfit(sheetContext, 16, weight: FontWeight.w700),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(labelOf(option), style: _outfit(sheetContext, 14)),
                trailing: option == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.secondaryTeal)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(PickedOption(option)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// The web week popover: previous/next week arrows around the month label,
/// and a calendar where picking any day selects its Monday–Sunday week.
Future<DateTime?> showAttendanceWeekPicker(
  BuildContext context, {
  required AttendanceWeek week,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('attendance-week-prev'),
                  tooltip: 'Previous week',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(week.previous.start),
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[week.start.month - 1]} ${week.start.year}',
                    textAlign: TextAlign.center,
                    style: _outfit(sheetContext, 15, weight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  key: const ValueKey('attendance-week-next'),
                  tooltip: 'Next week',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(week.next.start),
                ),
              ],
            ),
            CalendarDatePicker(
              initialDate: week.start,
              firstDate: DateTime(week.start.year - 5),
              lastDate: DateTime(week.start.year + 5),
              onDateChanged: (day) => Navigator.of(sheetContext).pop(day),
            ),
          ],
        ),
      ),
    ),
  );
}

const _monthNames = [
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
