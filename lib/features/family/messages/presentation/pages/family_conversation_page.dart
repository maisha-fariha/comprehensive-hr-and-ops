import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_conversation_thread.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../controllers/family_conversation_controller.dart';
import '../controllers/family_messages_controller.dart';
import '../widgets/family_messages_header.dart';
import '../widgets/priority_toggle_row.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

class FamilyConversationPage extends StatelessWidget {
  final String conversationId;
  final bool initiallyLeft;

  const FamilyConversationPage({
    super.key,
    required this.conversationId,
    this.initiallyLeft = false,
  });

  FamilyConversationController _resolve() {
    try {
      final existing =
          Get.find<FamilyConversationController>(tag: conversationId);
      if (initiallyLeft) existing.hasLeft.value = true;
      return existing;
    } catch (_) {
      return Get.put(
        FamilyConversationController(
          conversationId: conversationId,
          initiallyLeft: initiallyLeft,
        ),
        tag: conversationId,
      );
    }
  }

  Future<void> _hide(
    BuildContext context,
    FamilyConversationController controller,
  ) async {
    final hidden = await controller.hideConversation();
    if (!hidden || !context.mounted) return;
    if (Get.isRegistered<FamilyMessagesController>()) {
      await Get.find<FamilyMessagesController>().loadConversations();
    }
    if (context.mounted) Navigator.of(context).maybePop();
  }

  Future<void> _leave(
    BuildContext context,
    FamilyConversationController controller,
  ) async {
    final proceed = await _confirmLeave(
      context,
      lastRelative: false,
    );
    if (proceed != true || !context.mounted) return;
    final outcome = await controller.leaveConversation();
    if (outcome != 'last_relative' || !context.mounted) return;
    final anyway = await _confirmLeave(context, lastRelative: true);
    if (anyway != true || !context.mounted) return;
    await controller.leaveConversation(confirm: true);
  }

  Future<bool?> _confirmLeave(
    BuildContext context, {
    required bool lastRelative,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.8;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastRelative
                        ? 'You are the last family member here'
                        : 'Leave this conversation?',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lastRelative
                        ? 'If you leave, the care home will have nobody in this conversation to talk to. You will still be able to read what was said until now.'
                        : 'You will still be able to read everything said until now, but you will not see new messages or be able to reply.',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: lastRelative
                            ? AppColors.criticalRed
                            : AppColors.primaryNavy,
                      ),
                      child: Text(lastRelative ? 'Leave anyway' : 'Leave'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAttachment(
    BuildContext context,
    FamilyConversationController controller,
  ) async {
    final type = await showAppBottomSheet<MessageAttachmentType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Photo'),
              onTap: () =>
                  Navigator.pop(context, MessageAttachmentType.photo),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(context, MessageAttachmentType.pdf),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Document'),
              onTap: () =>
                  Navigator.pop(context, MessageAttachmentType.document),
            ),
          ],
        ),
      ),
    );
    if (type != null) await controller.pickAttachment(type);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolve();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          final thread = controller.thread;
          if (thread == null && controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }
          if (thread == null) {
            return Center(
              child: Text(
                controller.errorMessage.value.isEmpty
                    ? 'Could not load this conversation.'
                    : controller.errorMessage.value,
              ),
            );
          }
          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: FamilyMessagesHeader(
                  title: thread.title,
                  onBack: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).pop();
                  },
                  onHide: () => _hide(context, controller),
                  onLeave: controller.hasLeft.value
                      ? null
                      : () => _leave(context, controller),
                ),
              ),
              Expanded(
                child: thread.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: ResponsiveHelper.getResponsivePadding(
                            context,
                            all: 24,
                          ),
                          child: const Text(
                            'No messages in this conversation yet. Send a note below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.textFaint,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          all: 16,
                        ),
                        itemCount: thread.messages.length,
                        itemBuilder: (context, index) {
                          final message = thread
                              .messages[thread.messages.length - 1 - index];
                          final outgoing =
                              message.direction ==
                              FamilyMessageDirection.outgoing;
                          return Align(
                            alignment: outgoing
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  10,
                                ),
                              ),
                              padding: ResponsiveHelper.getResponsivePadding(
                                context,
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: outgoing
                                    ? AppColors.secondaryTeal
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: outgoing
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!outgoing)
                                    Text(
                                      message.senderName,
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w700,
                                        fontSize:
                                            ResponsiveHelper.getResponsiveFontSize(
                                              context,
                                              11,
                                            ),
                                        color: AppColors.secondaryTeal,
                                      ),
                                    ),
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: outgoing
                                          ? Colors.white
                                          : AppColors.textHeading,
                                    ),
                                  ),
                                  if (outgoing)
                                    _OutgoingStatus(message: message)
                                  else
                                    Text(
                                      message.timeLabel,
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize:
                                            ResponsiveHelper.getResponsiveFontSize(
                                              context,
                                              10,
                                            ),
                                        color: AppColors.textFaint,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (controller.hasLeft.value)
                ColoredBox(
                  color: AppColors.surfaceWhite,
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: const Text(
                      'You left this conversation. What was said until then stays here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PriorityToggleRow(
                        value: controller.isPriority.value,
                        onChanged: controller.togglePriority,
                      ),
                      if (controller.attachments.isNotEmpty) ...[
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(
                            context,
                            8,
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final file in controller.attachments)
                              InputChip(
                                label: Text(
                                  file.fileName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onDeleted: controller.isSending.value
                                    ? null
                                    : () => controller.removeAttachment(file),
                              ),
                          ],
                        ),
                      ],
                      if (controller.isUploading.value)
                        Padding(
                          padding: EdgeInsets.only(
                            top: ResponsiveHelper.getResponsiveHeight(
                              context,
                              8,
                            ),
                          ),
                          child: const LinearProgressIndicator(
                            color: AppColors.secondaryTeal,
                            minHeight: 2,
                          ),
                        ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(
                          context,
                          8,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: controller.isSending.value ||
                                    controller.isUploading.value
                                ? null
                                : () => _pickAttachment(context, controller),
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              color: AppColors.secondaryTeal,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller.textController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Message the care team…',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => controller.send(),
                            ),
                          ),
                          IconButton(
                            onPressed: controller.isSending.value ||
                                    controller.isUploading.value
                                ? null
                                : controller.send,
                            icon: controller.isSending.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.secondaryTeal,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: AppColors.secondaryTeal,
                                  ),
                          ),
                        ],
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

class _OutgoingStatus extends StatelessWidget {
  final FamilyChatMessage message;

  const _OutgoingStatus({required this.message});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label) = switch (message.delivery) {
      FamilyMessageDelivery.sending => (Icons.schedule_rounded, 'Sending…'),
      FamilyMessageDelivery.queued => (
        Icons.cloud_off_rounded,
        'Waiting for connection',
      ),
      FamilyMessageDelivery.sent => (Icons.done_all_rounded, 'Sent'),
    };
    final style = TextStyle(
      fontFamily: 'Manrope',
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
      color: Colors.white70,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.delivery == FamilyMessageDelivery.sent
              ? message.timeLabel
              : label,
          style: style,
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 12, color: Colors.white70, semanticLabel: label),
      ],
    );
  }
}
