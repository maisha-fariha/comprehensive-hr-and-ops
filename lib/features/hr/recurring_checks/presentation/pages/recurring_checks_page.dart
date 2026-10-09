import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/recurring_check.dart';
import '../controllers/recurring_checks_controller.dart';
import '../recurring_checks_labels.dart';
import '../widgets/assign_sheets.dart';
import '../widgets/check_cards.dart';
import '../widgets/check_common.dart';
import '../widgets/record_check_sheet.dart';
import '../widgets/schedule_form_sheet.dart';
import '../widgets/skip_check_sheet.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Manager "Recurring Checks" — mirrors web `/dashboard/recurring-checks`.
class RecurringChecksPage extends StatefulWidget {
  const RecurringChecksPage({super.key});

  @override
  State<RecurringChecksPage> createState() => _RecurringChecksPageState();
}

class _RecurringChecksPageState extends State<RecurringChecksPage> {
  late final RecurringChecksController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<RecurringChecksController>());
  }

  @override
  void dispose() {
    Get.delete<RecurringChecksController>();
    super.dispose();
  }

  Future<void> _confirmDelete(CheckSchedule s) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Delete this recurring check?',
          style: handoverText(dialogContext, 17, weight: FontWeight.w700),
        ),
        content: Text(
          'It stops producing checks and leaves the list. The checks already recorded '
          'against it are kept, so it can be restored.',
          style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          HandoverButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          Material(
            color: AppColors.criticalRed,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              key: const ValueKey('schedule-delete-confirm'),
              borderRadius: BorderRadius.circular(9),
              onTap: () => Navigator.of(dialogContext).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Delete',
                  style: handoverText(dialogContext, 13.5,
                      weight: FontWeight.w600, color: AppColors.surfaceWhite),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _c.deleteSchedule(s);
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHeading),
                    ),
                    Expanded(
                      child: Text(
                        'Recurring Checks',
                        style: handoverText(context, 18, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshCurrent,
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    _actions(context),
                    const SizedBox(height: 15),
                    _tabs(context),
                    const SizedBox(height: 15),
                    if (_c.tab.value == RecurringChecksTab.schedules)
                      ..._schedules(context)
                    else ...[
                      _filters(context),
                      const SizedBox(height: 15),
                      if (_c.tab.value == RecurringChecksTab.due)
                        ..._due(context)
                      else
                        ..._checks(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    if (!_c.canRecordProgress && !_c.canWrite) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_c.canRecordProgress)
          HandoverButton(
            key: const ValueKey('checks-record-progress'),
            label: 'Record Progress',
            icon: Icons.assignment_turned_in_outlined,
            onPressed: () => showRecordCheckSheet(context, controller: _c),
          ),
        if (_c.canWrite)
          HandoverButton(
            key: const ValueKey('checks-new-schedule'),
            label: 'New Schedule',
            icon: Icons.add_rounded,
            filled: true,
            onPressed: () => showScheduleFormSheet(context, controller: _c),
          ),
      ],
    );
  }

  Widget _tabs(BuildContext context) {
    const tabs = [
      (RecurringChecksTab.schedules, 'Schedules'),
      (RecurringChecksTab.due, 'Due'),
      (RecurringChecksTab.checks, 'Checks'),
    ];
    return HandoverPanel(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          for (final (tab, label) in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                key: ValueKey('checks-tab-${tab.name}'),
                onTap: () => _c.setTab(tab),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _c.tab.value == tab ? AppColors.filterButtonBackground : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: handoverText(
                      context,
                      13,
                      weight: _c.tab.value == tab ? FontWeight.w600 : FontWeight.w400,
                      color: _c.tab.value == tab ? AppColors.primaryNavy : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context) {
    final residenceOptions = [
      ('', 'All my residences'),
      for (final r in _c.residences) (r.id, r.label),
    ];
    final statusOptions = [('', 'Any status'), ...CheckLabels.statuses];
    String? labelOf(List<(String, String)> options, String? id) =>
        id == null ? null : options.where((o) => o.$1 == id).firstOrNull?.$2;
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HandoverSelect(
            key: const ValueKey('checks-residence-filter'),
            label: 'Residence',
            value: labelOf(residenceOptions, _c.residenceId.value),
            placeholder: 'All my residences',
            onTap: () async {
              final picked = await pickHandoverOption(context,
                  title: 'Residence', options: residenceOptions,
                  selected: _c.residenceId.value ?? '');
              if (picked != null) _c.setResidence(picked.isEmpty ? null : picked);
            },
          ),
          const SizedBox(height: 12),
          CheckPickerField(
            key: const ValueKey('checks-day-filter'),
            label: 'Day',
            value: WebFormat.date(_c.day.value),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _c.day.value,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) _c.setDay(picked);
            },
          ),
          const SizedBox(height: 12),
          HandoverSelect(
            key: const ValueKey('checks-status-filter'),
            label: 'Status',
            value: labelOf(statusOptions, _c.status.value),
            placeholder: 'Any status',
            onTap: () async {
              final picked = await pickHandoverOption(context,
                  title: 'Status', options: statusOptions, selected: _c.status.value ?? '');
              if (picked != null) _c.setStatus(picked.isEmpty ? null : picked);
            },
          ),
          const SizedBox(height: 12),
          CheckSwitchTile(
            key: const ValueKey('checks-mine-filter'),
            label: 'Only mine',
            description: 'Checks assigned to me',
            value: _c.mine.value,
            onChanged: _c.setMine,
          ),
        ],
      ),
    );
  }

  List<Widget> _skeletons(double height, int count) => [
        for (var i = 0; i < count; i++)
          Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ];

  List<Widget> _due(BuildContext context) {
    if (_c.listLoading.value && _c.instances.isEmpty) return _skeletons(86, 4);
    if (_c.instances.isEmpty) {
      final failed = _c.listError.value != null;
      return [
        HandoverPanel(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                failed ? 'Could not load the checks' : 'Nothing due in this window',
                textAlign: TextAlign.center,
                style: handoverText(context, 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                failed
                    ? _c.listError.value!
                    : 'Occurrences are written a day ahead, so a new schedule shows up '
                        'here shortly after it is created.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final i in _c.instances) ...[
        DueCheckCard(
          key: ValueKey('due-check-${i.id}'),
          instance: i,
          late: _c.isLate(i),
          locked: _c.lockedFor(i),
          canComplete: _c.canComplete,
          busy: _c.busyId.value == i.id,
          onAssign: () => showAssignInstanceSheet(context, controller: _c, instance: i),
          onRecord: () => showRecordCheckSheet(context, controller: _c, instance: i),
          onSkip: () => showSkipCheckSheet(context, controller: _c, instance: i),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _checks(BuildContext context) {
    if (_c.listLoading.value) return _skeletons(74, 3);
    if (_c.listError.value != null || _c.entries.isEmpty) {
      return [
        HandoverPanel(
          child: Text(
            _c.listError.value ?? 'No checks were recorded for these filters.',
            style: handoverText(context, 13,
                color: _c.listError.value != null ? AppColors.criticalRed : AppColors.textMuted),
          ),
        ),
      ];
    }
    return [
      for (final e in _c.entries) ...[
        RecordedCheckCard(key: ValueKey('recorded-check-${e.id}'), entry: e),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _schedules(BuildContext context) {
    final body = <Widget>[];
    if (_c.schedulesLoading.value && _c.schedules.isEmpty) {
      body.addAll(_skeletons(120, 3));
    } else if (_c.schedules.isEmpty) {
      body.add(
        HandoverPanel(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Text(
            _c.schedulesError.value ?? 'No recurring checks set up yet.',
            textAlign: TextAlign.center,
            style: handoverText(context, 13.5, color: AppColors.textMuted),
          ),
        ),
      );
    } else {
      for (final s in _c.schedules) {
        body
          ..add(ScheduleCard(
            key: ValueKey('schedule-${s.id}'),
            schedule: s,
            canWrite: _c.canWrite,
            busy: _c.busyId.value == s.id,
            onWho: () => showScheduleWhoSheet(context, controller: _c, schedule: s),
            onEdit: () => showScheduleFormSheet(context, controller: _c, editing: s),
            onToggle: () => _c.toggleSchedule(s),
            onDelete: () => _confirmDelete(s),
          ))
          ..add(const SizedBox(height: 12));
      }
    }
    body.add(
      AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: _c.total.value,
        totalPages: _c.totalPages.value,
        limitOptions: RecurringChecksController.limitOptions,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    );
    return body;
  }
}
