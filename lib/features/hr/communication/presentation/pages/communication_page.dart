import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/communication_enums.dart';
import '../controllers/communication_controller.dart';
import '../widgets/chat_panel.dart';
import '../widgets/communication_header.dart';
import '../widgets/communication_segment_tabs.dart';
import '../widgets/conversations_panel.dart';
import '../widgets/new_conversation_dialog.dart';

/// HR Communication screen — Messages / Communication Log.
/// Matches the Communication reference: conversations list + active chat.
class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

  CommunicationController _resolve() {
    if (Get.isRegistered<CommunicationController>()) {
      return Get.find<CommunicationController>();
    }
    return Get.put(CommunicationController());
  }

  Future<void> _openNewConversation(
    BuildContext context,
    CommunicationController controller,
  ) async {
    final result = await showNewConversationDialog(context);
    if (result == null) return;
    controller.startConversation(
      type: result.type,
      recipient: result.recipientQuery,
      firstMessage: result.firstMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolve();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            CommunicationHeader(
              onBack: () => Navigator.of(context).pop(),
              onNewConversation: () => _openNewConversation(context, controller),
            ),
            Expanded(
              child: Obx(() {
                if (controller.selectedTab.value ==
                    CommunicationTab.communicationLog) {
                  return const _CommunicationLogPlaceholder();
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
                );
                final chat = ChatPanel(
                  conversation: controller.selectedConversation,
                  messages: controller.activeMessages.toList(),
                  messageController: controller.messageController,
                  onSend: controller.sendMessage,
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

                return ListView(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 16,
                    top: 8,
                    bottom: 20,
                  ),
                  children: [
                    conversations,
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.58,
                      child: chat,
                    ),
                  ],
                );
              }),
            ),
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
