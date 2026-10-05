import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../controllers/daily_activity_controller.dart';
import '../daily_activity_labels.dart';
import 'daily_activity_common.dart';

/// Registry filter bar: search plus resident, staff, type, date and status.
class DailyActivityFilters extends StatelessWidget {
  final DailyActivityController controller;
  final TextEditingController searchController;

  const DailyActivityFilters({
    super.key,
    required this.controller,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    Widget pair(Widget a, Widget b) => Row(
          children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)],
        );
    return HandoverPanel(
      padding: const EdgeInsets.all(12),
      child: Obx(
        () => Column(
          children: [
            TextField(
              key: const ValueKey('daily-activity-search'),
              controller: searchController,
              onChanged: c.setSearch,
              style: handoverText(context, 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search what was written…',
                hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceWhite,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.searchBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.searchBorder),
                ),
              ),
            ),
            const SizedBox(height: 10),
            pair(
              DailyActivitySelect(
                key: const ValueKey('daily-activity-filter-resident'),
                title: 'Resident',
                options: [
                  ('', 'All residents'),
                  for (final o in c.clients) (o.id, o.name),
                ],
                selected: c.clientId.value ?? '',
                onChanged: c.setClient,
              ),
              DailyActivitySelect(
                key: const ValueKey('daily-activity-filter-staff'),
                title: 'Staff',
                options: [
                  ('', 'All staff'),
                  for (final o in c.staff) (o.id, o.name),
                ],
                selected: c.staffId.value ?? '',
                onChanged: c.setStaff,
              ),
            ),
            const SizedBox(height: 10),
            pair(
              DailyActivitySelect(
                key: const ValueKey('daily-activity-filter-type'),
                title: 'Activity type',
                options: const [('', 'All types'), ...DailyActivityLabels.types],
                selected: c.activityType.value ?? '',
                onChanged: c.setType,
              ),
              DailyActivitySelect(
                key: const ValueKey('daily-activity-filter-date'),
                title: 'Date',
                options: DailyActivityLabels.dateRanges,
                selected: c.range.value ?? '',
                onChanged: c.setRange,
              ),
            ),
            const SizedBox(height: 10),
            DailyActivitySelect(
              key: const ValueKey('daily-activity-filter-status'),
              title: 'Status',
              options: const [('', 'All statuses'), ...DailyActivityLabels.statuses],
              selected: c.status.value ?? '',
              onChanged: c.setStatus,
            ),
          ],
        ),
      ),
    );
  }
}
