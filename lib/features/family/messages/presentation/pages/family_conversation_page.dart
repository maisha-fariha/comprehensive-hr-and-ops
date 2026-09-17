import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_conversation_thread.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../controllers/family_conversation_controller.dart';
import '../widgets/family_messages_header.dart';
import '../widgets/priority_toggle_row.dart';

class FamilyConversationPage extends StatelessWidget {
  final String conversationId;

  const FamilyConversationPage({super.key, required this.conversationId});

  FamilyConversationController _resolve() {
    try {
      return Get.find<FamilyConversationController>(tag: conversationId);
    } catch (_) {
      return Get.put(
        FamilyConversationController(conversationId: conversationId),
        tag: conversationId,
      );
    }
  }

  Future<void> _pickAttachment(
    BuildContext context,
    FamilyConversationController controller,
  ) async {
    final type = await showModalBottomSheet<MessageAttachmentType>(
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
                child: FamilyMessagesHeader(title: thread.title),
              ),
              Expanded(
                child: ListView.builder(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    all: 16,
                  ),
                  itemCount: thread.messages.length,
                  itemBuilder: (context, index) {
                    final message = thread.messages[index];
                    final outgoing =
                        message.direction == FamilyMessageDirection.outgoing;
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
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
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
                            Text(
                              message.timeLabel,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  10,
                                ),
                                color: outgoing
                                    ? Colors.white70
                                    : AppColors.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
                              enabled: !controller.isSending.value,
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
