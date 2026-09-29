import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../recurring_checks/presentation/widgets/check_common.dart';
import '../controllers/daily_logs_controller.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

/// Residence*, Resident, and From / To (or Date on the day tab).
class DailyLogsFilters extends StatelessWidget {
  final DailyLogsController controller;

  const DailyLogsFilters({super.key, required this.controller});

  String _shown(String key) => WebFormat.date(DateTime.tryParse(key), empty: '');

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final hasResidence = c.hasResidence;
      final dayMode = c.tab.value == DailyLogsTab.day;
      return HandoverPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DailyLogSelect(
              key: const ValueKey('dl-residence'),
              label: 'Residence',
              required: true,
              value: c.residenceName,
              placeholder: 'Choose a residence',
              onTap: () async {
                final picked = await pickDailyLogOption(
                  context,
                  'Residence',
                  [for (final r in c.residences) (r.id, r.label)],
                  c.residenceId.value,
                );
                if (picked != null && picked != c.residenceId.value) c.setResidence(picked);
              },
            ),
            const SizedBox(height: 12),
            DailyLogSelect(
              key: const ValueKey('dl-resident'),
              label: 'Resident',
              value: c.clientName,
              placeholder: hasResidence ? 'Choose a resident' : 'Choose a residence first',
              onTap: hasResidence
                  ? () async {
                      final picked = await pickDailyLogOption(
                        context,
                        'Resident',
                        [for (final r in c.clients) (r.id, r.label)],
                        c.clientId.value,
                      );
                      if (picked != null && picked != c.clientId.value) c.setClient(picked);
                    }
                  : null,
              onClear: () => c.setClient(''),
            ),
            const SizedBox(height: 12),
            if (dayMode)
              CheckPickerField(
                key: const ValueKey('dl-date'),
                label: 'Date',
                value: _shown(c.logDate.value),
                onTap: () async {
                  final picked = await pickDailyLogDay(context, c.logDate.value);
                  if (picked != null) c.setLogDate(picked);
                },
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CheckPickerField(
                      key: const ValueKey('dl-from'),
                      label: 'From',
                      value: _shown(c.from.value),
                      onTap: () async {
                        final picked =
                            await pickDailyLogDay(context, c.from.value, max: c.to.value);
                        if (picked != null) c.setFrom(picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CheckPickerField(
                      key: const ValueKey('dl-to'),
                      label: 'To',
                      value: _shown(c.to.value),
                      onTap: () async {
                        final picked =
                            await pickDailyLogDay(context, c.to.value, min: c.from.value);
                        if (picked != null) c.setTo(picked);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}

class DailyLogsKpis extends StatelessWidget {
  final DailyLogsController controller;

  const DailyLogsKpis({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final tiles = [
        _Kpi(
          key: const ValueKey('dl-kpi-entries'),
          icon: Icons.description_outlined,
          color: AppColors.secondaryTeal,
          value: c.entriesLogged,
          label: 'Entries Logged',
          caption: DailyLogLabels.window(c.from.value, c.to.value),
        ),
        _Kpi(
          key: const ValueKey('dl-kpi-review'),
          icon: Icons.find_in_page_outlined,
          color: AppColors.infoBlue,
          value: c.review.value?.total ?? 0,
          label: 'Days To Review',
          caption: 'Resident-days with entries on them',
        ),
        _Kpi(
          key: const ValueKey('dl-kpi-missing'),
          icon: Icons.insert_drive_file_outlined,
          color: AppColors.urgentAmber,
          value: c.missing.value?.total ?? 0,
          label: 'Missing Logs',
          caption: 'Resident-days with nothing written',
        ),
        _Kpi(
          key: const ValueKey('dl-kpi-flags'),
          icon: Icons.warning_amber_rounded,
          color: AppColors.criticalRed,
          value: c.flagsTotal.value,
          label: 'Open Flags',
          caption: 'Raised and not yet resolved',
        ),
      ];
      return Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[row * 2]),
                  const SizedBox(width: 10),
                  Expanded(child: tiles[row * 2 + 1]),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final String caption;

  const _Kpi({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text('$value', style: handoverText(context, 24, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: handoverText(context, 11.5, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(caption, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class DailyLogsTabs extends StatelessWidget {
  final DailyLogsController controller;

  const DailyLogsTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => HandoverPanel(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final t in DailyLogsTab.values)
              InkWell(
                key: ValueKey('dl-tab-${t.name}'),
                onTap: () => controller.setTab(t),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: t == controller.tab.value
                        ? AppColors.filterButtonBackground
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DailyLogLabels.tabs[t.index],
                    style: handoverText(
                      context,
                      13,
                      weight: t == controller.tab.value ? FontWeight.w600 : FontWeight.w400,
                      color: t == controller.tab.value
                          ? AppColors.primaryNavy
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
