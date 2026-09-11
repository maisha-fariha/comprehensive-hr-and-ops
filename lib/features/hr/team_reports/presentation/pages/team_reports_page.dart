import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../../communication/domain/entities/hr_message_contact.dart';
import '../../../communication/domain/repositories/communication_repository.dart';
import '../../../communication/presentation/pages/communication_page.dart';
import '../../../communication/presentation/widgets/new_conversation_dialog.dart';
import '../../../hr_shell.dart';
import '../../../presentation/open_manager_portal_search.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../domain/entities/available_report_item.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/report_export_item.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../domain/repositories/team_reports_repository.dart';
import '../controllers/team_reports_controller.dart';
import '../widgets/messages_tab_view.dart';
import '../widgets/reports_tab_view.dart';
import '../widgets/team_reports_error_view.dart';
import '../widgets/team_reports_header.dart';
import '../widgets/team_reports_segmented_tabs.dart';
import '../widgets/team_staff_profile_sheet.dart';
import '../widgets/team_tab_view.dart';

/// "Team & Reports" screen — shared white header + pill tabs, with Team /
/// Reports / Messages body content.
///
/// Hosts [HrBottomNavBar] with "More" selected so the pushed route still
/// matches the reference frames that show the manager bottom nav.
class TeamReportsPage extends StatelessWidget {
  const TeamReportsPage({super.key});

  /// Index of the "More" slot in [HrBottomNavBar.items].
  static const int _moreTabIndex = 4;

  TeamReportsController _resolveController() {
    try {
      return Get.find<TeamReportsController>();
    } catch (_) {
      return Get.put(GetIt.instance<TeamReportsController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => HrShell(initialIndex: index));
  }

  TeamReportsRepository get _repository =>
      GetIt.instance<TeamReportsRepository>();

  CommunicationRepository get _messaging =>
      GetIt.instance<CommunicationRepository>();

  Future<void> _createExport(
    TeamReportsController controller,
    AvailableReportItem report,
  ) async {
    final result = await _repository.createExport(reportKey: report.id);
    result.when(
      success: (_) async {
        AppSnackbar.show(
          'Export queued',
          '“${report.title}” export was created.',
        );
        await controller.refresh();
      },
      failure: (error) {
        AppSnackbar.show(
          'Could not create export',
          _exportCreateErrorMessage(error),
        );
      },
    );
  }

  static String _exportCreateErrorMessage(AppError error) {
    final message = error.message.trim();
    final isForbidden = error is PermissionError ||
        error.code == '403' ||
        message.toLowerCase().contains('missing permission') ||
        message.toLowerCase().contains('forbidden');
    if (isForbidden) {
      return 'Your account can view reports but cannot create exports '
          '(needs reports:write). Ask an admin to grant that permission.';
    }
    if (message.isEmpty || message == 'Please try again in a moment.') {
      return 'Export could not be created. If this keeps happening, your '
          'role may be missing reports:write.';
    }
    return message;
  }

  Future<void> _downloadExport(ReportExportItem export) async {
    final result = await _repository.downloadExportFile(export.id);
    await result.when(
      success: (bytes) async {
        final safeKey = export.reportKey.replaceAll(RegExp(r'[^\w\-]+'), '_');
        final shortId = export.id.length > 8
            ? export.id.substring(0, 8)
            : export.id;
        final ext = export.format.trim().isEmpty ? 'csv' : export.format.trim();
        final fileName = '$safeKey-$shortId.$ext';
        final mime = ext.toLowerCase() == 'csv'
            ? 'text/csv'
            : 'application/octet-stream';
        final saveResult = await MediaStoreDownload.saveFile(
          fileName: fileName,
          bytes: Uint8List.fromList(bytes),
          mimeType: mime,
        );
        if (saveResult.success) {
          AppSnackbar.show(
            'Export downloaded',
            'Saved to ${saveResult.displayLocation}',
          );
        } else {
          AppSnackbar.show(
            'Could not download',
            saveResult.error ?? 'Could not save the export file.',
          );
        }
      },
      failure: (error) async {
        AppSnackbar.show('Could not download', error.message);
      },
    );
  }

  Future<void> _markAllConversationsRead(
    TeamReportsController controller,
  ) async {
    final result = await _messaging.markAllRead();
    await result.when(
      success: (_) async {
        AppSnackbar.show('Marked as read', 'All conversations are now read.');
        await controller.refresh();
      },
      failure: (error) async {
        AppSnackbar.show('Could not mark all read', error.message);
      },
    );
  }

  Future<void> _composeConversation(
    BuildContext context,
    TeamReportsController controller,
  ) async {
    final contactsResult = await _messaging.getContacts();
    if (!context.mounted) return;

    final contacts = contactsResult.when(
      success: (items) => items,
      failure: (_) => const <HrMessageContact>[],
    );
    if (contactsResult.isFailure) {
      AppSnackbar.show(
        'Could not load contacts',
        contactsResult.error?.message ?? 'Try again in a moment.',
      );
      return;
    }

    final draft = await showNewConversationDialog(
      context,
      contacts: List<HrMessageContact>.from(contacts),
    );
    if (draft == null) return;

    final created = await _messaging.startConversation(
      title: draft.title,
      memberUserIds: draft.memberUserIds,
    );
    await created.when(
      success: (conversation) async {
        final first = draft.firstMessage.trim();
        if (first.isNotEmpty) {
          await _messaging.sendMessage(
            conversationId: conversation.id,
            body: first,
          );
        }
        AppSnackbar.show('Conversation started', conversation.title);
        await controller.refresh();
        await Get.to(
          () => CommunicationPage(initialConversationId: conversation.id),
        );
        await controller.refresh();
      },
      failure: (error) async {
        AppSnackbar.show('Could not start conversation', error.message);
      },
    );
  }

  Future<void> _openConversation(
    TeamReportsController controller,
    ConversationPreview conversation,
  ) async {
    // Mark this thread read, then open the full messaging screen.
    await _messaging.markThreadRead(conversation.id);
    await Get.to(
      () => CommunicationPage(initialConversationId: conversation.id),
    );
    await controller.refresh();
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
        final data = response.data;
        final selectedTab = controller.selectedTab.value;
        final unreadBadgeCount = data == null
            ? 0
            : int.tryParse(
                  data.messages.stats
                      .firstWhere((stat) => stat.tag == MessageStatTag.unread)
                      .value,
                ) ??
                0;

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: Column(
                children: [
                  TeamReportsHeader(
                    selectedTab: selectedTab,
                    onTrailingTap: selectedTab == TeamReportsTab.messages
                        ? () => _composeConversation(context, controller)
                        : openManagerPortalSearch,
                  ),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 4,
                      bottom: 12,
                    ),
                    child: TeamReportsSegmentedTabs(
                      selectedTab: selectedTab,
                      messagesBadgeCount: unreadBadgeCount,
                      onTabSelected: controller.selectTab,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (data == null && controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    );
                  }

                  if (data == null) {
                    return TeamReportsErrorView(
                      message: controller.errorMessage.value.isEmpty
                          ? 'Something went wrong while loading Team & Reports.'
                          : controller.errorMessage.value,
                      onRetry: controller.refresh,
                    );
                  }

                  final Widget tabContent = switch (selectedTab) {
                    TeamReportsTab.team => TeamTabView(
                        overview: data.team,
                        onViewAllStats: () => showTeamStaffListSheet(
                          context,
                          staff: data.team.staffMembers,
                        ),
                        onViewAllReports: () =>
                            controller.selectTab(TeamReportsTab.reports),
                        onViewAllMessages: () =>
                            controller.selectTab(TeamReportsTab.messages),
                        onConversationTap: (conversation) =>
                            _openConversation(controller, conversation),
                      ),
                    TeamReportsTab.reports => ReportsTabView(
                        overview: data.reports,
                        onExportReport: (report) =>
                            _createExport(controller, report),
                        onDownloadExport: _downloadExport,
                      ),
                    TeamReportsTab.messages => MessagesTabView(
                        overview: data.messages,
                        onMarkAllRead: () =>
                            _markAllConversationsRead(controller),
                        onConversationTap: (conversation) =>
                            _openConversation(controller, conversation),
                      ),
                  };

                  return RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.refresh,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        ResponsiveHelper.getResponsiveWidth(context, 16),
                        ResponsiveHelper.getResponsiveHeight(context, 12),
                        ResponsiveHelper.getResponsiveWidth(context, 16),
                        ResponsiveHelper.getResponsiveHeight(context, 28),
                      ),
                      children: [tabContent],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
