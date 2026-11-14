import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_role.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../daily_activity/presentation/controllers/daily_activity_controller.dart';
import '../../../daily_activity/presentation/widgets/daily_activity_form_sheet.dart';
import '../../../daily_activity/presentation/widgets/daily_activity_group_sheet.dart';
import '../../../handovers/presentation/pages/handovers_page.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../hr_shell.dart';
import '../../../presentation/manager_destinations.dart';
import '../../../presentation/open_manager_portal_search.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../../../staff/extras/presentation/pages/staff_shift_handovers_page.dart';
import '../../../../staff/presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../../staff/search/presentation/pages/staff_search_page.dart';
import '../../../../staff/staff_shell.dart';
import '../../domain/entities/daily_log.dart';
import '../controllers/daily_logs_controller.dart';
import '../widgets/daily_log_common.dart';
import '../widgets/daily_logs_activities_section.dart';
import '../widgets/daily_logs_filters.dart';
import '../widgets/daily_logs_lists.dart';
import '../widgets/entry_sheets.dart';
import '../widgets/new_log_entry_sheet.dart';
import '../widgets/resident_day_section.dart';
import '../widgets/side_panels.dart';
import '../widgets/today_board_section.dart';

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

/// Manager / Staff Daily Logs — mirrors web `/dashboard/daily-logs`
/// (Today / Review / Activities + resident day).
class DailyLogsPage extends StatefulWidget {
  final DailyLogFilePicker? pickFiles;

  /// When false, omit the bottom nav (e.g. embedded in [StaffShell]).
  final bool showBottomNav;

  /// Staff portal chrome (search + back → Staff home). Managers use HR chrome.
  final bool staffPortal;

  const DailyLogsPage({
    super.key,
    this.pickFiles,
    this.showBottomNav = true,
    this.staffPortal = false,
  });

  static const int _moreTabIndex = 4;
  static const int _staffDailyLogsTab = 2;

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
    if (widget.staffPortal) return null;
    final destination =
        managerDestinations().firstWhereOrNull((d) => d.title == title);
    return destination?.open;
  }

  VoidCallback? _openModule(String title) => widget.staffPortal
      ? null
      : managerDestinations().firstWhereOrNull((d) => d.title == title)?.open;

  Future<(DailyActivityController, bool owned)> _activityController(
    String tag,
  ) async {
    final alreadyRegistered = Get.isRegistered<DailyActivityController>() ||
        Get.isRegistered<DailyActivityController>(tag: tag);
    final DailyActivityController controller;
    var owned = false;
    if (Get.isRegistered<DailyActivityController>(tag: tag)) {
      controller = Get.find<DailyActivityController>(tag: tag);
    } else if (Get.isRegistered<DailyActivityController>()) {
      controller = Get.find<DailyActivityController>();
    } else {
      controller = Get.put(GetIt.instance<DailyActivityController>(), tag: tag);
      owned = true;
    }
    if (alreadyRegistered) owned = false;
    final residenceId =
        _c.residenceId.value.isEmpty ? null : _c.residenceId.value;
    await controller.loadOptions(residenceId: residenceId);
    return (controller, owned);
  }

  Future<void> _refreshActivitiesRegistry() async {
    const tag = 'dl-activities-registry';
    if (Get.isRegistered<DailyActivityController>(tag: tag)) {
      await Get.find<DailyActivityController>(tag: tag).load();
    }
  }

  Future<void> _recordActivity() async {
    const tag = 'dl-record-activity';
    final (controller, owned) = await _activityController(tag);
    if (!mounted) return;
    await showDailyActivityFormSheet(context, controller: controller);
    if (owned && Get.isRegistered<DailyActivityController>(tag: tag)) {
      Get.delete<DailyActivityController>(tag: tag);
    }
    await _refreshActivitiesRegistry();
  }

  Future<void> _groupActivity() async {
    const tag = 'dl-group-activity';
    final (controller, owned) = await _activityController(tag);
    if (!mounted) return;
    await showDailyActivityGroupSheet(context, controller: controller);
    if (owned && Get.isRegistered<DailyActivityController>(tag: tag)) {
      Get.delete<DailyActivityController>(tag: tag);
    }
    await _refreshActivitiesRegistry();
  }

  void _addCareNote() {
    if (!_c.canOpenCareNote) {
      AppSnackbar.show(
        'Choose residence and resident',
        'Pick a home and resident before adding a care note.',
        force: true,
      );
      return;
    }
    showNewLogEntrySheet(
      context,
      controller: _c,
      pickFiles: widget.pickFiles,
    );
  }

  void _openHandovers() {
    if (widget.staffPortal ||
        (Get.isRegistered<UserSession>() &&
            Get.find<UserSession>().role == UserRole.staff)) {
      Get.to(() => const StaffShiftHandoversPage());
      return;
    }
    Get.to(() => const HandoversPage());
  }

  void _onBack() {
    if (widget.staffPortal) {
      Get.offAll(() => const StaffShell(initialIndex: 0));
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _onSearch() {
    if (widget.staffPortal) {
      StaffSearchPage.open();
      return;
    }
    openManagerPortalSearch();
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: AppRefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshAll,
              child: Obx(() {
                // Subscribe to the hub observables this page composes.
                final _ = (
                  _c.tab.value,
                  _c.residenceId.value,
                  _c.clientId.value,
                  _c.logDate.value,
                  _c.board.value,
                  _c.boardLoading.value,
                  _c.flagsTotal.value,
                  _c.review.value,
                  _c.missing.value,
                  _c.activity.value,
                  _c.activityLoading.value,
                  _c.staffId.value,
                  _c.flags.toList(),
                  _c.shiftLogs.toList(),
                );
                return ListView(
                  key: const ValueKey('dl-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: _content(context),
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? (widget.staffPortal
              ? StaffBottomNavBar(
                  currentIndex: DailyLogsPage._staffDailyLogsTab,
                  onTap: (index) =>
                      Get.offAll(() => StaffShell(initialIndex: index)),
                )
              : HrBottomNavBar(
                  currentIndex: DailyLogsPage._moreTabIndex,
                  onTap: (index) => Get.offAll(() => HrShell(initialIndex: index)),
                  alertsBadgeCount: hrAlertsBadgeCount(),
                ))
          : null,
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
                onPressed: _onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHeading),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Logs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(context, 18, weight: FontWeight.w700),
                    ),
                    Text(
                      'What each resident needs today, and the notes written about them.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _onSearch,
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
                  child: const AppSvgIcon(
                    AppAssets.search,
                    size: 18,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    if (_c.viewingResidentDay) {
      return [
        ResidentDaySection(
          controller: _c,
          onBack: _c.backToToday,
          onWriteNote: _addCareNote,
          onRecordIncident: _openModule('Incidents'),
          onRecordDose: _openModule('Medication'),
          onRecordCheck: _openModule('Recurring Checks'),
          onRecordTask: _openModule('Tasks & Compliance'),
          onOpenEntry: (e) =>
              showEntryDetailSheet(context, controller: _c, entryId: e.id),
          onAmend: (e) =>
              showAmendEntrySheet(context, controller: _c, entry: e),
          onDelete: (e) =>
              confirmDeleteEntry(context, controller: _c, entry: e),
        ),
      ];
    }

    return [
      if (!_c.viewingResidentDay) DailyLogsTabs(controller: _c),
      const SizedBox(height: 12),
      DailyLogsFilters(controller: _c),
      const SizedBox(height: 14),
      ..._main(context),
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

  List<Widget> _main(BuildContext context) {
    switch (_c.tab.value) {
      case DailyLogsTab.today:
        return [
          TodayBoardSection(
            controller: _c,
            onWriteNote: _addCareNote,
            onOpenHandover: _openHandovers,
            onOpenResident: (r) => _c.openDay(
              r.clientId,
              _c.logDate.value,
              name: r.name,
            ),
          ),
        ];
      case DailyLogsTab.review:
        final reviewRows = _c.review.value?.items ?? const [];
        final notHanded = _c.board.value?.notHandedOver ?? const [];
        final careRows = _c.activity.value?.items ?? const [];
        // Web Review: Open flags + Carer activity first; sign-off / handover
        // panels follow for managers with `daily-logs:review`.
        return [
          if (_c.canReadFlags) ...[
            PriorityNotesPanel(
              flags: _c.flags.toList(),
              loading: _c.flagsLoading.value,
              error: _c.flagsError.value,
              canResolve: _c.canResolveFlags,
              totalOpen: _c.flagsTotal.value,
              onResolve: (f) =>
                  showResolveFlagSheet(context, controller: _c, flag: f),
            ),
            const SizedBox(height: 12),
          ],
          CareGivenPanel(
            rows: careRows,
            loading: _c.activityLoading.value,
            staffFilterLabel: _c.staffName,
            onFilterStaff: () async {
              final picked = await pickDailyLogOption(
                context,
                'Carer',
                [
                  ('', 'Everyone'),
                  for (final person in _c.staff) (person.id, person.label),
                ],
                _c.staffId.value,
              );
              if (picked != null) _c.setStaff(picked);
            },
            openFor: _openFor,
          ),
          const SizedBox(height: 14),
          Text(
            'Waiting for sign-off',
            style: handoverText(context, 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Finished shifts from the last 7 days. Signing off locks the notes.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ReviewQueueList(
            rows: reviewRows,
            loading: _c.reviewLoading.value,
            error: _c.reviewError.value,
            onOpen: (r) => _c.openDay(
              r.clientId,
              r.logDate,
              name: r.clientName,
              residence: r.residenceId,
            ),
            onSignOff: _c.canReview
                ? (r) async {
                    final id = r.shiftLogId;
                    if (id == null || id.isEmpty) return;
                    final row = _c.shiftLogs.firstWhereOrNull((s) => s.id == id);
                    if (row != null) {
                      await _c.updateShiftLog(
                        row,
                        const {'status': 'locked'},
                        'Signed off',
                      );
                      return;
                    }
                    await _c.updateShiftLog(
                      DailyLogShiftRow(
                        id: id,
                        status: 'completed',
                        clientName: r.clientName,
                        shiftTitle: r.shiftLabel,
                        summary: r.summary,
                      ),
                      const {'status': 'locked'},
                      'Signed off',
                    );
                  }
                : null,
          ),
          if (reviewRows.isNotEmpty) _pagination(),
          const SizedBox(height: 14),
          NotHandedOverPanel(
            notes: notHanded,
            onOpenDay: (n) => _c.openDay(
              n.clientId,
              _c.logDate.value,
              name: n.clientName,
            ),
          ),
          if (_c.hasResidence) ...[
            const SizedBox(height: 14),
            ShiftDocumentationPanel(
              rows: _c.shiftLogs.toList(),
              loading: _c.shiftLogsLoading.value,
              canWrite: _c.canWrite,
              canReview: _c.canReview,
              busyId: _c.busyShiftId.value,
              onUpdate: _c.updateShiftLog,
            ),
          ],
        ];
      case DailyLogsTab.activities:
        return [
          DailyLogsActivitiesSection(
            controller: _c,
            openFor: _openFor,
            onRecordActivity: _c.canRecordActivity ? _recordActivity : null,
            onGroupActivity: _c.canRecordActivity ? _groupActivity : null,
          ),
        ];
    }
  }
}
