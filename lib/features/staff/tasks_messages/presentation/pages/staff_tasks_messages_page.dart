import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/offline/outbox_feature.dart';
import '../../../../../core/offline/presentation/pending_outbox_section.dart';
import '../../../../hr/recurring_checks/domain/entities/recurring_check.dart';
import '../../../../hr/recurring_checks/presentation/controllers/recurring_checks_controller.dart';
import '../../../../hr/recurring_checks/presentation/widgets/record_check_sheet.dart';
import '../../../../hr/recurring_checks/presentation/widgets/skip_check_sheet.dart';
import '../../domain/entities/recurring_check_instance.dart';
import '../controllers/tasks_messages_controller.dart';
import '../widgets/tasks_messages_header.dart';
import '../widgets/tasks_tab_view.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// Staff Tasks screen (web Tasks module — messages live under Communication).
class StaffTasksMessagesPage extends StatelessWidget {
  const StaffTasksMessagesPage({super.key});

  TasksMessagesController _resolveController() {
    try {
      return Get.find<TasksMessagesController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<TasksMessagesController>(),
        permanent: true,
      );
    }
  }

  /// Same Record / Skip sheets as web Recurring Checks Due (not a bare PATCH).
  CheckInstance _asCheckInstance(RecurringCheckInstance check) {
    return CheckInstance(
      id: check.id,
      scheduleId: check.scheduleId,
      clientId: check.clientId,
      residenceId: check.residenceId,
      dueAt: check.dueAt ?? DateTime.now(),
      status: check.statusRaw.isEmpty ? 'pending' : check.statusRaw,
      statusNote: check.statusNote.isEmpty ? null : check.statusNote,
      assignedRole: check.assignedRole.isEmpty ? null : check.assignedRole,
      assignedStaffName:
          check.assignedStaffName.isEmpty ? null : check.assignedStaffName,
      checkName: check.title,
      clientName: check.clientName.isEmpty ? null : check.clientName,
      roomNumber: check.roomLabel.isEmpty ? null : check.roomLabel,
    );
  }

  Future<void> _recordRecurringCheck(
    BuildContext context,
    TasksMessagesController tasks,
    RecurringCheckInstance check,
  ) async {
    final recurring = GetIt.instance<RecurringChecksController>();
    await showRecordCheckSheet(
      context,
      controller: recurring,
      instance: _asCheckInstance(check),
    );
    await tasks.refresh();
  }

  Future<void> _skipRecurringCheck(
    BuildContext context,
    TasksMessagesController tasks,
    RecurringCheckInstance check,
  ) async {
    final recurring = GetIt.instance<RecurringChecksController>();
    await showSkipCheckSheet(
      context,
      controller: recurring,
      instance: _asCheckInstance(check),
    );
    await tasks.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          final response = controller.state.value;
          final overview = response.data;

          if (overview == null && controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }

          if (overview == null) {
            return _TasksMessagesError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading Tasks.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          final session = Get.isRegistered<UserSession>()
              ? Get.find<UserSession>()
              : null;
          // Web shows New Task only with tasks:manage. tasks:write is for
          // working an assigned task, which caregivers have.
          final canCreateTasks =
              session == null || session.can('tasks:manage');
          final canCompleteChecks = session == null ||
              session.can('recurring-checks:complete') ||
              session.can('recurring-checks:write');

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: TasksMessagesHeader(
                  title: 'Tasks',
                  onNewTaskTap:
                      canCreateTasks ? controller.showCreateTaskDialog : null,
                ),
              ),
              PendingOutboxSection(
                features: const {
                  OutboxFeature.tasks,
                  OutboxFeature.recurringChecks,
                },
                onSynced: () => controller.refresh(),
              ),
              Expanded(
                child: AppRefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      ResponsiveHelper.getResponsiveHeight(context, 16),
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      ResponsiveHelper.getResponsiveHeight(context, 24),
                    ),
                    children: [
                      TasksTabView(
                        tasks: controller.filteredTasks,
                        recurringChecks: controller.recurringChecks,
                        selectedFilter: controller.selectedFilter.value,
                        countFor: controller.countFor,
                        onFilterSelected: controller.selectFilter,
                        onTaskTap: controller.openTask,
                        onRecurringTap: canCompleteChecks
                            ? (check) => _recordRecurringCheck(
                                  context,
                                  controller,
                                  check,
                                )
                            : null,
                        onRecurringSkip: canCompleteChecks
                            ? (check) => _skipRecurringCheck(
                                  context,
                                  controller,
                                  check,
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TasksMessagesError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _TasksMessagesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: 40,
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
