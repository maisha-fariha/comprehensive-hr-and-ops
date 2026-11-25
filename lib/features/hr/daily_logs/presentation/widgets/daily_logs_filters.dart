import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../controllers/daily_logs_controller.dart';
import 'daily_log_common.dart';

/// Residence + date (+ resident search on Today).
class DailyLogsFilters extends StatelessWidget {
  final DailyLogsController controller;

  const DailyLogsFilters({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final today = DailyLogsController.dayKey(DateTime.now());
      final date = DateTime.tryParse(c.logDate.value) ?? DateTime.now();
      final dateLabel = c.logDate.value == today
          ? 'Today · ${_weekday(date)} ${date.day} ${_month(date)}'
          : '${_weekday(date)} ${date.day} ${_month(date)}';
      return HandoverPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DailyLogSelect(
              key: const ValueKey('dl-residence'),
              label: 'Home',
              value: c.residenceName,
              placeholder: 'Choose a home',
              required: true,
              onTap: () async {
                final picked = await pickDailyLogOption(
                  context,
                  'Home',
                  [for (final r in c.residences) (r.id, r.label)],
                  c.residenceId.value,
                );
                if (picked != null && picked != c.residenceId.value) {
                  c.setResidence(picked);
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('dl-date-prev'),
                  onPressed: () => c.shiftLogDate(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: InkWell(
                    key: const ValueKey('dl-date'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) c.setLogDate(DailyLogsController.dayKey(picked));
                    },
                    child: Text(
                      dateLabel,
                      textAlign: TextAlign.center,
                      style: handoverText(context, 14, weight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('dl-date-next'),
                  onPressed: () => c.shiftLogDate(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            if (c.tab.value == DailyLogsTab.today && !c.viewingResidentDay) ...[
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('dl-resident-search'),
                onChanged: c.setResidentQuery,
                decoration: InputDecoration(
                  hintText: 'Find a resident',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceWhite,
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
            ],
            // Activities uses the board Home + date above; staff/type/status
            // search live on the Client Activity Registry strip (web
            // hideDuplicateFilters). Do not show a second From/To here.
          ],
        ),
      );
    });
  }

  String _weekday(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  String _month(DateTime d) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          [d.month - 1];
}

/// Web tabs: Today / Review / Activities.
class DailyLogsTabs extends StatelessWidget {
  final DailyLogsController controller;

  const DailyLogsTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final tab = c.tab.value;
      final openFlags = c.flagsTotal.value;
      return HandoverPanel(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _TabChip(
              tabKey: 'today',
              label: 'Today',
              selected: tab == DailyLogsTab.today,
              onTap: () => c.setTab(DailyLogsTab.today),
            ),
            if (c.canReview)
              _TabChip(
                tabKey: 'review',
                label: 'Review',
                // Badge only when the user can see open flags (`care-flags:read`).
                count: c.canReadFlags ? openFlags : 0,
                badge: c.canReadFlags && openFlags > 0,
                selected: tab == DailyLogsTab.review,
                onTap: () => c.setTab(DailyLogsTab.review),
              ),
            if (c.canReadActivities)
              _TabChip(
                tabKey: 'activities',
                label: 'Activities',
                selected: tab == DailyLogsTab.activities,
                onTap: () => c.setTab(DailyLogsTab.activities),
              ),
          ],
        ),
      );
    });
  }
}

class _TabChip extends StatelessWidget {
  final String tabKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final bool badge;

  const _TabChip({
    required this.tabKey,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('dl-tab-$tabKey'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.filterButtonBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? const Border(bottom: BorderSide(color: AppColors.secondaryTeal, width: 2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: handoverText(
                context,
                13,
                weight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primaryNavy : AppColors.textMuted,
              ),
            ),
            if (badge && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: handoverText(context, 10.5, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
