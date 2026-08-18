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
import '../widgets/typing_indicator.dart';

/// The Message Details (conversation thread) screen for a single
/// conversation.
///
/// Unlike `TasksMessagesController`/`StaffTasksMessagesPage`, this page's
/// controller is **not** a shared singleton: since the chat history
/// is per-conversation mock data, a fresh [MessageThreadController] is put
/// into GetX tagged with [conversationId] the first time this page is
/// opened for that conversation, so switching between conversations never
/// mixes up message lists.
///
/// Hosts [StaffBottomNavBar] with "MAR / Tasks" selected so the pushed route
/// still matches reference frames that show the staff bottom nav.
class MessageThreadPage extends StatelessWidget {
  final String conversationId;

  /// Index of the "MAR / Tasks" slot in [StaffBottomNavBar.items].
  static const int _marTasksTabIndex = 3;

  const MessageThreadPage({super.key, required this.conversationId});

  MessageThreadController _resolveController() {
    try {
      return Get.find<MessageThreadController>(tag: conversationId);
    } catch (_) {
      return Get.put(
        MessageThreadController(
          conversationId: conversationId,
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
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
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
                  isActiveNow: thread.isActiveNow,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
                  children: [
                    const DateDivider(label: 'Today'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                    for (var i = 0; i < messages.length; i++) ...[
                      ChatBubble(
                        message: messages[i],
                        contactInitials: thread.contactInitials,
                        // Avatar on the first bubble of a consecutive same-direction group.
                        showAvatar: i == 0 || messages[i].direction != messages[i - 1].direction,
                      ),
                      if (i != messages.length - 1)
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(
                            context,
                            messages[i].direction == messages[i + 1].direction ? 10 : 16,
                          ),
                        ),
                    ],
                    if (thread.isOtherPersonTyping) ...[
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                      TypingIndicator(contactInitials: thread.contactInitials),
                    ],
                  ],
                ),
              ),
              MessageInputBar(
                controller: controller.textController,
                onSend: controller.sendMessage,
              ),
            ],
          );
        }),
      ),
    );
  }
}
