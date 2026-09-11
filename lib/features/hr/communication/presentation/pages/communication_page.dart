import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_message_contact.dart';
import '../controllers/communication_controller.dart';
import '../widgets/chat_panel.dart';
import '../widgets/communication_header.dart';
import '../widgets/conversations_panel.dart';
import '../widgets/new_conversation_dialog.dart';

/// HR Communication screen — Messages / Communication Log.
class CommunicationPage extends StatefulWidget {
  final String? initialConversationId;

  const CommunicationPage({super.key, this.initialConversationId});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  var _didSeedConversation = false;

  CommunicationController _resolve() {
    if (Get.isRegistered<CommunicationController>()) {
      return Get.find<CommunicationController>();
    }
    return Get.put(
      GetIt.instance<CommunicationController>(),
      permanent: true,
    );
  }

  Future<void> _openNewConversation(
    BuildContext context,
    CommunicationController controller,
  ) async {
    if (controller.contacts.isEmpty && !controller.isLoadingContacts.value) {
      await controller.loadContacts();
    }
    if (!context.mounted) return;

    final result = await showNewConversationDialog(
      context,
      contacts: List<HrMessageContact>.from(controller.contacts),
    );
    if (result == null) return;

    await controller.startConversation(
      title: result.title,
      memberUserIds: result.memberUserIds,
      firstMessage: result.firstMessage,
    );
  }

  Future<void> _seedIfNeeded(CommunicationController controller) async {
    if (_didSeedConversation) return;
    final seedId = widget.initialConversationId?.trim();
    if (seedId == null || seedId.isEmpty) return;
    _didSeedConversation = true;
    if (controller.conversations.isEmpty) {
      await controller.loadConversations();
    }
    await controller.selectConversation(seedId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolve();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedIfNeeded(controller);
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            CommunicationHeader(
              onBack: () => Navigator.of(context).pop(),
              onNewConversation: () =>
                  _openNewConversation(context, controller),
            ),
            Expanded(
              child: Obx(() {
                if (controller.selectedTab.value ==
                    CommunicationTab.communicationLog) {
                  return const _CommunicationLogPlaceholder();
                }

                if (controller.isLoading.value &&
                    controller.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty &&
                    controller.conversations.isEmpty) {
                  return _ErrorState(
                    message: controller.errorMessage.value,
                    onRetry: controller.loadConversations,
                  );
                }

                final wide = MediaQuery.sizeOf(context).width >= 900;
                final conversations = ConversationsPanel(
                  conversations: controller.filteredConversations,
                  selectedId: controller.selectedConversationId.value,
                  activeCount: controller.activeCount,
                  unreadCount: controller.unreadCount,
                  selectedFilter: controller.selectedFilter.value,
                  searchController: controller.searchController,
                  onSearchChanged: controller.onSearchChanged,
                  onFilterSelected: controller.selectFilter,
                  onConversationTap: controller.selectConversation,
                  onComposeTap: () =>
                      _openNewConversation(context, controller),
                  onMarkAllRead:
                      controller.unreadCount > 0 ? controller.markAllRead : null,
                );
                final chat = ChatPanel(
                  conversation: controller.selectedConversation,
                  messages: controller.activeMessages.toList(),
                  messageController: controller.messageController,
                  onSend: controller.sendMessage,
                  isLoading: controller.isLoadingMessages.value,
                  isSending: controller.isSending.value,
                );

                if (wide) {
                  return Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 20,
                      top: 8,
                      bottom: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(
                            context,
                            340,
                          ),
                          child: conversations,
                        ),
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(
                            context,
                            16,
                          ),
                        ),
                        Expanded(child: chat),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshConversations,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 8,
                      bottom: 20,
                    ),
                    children: [
                      conversations,
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 16),
                      ),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.58,
                        child: chat,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CommunicationLogPlaceholder extends StatelessWidget {
  const _CommunicationLogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_edu_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 40),
              color: AppColors.textMuted,
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              'Communication Log',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Text(
              'Audit entries for monitored conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
