import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Date picker + status dropdown for Attendance History (BUG_Report006).
class StaffAttendanceFiltersBar extends StatelessWidget {
  final DateTime? selectedDate;
  final String statusFilter;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<String> onStatusChanged;

  const StaffAttendanceFiltersBar({
    super.key,
    required this.selectedDate,
    required this.statusFilter,
    required this.onDateChanged,
    required this.onStatusChanged,
  });

  String _dateLabel(DateTime? date) {
    if (date == null) return 'All dates';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  lastDate: now,
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
                      width: ResponsiveHelper.getResponsiveWidth(context, 8),
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
                  DropdownMenuItem(value: 'all', child: Text('All status')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In progress'),
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
    );
  }
}
