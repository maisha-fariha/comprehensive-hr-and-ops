import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_activity_option.dart';

/// Search + resident / staff / type / date / status filters (web parity).
class StaffDailyActivityFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? clientId;
  final String? staffId;
  final String? activityType;
  final String? status;
  final DateTime? date;
  final List<StaffDailyActivityPersonOption> clients;
  final List<StaffDailyActivityPersonOption> staff;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onStaffChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final String Function(DateTime?) formatDate;

  const StaffDailyActivityFiltersBar({
    super.key,
    required this.searchController,
    required this.clientId,
    required this.staffId,
    required this.activityType,
    required this.status,
    required this.date,
    required this.clients,
    required this.staff,
    required this.onSearchChanged,
    required this.onClientChanged,
    required this.onStaffChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveHeight(context, 10);
    return Column(
      children: [
        TextField(
          key: const Key('staff-daily-activity-search'),
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.textHeading,
          ),
          decoration: InputDecoration(
            hintText: 'Search what was written...',
            hintStyle: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.secondaryTeal,
                width: 1.4,
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _Dropdown(
                value: clientId ?? 'all',
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All residents'),
                  ),
                  for (final c in clients)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => onClientChanged(v == 'all' ? null : v),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(
              child: _Dropdown(
                value: staffId ?? 'all',
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All staff'),
                  ),
                  for (final s in staff)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => onStaffChanged(v == 'all' ? null : v),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _Dropdown(
                value: activityType ?? 'all',
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All types'),
                  ),
                  for (final entry in StaffDailyActivityEnums.activityTypes)
                    DropdownMenuItem(
                      value: entry.$1,
                      child: Text(entry.$2),
                    ),
                ],
                onChanged: (v) => onTypeChanged(v == 'all' ? null : v),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(
              child: Material(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const Key('staff-daily-activity-date-filter'),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? now,
                      firstDate: now.subtract(const Duration(days: 365)),
                      lastDate: now.add(const Duration(days: 30)),
                    );
                    if (picked != null) onDateChanged(picked);
                  },
                  onLongPress: () => onDateChanged(null),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.searchBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatDate(date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textHeading,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _Dropdown(
          value: status ?? 'all',
          items: [
            const DropdownMenuItem(
              value: 'all',
              child: Text('All statuses'),
            ),
            for (final entry in StaffDailyActivityEnums.statuses)
              DropdownMenuItem(value: entry.$1, child: Text(entry.$2)),
          ],
          onChanged: (v) => onStatusChanged(v == 'all' ? null : v),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safe = items.any((i) => i.value == value) ? value : 'all';
    return DropdownButtonFormField<String>(
      key: ValueKey(safe),
      initialValue: safe,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.searchBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.searchBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondaryTeal,
            width: 1.4,
          ),
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: AppColors.textHeading,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
