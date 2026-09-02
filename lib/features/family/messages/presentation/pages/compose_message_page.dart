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
                subtitle: 'Sent to the care team for your family member',
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
                    Container(
                      width: double.infinity,
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 14),
                        ),
                      ),
                      child: Text(
                        'Care team',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          color: AppColors.textHeading,
                        ),
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
                child: Obx(
                  () => SendMessageButton(
                    onTap: controller.isSending.value ? () {} : controller.sendMessage,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
