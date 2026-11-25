import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_log.dart';
import '../controllers/daily_logs_controller.dart';
import '../daily_logs_labels.dart';
import 'ai_day_assistant_card.dart';
import 'daily_log_common.dart';
import 'daily_summary_card.dart';
import 'day_timeline.dart';

/// Web resident-day drill-down: back link, header, + Record, The day feed,
/// Today so far stats, and AI summarise.
class ResidentDaySection extends StatelessWidget {
  final DailyLogsController controller;
  final VoidCallback onBack;
  final VoidCallback? onWriteNote;
  final VoidCallback? onRecordIncident;
  final VoidCallback? onRecordDose;
  final VoidCallback? onRecordCheck;
  final VoidCallback? onRecordTask;
  final ValueChanged<DailyLogEntry>? onOpenEntry;
  final ValueChanged<DailyLogEntry>? onAmend;
  final ValueChanged<DailyLogEntry>? onDelete;

  const ResidentDaySection({
    super.key,
    required this.controller,
    required this.onBack,
    this.onWriteNote,
    this.onRecordIncident,
    this.onRecordDose,
    this.onRecordCheck,
    this.onRecordTask,
    this.onOpenEntry,
    this.onAmend,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final room = c.clientRoom;
      final home = c.dayResidenceName.isNotEmpty ? c.dayResidenceName : c.residenceName;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const ValueKey('dl-back-today'),
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.secondaryTeal),
                  Expanded(
                    child: Text(
                      'Today at ${home.isEmpty ? 'home' : home}',
                      style: handoverText(
                        context,
                        13.5,
                        weight: FontWeight.w700,
                        color: AppColors.secondaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          HandoverPanel(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
                  child: Text(
                    _initials(c.clientName),
                    style: const TextStyle(
                      color: AppColors.secondaryTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.clientName.isEmpty ? 'Resident' : c.clientName,
                        style: handoverText(context, 16, weight: FontWeight.w700),
                      ),
                      Text(
                        [
                          if ((room ?? '').isNotEmpty) 'Room $room',
                          if (home.isNotEmpty) home,
                        ].join(' · '),
                        style: handoverText(context, 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (c.canWrite)
                  PopupMenuButton<String>(
                    key: const ValueKey('dl-record-menu'),
                    offset: const Offset(0, 40),
                    onSelected: (value) {
                      switch (value) {
                        case 'note':
                          onWriteNote?.call();
                        case 'incident':
                          onRecordIncident?.call();
                        case 'dose':
                          onRecordDose?.call();
                        case 'check':
                          onRecordCheck?.call();
                        case 'task':
                          onRecordTask?.call();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'note', child: Text('Care note')),
                      if (onRecordIncident != null)
                        const PopupMenuItem(value: 'incident', child: Text('Incident')),
                      if (onRecordDose != null)
                        const PopupMenuItem(value: 'dose', child: Text('Dose (MAR)')),
                      if (onRecordCheck != null)
                        const PopupMenuItem(value: 'check', child: Text('Check')),
                      if (onRecordTask != null)
                        const PopupMenuItem(value: 'task', child: Text('Task')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Record',
                            style: handoverText(
                              context,
                              13,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DateStepper(controller: c),
          const SizedBox(height: 14),
          _TodayStats(controller: c),
          const SizedBox(height: 14),
          _DayFeed(
            controller: c,
            onOpenEntry: onOpenEntry,
            onAmend: onAmend,
            onDelete: onDelete,
          ),
          const SizedBox(height: 14),
          AiDayAssistantCard(
            clientId: c.clientId.value,
            clientName: c.clientName,
            logDate: c.logDate.value,
          ),
          const SizedBox(height: 12),
          DailySummaryCard(
            clientId: c.clientId.value,
            clientName: c.clientName,
            logDate: c.logDate.value,
            canReview: c.canReview,
          ),
        ],
      );
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _DateStepper extends StatelessWidget {
  final DailyLogsController controller;

  const _DateStepper({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final key = controller.logDate.value;
      final date = DateTime.tryParse(key) ?? DateTime.now();
      final today = DailyLogsController.dayKey(DateTime.now());
      final label = key == today
          ? 'Today · ${_weekday(date)} ${date.day} ${_month(date)}'
          : '${_weekday(date)} ${date.day} ${_month(date)}';
      return Row(
        children: [
          IconButton(
            key: const ValueKey('dl-date-prev'),
            onPressed: () => controller.shiftLogDate(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: handoverText(context, 14, weight: FontWeight.w700),
            ),
          ),
          IconButton(
            key: const ValueKey('dl-date-next'),
            onPressed: () => controller.shiftLogDate(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      );
    });
  }

  String _weekday(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  String _month(DateTime d) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          [d.month - 1];
}

class _TodayStats extends StatelessWidget {
  final DailyLogsController controller;

  const _TodayStats({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final tiles = [
        (c.notesWrittenToday, 'notes written', false),
        (c.dosesRecordedToday, 'doses recorded', false),
        (c.checksDoneToday, 'checks done', false),
        (c.openFlagsForResident, 'open flags', true),
      ];
      return HandoverPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Today so far',
              style: handoverText(context, 14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label, alert) in tiles)
                  Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alert && value > 0
                          ? AppColors.criticalBackgroundSoft
                          : AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$value',
                          style: handoverText(
                            context,
                            20,
                            weight: FontWeight.w800,
                            color: alert && value > 0
                                ? AppColors.criticalRed
                                : AppColors.textHeading,
                          ),
                        ),
                        Text(
                          label,
                          style: handoverText(context, 12, color: AppColors.textMuted),
                        ),
                      ],
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

class _DayFeed extends StatelessWidget {
  final DailyLogsController controller;
  final ValueChanged<DailyLogEntry>? onOpenEntry;
  final ValueChanged<DailyLogEntry>? onAmend;
  final ValueChanged<DailyLogEntry>? onDelete;

  const _DayFeed({
    required this.controller,
    this.onOpenEntry,
    this.onAmend,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final feed = c.feed.value;
      final filter = c.feedFilter.value;
      final items = feed?.items ?? const <DailyActivityFeedItem>[];
      final filtered = [
        for (final item in items)
          if (_matches(filter, item)) item,
      ];
      final medCount = items.where((i) => i.module == 'mar').length;
      final checkTaskCount = items
          .where((i) => i.module == 'tasks' || i.module == 'recurringChecks')
          .length;

      return HandoverPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The day',
              style: handoverText(context, 14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, c, 'all', 'All ${items.length}'),
                _chip(context, c, 'medication', 'Medication $medCount'),
                _chip(context, c, 'checks', 'Checks & tasks $checkTaskCount'),
              ],
            ),
            const SizedBox(height: 12),
            if (c.feedLoading.value && feed == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.secondaryTeal),
                ),
              )
            else if (filtered.isEmpty) ...[
              Text(
                'No activity for this filter yet.',
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              DayTimeline(
                day: c.day.value,
                loading: c.dayLoading.value,
                canWrite: c.canWrite,
                onOpen: onOpenEntry ?? (_) {},
                onAmend: onAmend ?? (_) {},
                onDelete: onDelete ?? (_) {},
              ),
            ] else ...[
              for (final item in filtered) _FeedRow(item: item),
              if ((c.day.value?.entries.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 8),
                Text(
                  'Care notes',
                  style: handoverText(context, 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DayTimeline(
                  day: c.day.value,
                  loading: c.dayLoading.value,
                  canWrite: c.canWrite,
                  onOpen: onOpenEntry ?? (_) {},
                  onAmend: onAmend ?? (_) {},
                  onDelete: onDelete ?? (_) {},
                ),
              ],
            ],
          ],
        ),
      );
    });
  }

  bool _matches(String filter, DailyActivityFeedItem item) {
    if (filter == 'all') return true;
    if (filter == 'medication') return item.module == 'mar';
    if (filter == 'checks') {
      return item.module == 'tasks' || item.module == 'recurringChecks';
    }
    return true;
  }

  Widget _chip(
    BuildContext context,
    DailyLogsController c,
    String value,
    String label,
  ) {
    final selected = c.feedFilter.value == value;
    return InkWell(
      key: ValueKey('dl-feed-filter-$value'),
      onTap: () => c.setFeedFilter(value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryTeal : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.secondaryTeal : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: handoverText(
            context,
            12.5,
            weight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textHeading,
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  final DailyActivityFeedItem item;

  const _FeedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final time = WebFormat.time(TenantClock.wallOf(item.occurredAt));
    final moduleLabel = switch (item.module) {
      'mar' => 'Medication',
      'tasks' => 'Task',
      'recurringChecks' => 'Check',
      'incidents' => 'Incident',
      'activities' => 'Activity',
      'handovers' => 'Handover',
      _ => DailyLogLabels.capitalise(item.module),
    };
    final tone = DailyLogLabels.moduleTones[item.module] ?? DailyLogTone.info;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              time,
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
          ),
          Icon(
            item.module == 'mar' ? Icons.medication_outlined : Icons.task_alt_rounded,
            size: 16,
            color: tone.foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '$moduleLabel${item.staffName == null ? '' : ' · ${item.staffName}'}',
                      style: handoverText(context, 13, weight: FontWeight.w700),
                    ),
                    if (item.detail.trim().isNotEmpty)
                      DailyLogPill(
                        item.detail,
                        tone: item.detail.toLowerCase() == 'given'
                            ? DailyLogTone.success
                            : tone,
                      ),
                  ],
                ),
                if (item.title.trim().isNotEmpty)
                  Text(
                    item.title,
                    style: handoverText(context, 12.5, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
