import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_activity.dart';
import '../controllers/daily_activity_controller.dart';
import '../widgets/daily_activity_common.dart';
import '../widgets/daily_activity_detail_sheet.dart';
import '../widgets/daily_activity_filters.dart';
import '../widgets/daily_activity_form_sheet.dart';
import '../widgets/daily_activity_history_tab.dart';
import '../widgets/daily_activity_kpi_grid.dart';
import '../widgets/daily_activity_registry.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Manager "Daily Activity" — mirrors web `/dashboard/daily-activity`.
class DailyActivityPage extends StatefulWidget {
  final DailyActivityFilePicker? pickFile;

  const DailyActivityPage({super.key, this.pickFile});

  @override
  State<DailyActivityPage> createState() => _DailyActivityPageState();
}

class _DailyActivityPageState extends State<DailyActivityPage> {
  late final DailyActivityController _c;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<DailyActivityController>());
    _search.text = _c.search.value;
  }

  @override
  void dispose() {
    _search.dispose();
    Get.delete<DailyActivityController>();
    super.dispose();
  }

  void _openForm([DailyActivity? editing]) => showDailyActivityFormSheet(
        context,
        controller: _c,
        editing: editing,
        pickFile: widget.pickFile,
      );

  void _view(DailyActivity activity) => showDailyActivityDetailSheet(
        context,
        controller: _c,
        activity: activity,
        onEdit: _openForm,
      );

  Future<void> _confirmDelete(DailyActivity activity) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Delete this activity record?',
          style: handoverText(dialogContext, 17, weight: FontWeight.w700),
        ),
        content: Text(
          'It leaves the registry. What was written is kept rather than destroyed, '
          'so it can be restored.',
          style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          HandoverButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          DailyActivityDangerButton(
            key: const ValueKey('daily-activity-delete-confirm'),
            label: 'Delete',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) await _c.delete(activity);
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
                        'Daily Activity',
                        style: handoverText(context, 18, weight: FontWeight.w700),
                      ),
                    ),
                    if (_c.canWrite)
                      HandoverButton(
                        key: const ValueKey('daily-activity-record'),
                        label: 'Record activity',
                        icon: Icons.add_rounded,
                        filled: true,
                        compact: true,
                        onPressed: _openForm,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshAll,
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    DailyActivityKpiGrid(stats: _c.stats.value),
                    const SizedBox(height: 15),
                    _tabs(context),
                    const SizedBox(height: 15),
                    if (_c.tab.value == DailyActivityTab.registry) ..._registry(context)
                    else
                      DailyActivityHistoryTab(
                        controller: _c,
                        onView: _view,
                        onEdit: _c.canWrite ? _openForm : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    Widget tab(DailyActivityTab value, String label) {
      final selected = _c.tab.value == value;
      return InkWell(
        key: ValueKey('daily-activity-tab-${value.name}'),
        onTap: () => _c.selectTab(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.secondaryTeal : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: handoverText(
              context,
              13.5,
              weight: FontWeight.w500,
              color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          tab(DailyActivityTab.registry, 'Activity registry'),
          tab(DailyActivityTab.history, 'Resident history'),
        ],
      ),
    );
  }

  List<Widget> _registry(BuildContext context) {
    final failed = _c.loadError.value != null;
    return [
      DailyActivityFilters(controller: _c, searchController: _search),
      const SizedBox(height: 15),
      DailyActivityRegistry(
        pendingReview: _c.stats.value.pendingReview,
        items: _c.items.toList(),
        loading: _c.loading.value,
        emptyTitle: failed ? 'Activities could not be loaded' : 'Nothing recorded',
        emptyMessage: failed
            ? _c.loadError.value!
            : 'Outings, programmes and observations appear here.',
        onView: _view,
        onEdit: _c.canWrite ? _openForm : null,
        onDelete: _c.canWrite ? _confirmDelete : null,
        footer: _c.total.value == 0
            ? null
            : AttendancePagination(
                page: _c.page.value,
                limit: _c.limit.value,
                total: _c.total.value,
                totalPages: _c.totalPages.value,
                limitOptions: DailyActivityController.pageSizes,
                onPage: _c.setPage,
                onLimit: _c.setLimit,
              ),
      ),
    ];
  }
}
