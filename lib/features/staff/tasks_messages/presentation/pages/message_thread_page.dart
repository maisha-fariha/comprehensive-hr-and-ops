import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';
import '../controllers/message_thread_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/date_divider.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/thread_header.dart';

/// Message Details (conversation thread) for a single conversation.
class MessageThreadPage extends StatelessWidget {
  final String conversationId;
  final String contactName;

  /// Index of the "MAR / Tasks" slot in [StaffBottomNavBar.items].
  static const int _marTasksTabIndex = 3;

  const MessageThreadPage({
    super.key,
    required this.conversationId,
    this.contactName = 'Conversation',
  });

  MessageThreadController _resolveController() {
    try {
      return Get.find<MessageThreadController>(tag: conversationId);
    } catch (_) {
      return Get.put(
        MessageThreadController(
          conversationId: conversationId,
          contactName: contactName,
          repository: GetIt.instance<StaffTasksMessagesRepository>(),
        ),
        tag: conversationId,
      );
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _marTasksTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final thread = controller.thread;

          if (thread == null && controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }

          if (thread == null) {
            return Center(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
                child: Text(
                  controller.errorMessage.value.isEmpty
                      ? 'Something went wrong while loading this conversation.'
                      : controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          final messages = controller.messages;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: ThreadHeader(
                  contactName: thread.contactName,
                  contactInitials: thread.contactInitials,
                  // Presence is not available yet — keep header name-only.
                  isActiveNow: false,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    if (messages.isNotEmpty) ...[
                      const DateDivider(label: 'Today'),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 16),
                      ),
                    ],
                    if (messages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No messages yet. Say hello.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < messages.length; i++) ...[
                        ChatBubble(
                          message: messages[i],
                          contactInitials: thread.contactInitials,
                          showAvatar: i == 0 ||
                              messages[i].direction !=
                                  messages[i - 1].direction,
                        ),
                        if (i != messages.length - 1)
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              messages[i].direction ==
                                      messages[i + 1].direction
                                  ? 10
                                  : 16,
                            ),
                          ),
                      ],
                  ],
                ),
              ),
              MessageInputBar(
                controller: controller.textController,
                priority: controller.sendPriority.value,
                onPriorityChanged: controller.setSendPriority,
                onSend: controller.sendMessage,
              ),
            ],
          );
        }),
      ),
    );
  }
}
