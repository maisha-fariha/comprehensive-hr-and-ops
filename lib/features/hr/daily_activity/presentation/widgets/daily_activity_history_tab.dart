import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_activity.dart';
import '../controllers/daily_activity_controller.dart';
import '../daily_activity_labels.dart';
import 'daily_activity_common.dart';
import 'daily_activity_registry.dart';

/// Web "Resident history": one resident's month, its summary and records.
class DailyActivityHistoryTab extends StatelessWidget {
  final DailyActivityController controller;
  final ValueChanged<DailyActivity> onView;
  final ValueChanged<DailyActivity>? onEdit;

  const DailyActivityHistoryTab({
    super.key,
    required this.controller,
    required this.onView,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final client = c.historyClient;
      final clientId = c.historyClientId.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HandoverPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DailyActivitySelect(
                        key: const ValueKey('daily-activity-history-resident'),
                        title: 'Choose a resident',
                        options: [
                          if (clientId == null) ('', 'Choose a resident'),
                          for (final o in c.clients) (o.id, o.name),
                        ],
                        selected: clientId ?? '',
                        onChanged: c.setHistoryClient,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MonthButton(
                      value: c.historyMonth.value,
                      onChanged: c.setHistoryMonth,
                    ),
                  ],
                ),
                if (client != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${client.residenceName ?? '—'}'
                    '${client.level == null ? '' : ' · ${DailyActivityLabels.humanise(client.level)}'}',
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (clientId == null)
            const HandoverPanel(
              child: DailyActivityEmpty(
                icon: Icons.date_range_outlined,
                title: 'Choose a resident',
                message: 'Their month appears here — what was recorded, and how it went.',
              ),
            )
          else
            ..._month(context, client),
        ],
      );
    });
  }

  List<Widget> _month(BuildContext context, DailyActivityOption? client) {
    final c = controller;
    final summary = c.monthSummary.value;
    final items = c.historyItems;
    final size = c.historyPageSize.value;
    final pages = items.isEmpty ? 0 : (items.length + size - 1) ~/ size;
    final page = c.historyPage.value.clamp(1, pages == 0 ? 1 : pages);
    final visible = items.skip((page - 1) * size).take(size).toList();
    const nothing = 'Nothing recorded this month.';
    return [
      if (c.monthSummaryError.value != null) ...[
        HandoverPanel(
          child: Text(
            c.monthSummaryError.value!,
            style: handoverText(context, 13.5, color: AppColors.criticalRed),
          ),
        ),
        const SizedBox(height: 15),
      ],
      HandoverPanel(
        key: const ValueKey('daily-activity-month-status'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How the month went', style: handoverText(context, 13, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (summary == null || summary.byStatus.isEmpty)
              Text(nothing, style: handoverText(context, 13, color: AppColors.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (status, count) in summary.byStatus)
                    DailyActivityPill(
                      label: '${DailyActivityLabels.humanise(status)} · $count',
                      tone: status == 'completed'
                          ? DailyActivityTone.success
                          : DailyActivityTone.warning,
                    ),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      HandoverPanel(
        key: const ValueKey('daily-activity-month-type'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What they did', style: handoverText(context, 13, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (summary == null || summary.byType.isEmpty)
              Text(nothing, style: handoverText(context, 13, color: AppColors.textMuted))
            else
              for (final (type, count) in summary.byType)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DailyActivityLabels.humanise(type),
                          style: handoverText(context, 12.5, color: AppColors.textMuted),
                        ),
                      ),
                      Text(
                        '$count',
                        style: handoverText(
                          context,
                          12.5,
                          weight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      DailyActivityRegistry(
        title: client == null ? 'History' : '${client.name} — ${c.historyMonth.value}',
        subtitle: 'Everything recorded for this resident in the month shown',
        pendingReview: items.where((a) => a.isPendingReview).length,
        items: visible,
        loading: c.historyLoading.value,
        emptyTitle: 'Nothing this month',
        emptyMessage: 'Pick another month, or record the first activity.',
        onView: onView,
        onEdit: onEdit,
        footer: items.isEmpty
            ? null
            : AttendancePagination(
                page: page,
                limit: size,
                total: items.length,
                totalPages: pages,
                limitOptions: DailyActivityController.pageSizes,
                onPage: c.setHistoryPage,
                onLimit: c.setHistoryPageSize,
              ),
      ),
    ];
  }
}

class _MonthButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _MonthButton({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        key: const ValueKey('daily-activity-history-month'),
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          final picked = await showDailyActivityMonthPicker(context, value);
          if (picked != null && picked != value) onChanged(picked);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DailyActivityLabels.monthLabel(value),
                style: handoverText(context, 13.5, weight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Year + month grid; returns `YYYY-MM`.
Future<String?> showDailyActivityMonthPicker(BuildContext context, String current) {
  final parts = current.split('-');
  var year = int.tryParse(parts.first) ?? DateTime.now().year;
  final selectedYear = year;
  final selectedMonth = parts.length == 2 ? int.tryParse(parts[1]) : null;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('daily-activity-month-prev-year'),
                    onPressed: () => setState(() => year--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '$year',
                      textAlign: TextAlign.center,
                      style: handoverText(context, 16, weight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('daily-activity-month-next-year'),
                    onPressed: () => setState(() => year++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var m = 1; m <= 12; m++)
                    _MonthCell(
                      label: DailyActivityLabels.monthName(m).substring(0, 3),
                      selected: year == selectedYear && m == selectedMonth,
                      onTap: () => Navigator.of(sheetContext)
                          .pop('$year-${m.toString().padLeft(2, '0')}'),
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

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MonthCell({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.secondaryTeal : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.secondaryTeal : AppColors.searchBorder,
            ),
          ),
          child: Text(
            label,
            style: handoverText(
              context,
              13.5,
              weight: FontWeight.w600,
              color: selected ? AppColors.surfaceWhite : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}
