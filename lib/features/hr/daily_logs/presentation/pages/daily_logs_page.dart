import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../hr_shell.dart';
import '../../../presentation/manager_destinations.dart';
import '../../../presentation/open_manager_portal_search.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../controllers/daily_logs_controller.dart';
import '../widgets/daily_log_common.dart';
import '../widgets/daily_logs_filters.dart';
import '../widgets/daily_logs_lists.dart';
import '../widgets/day_timeline.dart';
import '../widgets/entry_sheets.dart';
import '../widgets/new_log_entry_sheet.dart';
import '../widgets/side_panels.dart';

/// Web `notificationHref` targets that have a manager screen in the app.
const _entityDestinations = {
  'shift': 'Scheduling',
  'shift_swap': 'Scheduling',
  'shift_handover': 'Shift Handovers',
  'attendance_record': 'Attendance',
  'task': 'Tasks & Compliance',
  'compliance_score': 'Tasks & Compliance',
  'compliance_check': 'Tasks & Compliance',
  'corrective_action': 'Tasks & Compliance',
  'incident': 'Incidents',
  'client': 'Clients',
  'medication_chart': 'Medication',
  'medication_stock': 'Medication',
  'recurring_check': 'Recurring Checks',
  'conversation': 'Communication',
};

/// Manager "Daily Logs" — mirrors web `/dashboard/daily-logs`.
class DailyLogsPage extends StatefulWidget {
  final DailyLogFilePicker? pickFiles;

  const DailyLogsPage({super.key, this.pickFiles});

  static const int _moreTabIndex = 4;

  @override
  State<DailyLogsPage> createState() => _DailyLogsPageState();
}

class _DailyLogsPageState extends State<DailyLogsPage> {
  late final DailyLogsController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<DailyLogsController>());
  }

  @override
  void dispose() {
    Get.delete<DailyLogsController>();
    super.dispose();
  }

  VoidCallback? _openFor(String? entityType, String? _) {
    final title = _entityDestinations[entityType];
    if (title == null) return null;
    final destination = managerDestinations().firstWhereOrNull((d) => d.title == title);
    return destination?.open;
  }

  VoidCallback? get _openMedication =>
      managerDestinations().firstWhereOrNull((d) => d.title == 'Medication')?.open;

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshAll,
              child: Obx(
                () => ListView(
                  key: const ValueKey('dl-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: _content(context),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => HrBottomNavBar(
          currentIndex: DailyLogsPage._moreTabIndex,
          onTap: (index) => Get.offAll(() => HrShell(initialIndex: index)),
          alertsBadgeCount: hrAlertsBadgeCount(),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 36);
    return ColoredBox(
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
                  'Daily Logs',
                  style: handoverText(context, 18, weight: FontWeight.w700),
                ),
              ),
              Obx(
                () => _c.showAddEntry
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: HandoverButton(
                          key: const ValueKey('dl-add-entry'),
                          label: 'Add Entry',
                          icon: Icons.add_rounded,
                          filled: true,
                          compact: true,
                          onPressed: () => showNewLogEntrySheet(
                            context,
                            controller: _c,
                            pickFiles: widget.pickFiles,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              GestureDetector(
                onTap: openManagerPortalSearch,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(AppAssets.search, size: 18, color: AppColors.textHeading),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final tab = _c.tab.value;
    final hasResidence = _c.hasResidence;
    return [
      DailyLogsFilters(controller: _c),
      const SizedBox(height: 15),
      if (hasResidence && tab != DailyLogsTab.day) ...[
        DailyLogsKpis(controller: _c),
        const SizedBox(height: 15),
      ],
      DailyLogsTabs(controller: _c),
      const SizedBox(height: 15),
      if (!hasResidence)
        const DailyLogEmptyCard(
          title: 'Choose a residence to begin',
          description: 'Daily logs are read one residence at a time.',
        )
      else ...[
        ..._main(context, tab),
        const SizedBox(height: 15),
        ShiftDocumentationPanel(
          rows: _c.shiftLogs.toList(),
          loading: _c.shiftLogsLoading.value,
          canWrite: _c.canWrite,
          canReview: _c.canReview,
          busyId: _c.busyShiftId.value,
          onUpdate: _c.updateShiftLog,
        ),
        const SizedBox(height: 15),
        PriorityNotesPanel(
          flags: _c.flags.toList(),
          loading: _c.flagsLoading.value,
          error: _c.flagsError.value,
          canResolve: _c.canResolveFlags,
          onResolve: (f) => showResolveFlagSheet(context, controller: _c, flag: f),
        ),
      ],
    ];
  }

  Widget _pagination() {
    final (total, totalPages) = _c.paging;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: total,
        totalPages: totalPages,
        limitOptions: DailyLogsController.limitOptions,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    );
  }

  List<Widget> _main(BuildContext context, DailyLogsTab tab) {
    switch (tab) {
      case DailyLogsTab.review:
        final rows = _c.review.value?.items ?? const [];
        return [
          ReviewQueueList(
            rows: rows,
            loading: _c.reviewLoading.value,
            error: _c.reviewError.value,
            onOpen: (r) => _c.openDay(r.clientId, r.logDate, name: r.clientName),
          ),
          if (rows.isNotEmpty) _pagination(),
        ];
      case DailyLogsTab.missing:
        final rows = _c.missing.value?.items ?? const [];
        return [
          MissingLogsList(
            rows: rows,
            loading: _c.missingLoading.value,
            error: _c.missingError.value,
            onWrite: (r) => _c.openDay(r.clientId, r.logDate, name: r.clientName),
          ),
          if (rows.isNotEmpty) _pagination(),
        ];
      case DailyLogsTab.activity:
        final rows = _c.activity.value?.items ?? const [];
        return [
          HouseActivityList(
            rows: rows,
            loading: _c.activityLoading.value,
            openFor: _openFor,
          ),
          if (rows.isNotEmpty) _pagination(),
        ];
      case DailyLogsTab.day:
        if (_c.clientId.value.isEmpty) {
          return const [
            DailyLogEmptyCard(
              title: 'Choose a resident',
              description: 'A day view is one resident on one date.',
            ),
          ];
        }
        return [
          if (_c.dayError.value case final error?) ...[
            DailyLogFormError(error),
            const SizedBox(height: 12),
          ],
          DayTimeline(
            day: _c.day.value,
            loading: _c.dayLoading.value,
            canWrite: _c.canWrite,
            onOpen: (e) => showEntryDetailSheet(context, controller: _c, entryId: e.id),
            onAmend: (e) => showAmendEntrySheet(context, controller: _c, entry: e),
            onDelete: (e) => confirmDeleteEntry(context, controller: _c, entry: e),
            onMedication: _openMedication == null ? null : (_) => _openMedication!(),
          ),
        ];
    }
  }
}
