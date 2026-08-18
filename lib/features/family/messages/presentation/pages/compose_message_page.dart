import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../controllers/compose_message_controller.dart';
import '../widgets/attachment_options_row.dart';
import '../widgets/compose_field_label.dart';
import '../widgets/compose_message_field.dart';
import '../widgets/compose_message_header.dart';
import '../widgets/priority_toggle_row.dart';
import '../widgets/recipient_input_field.dart';
import '../widgets/send_message_button.dart';

/// The "New Message" compose screen, reached from the [NewMessageFab] on
/// `FamilyMessagesListPage`.
///
/// Pushed as a standalone route via `Get.to()` with its own `Scaffold`/
/// `SafeArea` and back button, mirroring how
/// `lib/features/staff/tasks_messages/presentation/pages/message_thread_page.dart`
/// is a standalone pushed page for the analogous Staff feature.
class ComposeMessagePage extends StatelessWidget {
  const ComposeMessagePage({super.key});

  /// Always starts a fresh controller instance for a new draft rather than
  /// resolving a shared singleton - reusing the same instance across
  /// multiple "New Message" sessions would resurface a previous draft's
  /// field values, and its `TextEditingController`s would already be
  /// disposed after the first time this page is closed (see the identical
  /// rationale on `CreateIncidentPage`).
  ComposeMessageController _resolveController() {
    if (Get.isRegistered<ComposeMessageController>()) {
      Get.delete<ComposeMessageController>(force: true);
    }
    return Get.put(ComposeMessageController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final fieldGap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: ComposeMessageHeader(
                title: 'New Message',
                subtitle: 'Send to a person or care group',
                onBack: Get.back,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ComposeFieldLabel('To'),
                    Obx(
                      () => RecipientInputField(
                        recipients: controller.recipients.toList(),
                        controller: controller.recipientInputController,
                        onRemoveRecipient: controller.removeRecipient,
                        onSubmitted: controller.addRecipientFromInput,
                      ),
                    ),
                    fieldGap,
                    const ComposeFieldLabel('Message'),
                    ComposeMessageField(controller: controller.messageController),
                    fieldGap,
                    const ComposeFieldLabel('Attachments', suffix: '(Optional)'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    Obx(
                      () => AttachmentOptionsRow(
                        selected: controller.selectedAttachments.toSet(),
                        onToggle: controller.toggleAttachment,
                      ),
                    ),
                    fieldGap,
                    Obx(
                      () => PriorityToggleRow(
                        value: controller.isPriority.value,
                        onChanged: controller.togglePriority,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 12, bottom: 12),
                child: SendMessageButton(onTap: controller.sendMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
