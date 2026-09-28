import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';

/// Date + residence + status filters for Attendance History (BUG_Report006).
/// Matches web: date range control, "All Residences", "Any status".
class StaffAttendanceFiltersBar extends StatelessWidget {
  final DateTime? selectedDate;
  final String residenceFilter;
  final String statusFilter;
  final List<ManualEntryResidenceOption> residences;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<String> onResidenceChanged;
  final ValueChanged<String> onStatusChanged;

  const StaffAttendanceFiltersBar({
    super.key,
    required this.selectedDate,
    required this.residenceFilter,
    required this.statusFilter,
    required this.residences,
    required this.onDateChanged,
    required this.onResidenceChanged,
    required this.onStatusChanged,
  });

  String _dateLabel(DateTime? date) {
    if (date == null) return 'All dates';
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 10),
    );
    final residenceItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'all', child: Text('All Residences')),
      for (final residence in residences)
        DropdownMenuItem(
          value: residence.id,
          child: Text(residence.name),
        ),
    ];
    final residenceValue = residenceItems.any((i) => i.value == residenceFilter)
        ? residenceFilter
        : 'all';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Material(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
                child: InkWell(
                  key: const Key('staff-attendance-date-picker'),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? now,
                      firstDate: now.subtract(const Duration(days: 365)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) onDateChanged(picked);
                  },
                  onLongPress: () => onDateChanged(null),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 14),
                  ),
                  child: Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 14),
                      ),
                      border: Border.all(color: AppColors.searchBorder),
                    ),
                    child: Row(
                      children: [
                        const AppSvgIcon(
                          AppAssets.navCalendar,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(
                            context,
                            8,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _dateLabel(selectedDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13,
                              ),
                              color: AppColors.textHeading,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: Container(
                key: const Key('staff-attendance-residence-dropdown'),
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 14),
                  ),
                  border: Border.all(color: AppColors.searchBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: residenceValue,
                    items: residenceItems,
                    onChanged: (value) {
                      if (value != null) onResidenceChanged(value);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: Container(
                key: const Key('staff-attendance-status-dropdown'),
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 14),
                  ),
                  border: Border.all(color: AppColors.searchBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: statusFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Any status'),
                      ),
                      DropdownMenuItem(
                        value: 'present',
                        child: Text('Present'),
                      ),
                      DropdownMenuItem(value: 'late', child: Text('Late')),
                      DropdownMenuItem(value: 'missed', child: Text('Missed')),
                      DropdownMenuItem(
                        value: 'pending_approval',
                        child: Text('Pending approval'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onStatusChanged(value);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
