import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../daily_activity/domain/entities/daily_activity.dart';
import '../../../daily_activity/domain/repositories/daily_activity_repository.dart';
import '../../../daily_activity/presentation/controllers/daily_activity_controller.dart';
import '../../../daily_activity/presentation/widgets/daily_activity_detail_sheet.dart';
import '../../../daily_activity/presentation/widgets/daily_activity_filters.dart';
import '../../../daily_activity/presentation/widgets/daily_activity_form_sheet.dart';
import '../../../daily_activity/presentation/widgets/daily_activity_kpi_grid.dart';
import '../../../daily_activity/presentation/widgets/daily_activity_registry.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_log.dart';
import '../controllers/daily_logs_controller.dart';
import 'daily_logs_lists.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Web Daily Logs → Activities: Client Activity Registry scoped to the board
/// home + day (`from`/`to` = selected date), matching
/// `eP({ residenceId, from, to, hideDuplicateFilters: true })`.
class DailyLogsActivitiesSection extends StatefulWidget {
  final DailyLogsController controller;
  final VoidCallback? onRecordActivity;
  final VoidCallback? onGroupActivity;
  final VoidCallback? Function(String? entityType, String? entityId) openFor;
  final DailyActivityFilePicker? pickFile;

  const DailyLogsActivitiesSection({
    super.key,
    required this.controller,
    required this.openFor,
    this.onRecordActivity,
    this.onGroupActivity,
    this.pickFile,
  });

  @override
  State<DailyLogsActivitiesSection> createState() =>
      _DailyLogsActivitiesSectionState();
}

class _DailyLogsActivitiesSectionState
    extends State<DailyLogsActivitiesSection> {
  static const _tag = 'dl-activities-registry';
  DailyActivityController? _activity;
  bool _owned = false;
  final _search = TextEditingController();
  Worker? _dateWorker;
  Worker? _homeWorker;

  DailyLogsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _ensureActivityController();
    _dateWorker = ever<String>(_c.logDate, (_) => _reloadBoard());
    _homeWorker = ever<String>(_c.residenceId, (_) => _reloadBoard());
  }

  @override
  void dispose() {
    _dateWorker?.dispose();
    _homeWorker?.dispose();
    _search.dispose();
    if (_owned && Get.isRegistered<DailyActivityController>(tag: _tag)) {
      Get.delete<DailyActivityController>(tag: _tag);
    }
    super.dispose();
  }

  void _ensureActivityController() {
    if (!GetIt.I.isRegistered<DailyActivityRepository>()) return;
    if (Get.isRegistered<DailyActivityController>(tag: _tag)) {
      _activity = Get.find<DailyActivityController>(tag: _tag);
      _owned = false;
    } else {
      // loadOnInit: false — otherwise onInit races an unscoped list and paints
      // historical rows / mismatched KPI tiles (web scopes to board day).
      _activity = Get.put(
        DailyActivityController(
          repository: GetIt.instance<DailyActivityRepository>(),
          session: Get.find<UserSession>(),
          loadOnInit: false,
        ),
        tag: _tag,
      );
      _owned = true;
    }
    _reloadBoard();
  }

  void _reloadBoard() {
    final activity = _activity;
    if (activity == null) return;
    final residence =
        _c.residenceId.value.isEmpty ? null : _c.residenceId.value;
    activity.bindBoard(residenceId: residence, day: _c.logDate.value);
    activity.loadOptions(residenceId: residence);
    activity.load();
  }

  Future<void> _confirmDelete(DailyActivity item) async {
    final activity = _activity;
    if (activity == null) return;
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Delete this activity record?',
          style: handoverText(dialogContext, 17, weight: FontWeight.w700),
        ),
        content: Text(
          'It leaves the registry. What was written is kept rather than destroyed.',
          style: handoverText(
            dialogContext,
            13.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          HandoverButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          HandoverButton(
            label: 'Delete',
            filled: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await activity.delete(item);
      await activity.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    if (activity == null || !_c.canReadActivities) {
      return Obx(() {
        final rows = _c.activity.value?.items ?? const <ResidenceActivityRow>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_c.canRecordActivity) _actionButtons(),
            const SizedBox(height: 12),
            HouseActivityList(
              rows: rows,
              loading: _c.activityLoading.value,
              openFor: widget.openFor,
            ),
          ],
        );
      });
    }

    return Obx(() {
      final _ = (
        activity.items.toList(),
        activity.stats.value,
        activity.loading.value,
        activity.page.value,
        activity.limit.value,
        activity.total.value,
        _c.logDate.value,
        _c.residenceId.value,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_c.canRecordActivity) _actionButtons(),
          const SizedBox(height: 12),
          DailyActivityKpiGrid(stats: activity.stats.value),
          const SizedBox(height: 12),
          DailyActivityFilters(
            controller: activity,
            searchController: _search,
            hideDuplicateFilters: true,
          ),
          const SizedBox(height: 14),
          DailyActivityRegistry(
            pendingReview: activity.stats.value.pendingReview,
            items: activity.items.toList(),
            loading: activity.loading.value,
            onView: (item) => showDailyActivityDetailSheet(
              context,
              controller: activity,
              activity: item,
              onEdit: (editing) => showDailyActivityFormSheet(
                context,
                controller: activity,
                editing: editing,
                pickFile: widget.pickFile,
              ),
            ),
            onEdit: activity.canWrite
                ? (item) => showDailyActivityFormSheet(
                      context,
                      controller: activity,
                      editing: item,
                      pickFile: widget.pickFile,
                    )
                : null,
            onDelete: activity.canWrite ? _confirmDelete : null,
            footer: activity.total.value == 0
                ? null
                : AttendancePagination(
                    page: activity.page.value,
                    limit: activity.limit.value,
                    total: activity.total.value,
                    totalPages: activity.totalPages.value,
                    limitOptions: DailyActivityController.pageSizes,
                    onPage: (p) {
                      activity.page.value = p;
                      activity.load();
                    },
                    onLimit: (l) {
                      activity.limit.value = l;
                      activity.page.value = 1;
                      activity.load();
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _actionButtons() {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          HandoverButton(
            key: const ValueKey('dl-group-activity'),
            label: 'Group activity',
            icon: Icons.groups_rounded,
            compact: true,
            onPressed: widget.onGroupActivity,
          ),
          HandoverButton(
            key: const ValueKey('dl-record-activity'),
            label: 'Record activity',
            icon: Icons.add_rounded,
            filled: true,
            compact: true,
            onPressed: widget.onRecordActivity,
          ),
        ],
      ),
    );
  }
}
