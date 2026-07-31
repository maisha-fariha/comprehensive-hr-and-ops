import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../controllers/tasks_messages_controller.dart';
import '../widgets/messages_tab_view.dart';
import '../widgets/tasks_messages_header.dart';
import '../widgets/tasks_messages_segmented_tabs.dart';
import '../widgets/tasks_tab_view.dart';
import 'message_thread_page.dart';

/// The Staff "Tasks & Messages" screen.
///
/// Reproduces both Figma frames in the "Tasks & Messages" group ("Tasks",
/// "Messages") as a single page: both frames share the exact same header
/// and segmented tab bar, and only the body content underneath swaps per
/// tab, mirroring the pattern used by the HR "Team & Reports" and "Tasks &
/// Compliance" screens.
class StaffTasksMessagesPage extends StatelessWidget {
  const StaffTasksMessagesPage({super.key});

  TasksMessagesController _resolveController() {
    try {
      return Get.find<TasksMessagesController>();
    } catch (_) {
      return Get.put(GetIt.instance<TasksMessagesController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final response = controller.state.value;
          final overview = response.data;

          if (overview == null && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (overview == null) {
            return _TasksMessagesError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading Tasks & Messages.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          final selectedTab = controller.selectedTab.value;

          return Column(
            children: [
              const TasksMessagesHeader(title: 'Tasks & Messages'),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: AppDimens.screenPaddingHorizontal,
                ),
                child: TasksMessagesSegmentedTabs(
                  selectedTab: selectedTab,
                  tasksCount: overview.tasks.length,
                  messagesCount: overview.conversations.length,
                  onTabSelected: controller.selectTab,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                      ResponsiveHelper.getResponsiveHeight(context, 16),
                      ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                      ResponsiveHelper.getResponsiveHeight(context, 24),
                    ),
                    children: [
                      switch (selectedTab) {
                        TasksMessagesTab.tasks => TasksTabView(
                            tasks: controller.filteredTasks,
                            selectedFilter: controller.selectedFilter.value,
                            countFor: controller.countFor,
                            onFilterSelected: controller.selectFilter,
                          ),
                        TasksMessagesTab.messages => MessagesTabView(
                            conversations: overview.conversations,
                            onConversationTap: (conversation) {
                              Get.to(() => MessageThreadPage(conversationId: conversation.id));
                            },
                          ),
                      },
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
