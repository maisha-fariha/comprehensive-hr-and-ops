import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../hr_shell.dart';
import '../../../presentation/open_manager_portal_search.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import '../controllers/tasks_compliance_controller.dart';
import '../widgets/compliance_tab_view.dart';
import '../widgets/corrective_tab_view.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/tasks_compliance_header.dart';
import '../widgets/tasks_compliance_tab_bar.dart';
import '../widgets/tasks_tab_view.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';

/// The "Tasks & Compliance" screen — shared white header + pill tab bar,
/// with Tasks / Compliance / Corrective body content.
///
/// Hosts [HrBottomNavBar] with "More" selected so the pushed route still
/// matches the reference frames that show the manager bottom nav.
class TasksCompliancePage extends StatelessWidget {
  const TasksCompliancePage({super.key});

  /// Index of the "More" slot in [HrBottomNavBar.items].
  static const int _moreTabIndex = 4;

  TasksComplianceController _resolveController() {
    try {
      return Get.find<TasksComplianceController>();
    } catch (_) {
      return Get.put(GetIt.instance<TasksComplianceController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => HrShell(initialIndex: index));
  }

  TasksComplianceRepository get _repository =>
      GetIt.instance<TasksComplianceRepository>();

  Future<void> _approveReview(
    TasksComplianceController controller,
    TaskItem task,
  ) async {
    final result = await _repository.reviewTask(
      taskId: task.id,
      decision: 'approve',
    );
    result.when(
      success: (_) async {
        AppSnackbar.show('Review approved', '“${task.title}” was approved.');
        await controller.refresh();
      },
      failure: (error) {
        AppSnackbar.show('Could not approve', error.message);
      },
    );
  }

  Future<void> _rejectReview(
    TasksComplianceController controller,
    TaskItem task,
  ) async {
    final result = await _repository.reviewTask(
      taskId: task.id,
      decision: 'reject',
      reviewNotes: 'Needs more work before approval.',
    );
    result.when(
      success: (_) async {
        AppSnackbar.show('Review rejected', '“${task.title}” was sent back.');
        await controller.refresh();
      },
      failure: (error) {
        AppSnackbar.show('Could not reject', error.message);
      },
    );
  }

  Future<void> _pauseRecurring(
    TasksComplianceController controller,
    TaskItem task,
  ) async {
    final result = await _repository.pauseRecurring(task.id);
    result.when(
      success: (_) async {
        AppSnackbar.show('Paused', '“${task.title}” was paused.');
        await controller.refresh();
      },
      failure: (error) {
        AppSnackbar.show('Could not pause', error.message);
      },
    );
  }

  Future<void> _resumeRecurring(
    TasksComplianceController controller,
    TaskItem task,
  ) async {
    final result = await _repository.resumeRecurring(task.id);
    result.when(
      success: (_) async {
        AppSnackbar.show('Resumed', '“${task.title}” was resumed.');
        await controller.refresh();
      },
      failure: (error) {
        AppSnackbar.show('Could not resume', error.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: Obx(
        () => HrBottomNavBar(
          currentIndex: _moreTabIndex,
          onTap: _onBottomNavTap,
          alertsBadgeCount: hrAlertsBadgeCount(),
        ),
      ),
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null) {
          return _TasksComplianceError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading Tasks & Compliance.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: Column(
                children: [
                  TasksComplianceHeader(
                    subtitle: overview.headerSubtitle,
                    onSearchTap: openManagerPortalSearch,
                  ),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 4,
                      bottom: 12,
                    ),
                    child: TasksComplianceTabBar(
                      selectedTab: controller.selectedTab.value,
                      onTabSelected: controller.selectTab,
                      complianceAlertCount: overview.complianceAlertCount,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  children: [
                    switch (controller.selectedTab.value) {
                      TasksComplianceTab.tasks => TasksTabView(
                          overview: overview,
                          onNewTaskTap: () => showCreateTaskSheet(
                            context,
                            onCreated: controller.refresh,
                          ),
                          onTaskTap: (task) => showTaskDetailSheet(
                            context,
                            task: task,
                          ),
                          onApproveReview: (task) =>
                              _approveReview(controller, task),
                          onRejectReview: (task) =>
                              _rejectReview(controller, task),
                          onPauseRecurring: (task) =>
                              _pauseRecurring(controller, task),
                          onResumeRecurring: (task) =>
                              _resumeRecurring(controller, task),
                        ),
                      TasksComplianceTab.compliance =>
                        ComplianceTabView(overview: overview),
                      TasksComplianceTab.corrective =>
                        CorrectiveTabView(overview: overview),
                    },
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TasksComplianceError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _TasksComplianceError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.criticalRed, size: 40),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryTeal),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
