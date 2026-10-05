import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/repositories/family_messages_repository.dart';
import '../pages/family_conversation_page.dart';
import 'family_messages_controller.dart';
import '../../../../../core/media/app_file_picker.dart';

class ComposeMessageController extends GetxController {
  final FamilyMessagesRepository repository;
  final UserSession session;

  ComposeMessageController({
    FamilyMessagesRepository? repository,
    UserSession? session,
  })  : repository = repository ?? GetIt.instance<FamilyMessagesRepository>(),
        session = session ?? Get.find<UserSession>();

  final TextEditingController messageController = TextEditingController();
  final RxBool isPriority = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isUploading = false.obs;
  final RxList<MessageAttachment> attachments = <MessageAttachment>[].obs;

  /// `null` while checking (or when the check could not reach the server).
  final RxnBool hasLinkedResident = RxnBool();

  static const notLinkedMessage =
      "Your account isn't linked to a resident yet. Ask the care home to "
      'link you, then you can start a new conversation.';

  bool get canSend => hasLinkedResident.value != false;

  @override
  void onInit() {
    super.onInit();
    checkLinkedResident();
  }

  Future<void> checkLinkedResident() async {
    final result = await repository.getLinkedClientIds();
    result.when(
      success: (ids) {
        if (ids.isEmpty) {
          hasLinkedResident.value = false;
          return;
        }
        if (!ids.contains(session.selectedClientId)) {
          session.selectClient(ids.first);
        }
        hasLinkedResident.value = true;
      },
      failure: (_) {
        final selected = session.selectedClientId;
        hasLinkedResident.value =
            selected != null && selected.isNotEmpty ? true : null;
      },
    );
  }

  void togglePriority(bool value) => isPriority.value = value;

  void removeAttachment(MessageAttachment attachment) {
    attachments.remove(attachment);
  }

  Future<void> pickAttachment(MessageAttachmentType type) async {
    if (isUploading.value || isSending.value) return;

    final result = await AppFilePicker.pickFiles(
      type: switch (type) {
        MessageAttachmentType.photo => FileType.image,
        MessageAttachmentType.pdf => FileType.custom,
        MessageAttachmentType.document => FileType.custom,
      },
      allowedExtensions: switch (type) {
        MessageAttachmentType.photo => null,
        MessageAttachmentType.pdf => const ['pdf'],
        MessageAttachmentType.document => const [
            'pdf',
            'doc',
            'docx',
            'txt',
            'png',
            'jpg',
            'jpeg',
          ],
      },
      withData: false,
    );
    final file = result?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null || path.isEmpty) return;

    isUploading.value = true;
    final upload = await repository.uploadAttachment(
      localPath: path,
      fileName: file.name,
      fileType: _mimeFor(file.name, type),
    );
    isUploading.value = false;
    upload.when(
      success: (attachment) => attachments.add(attachment),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not upload attachment',
      ),
    );
  }

  Future<void> sendMessage() async {
    final body = messageController.text.trim();
    if ((body.isEmpty && attachments.isEmpty) || isSending.value) return;
    final clientId = session.selectedClientId;
    if (!canSend || clientId == null || clientId.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'No linked resident',
        message: notLinkedMessage,
      );
      return;
    }

    isSending.value = true;
    final result = await repository.startConversation(
      clientId: clientId,
      body: body.isEmpty ? '(Attachment)' : body,
      highPriority: isPriority.value,
      attachments: List<MessageAttachment>.from(attachments),
    );
    isSending.value = false;
    result.when(
      success: (conversationId) {
        messageController.clear();
        attachments.clear();
        isPriority.value = false;
        if (Get.isRegistered<FamilyMessagesController>()) {
          Get.find<FamilyMessagesController>().refresh();
        }
        AppSnackbar.show(
          'Message sent!',
          'A member of the care team will respond shortly.',
          force: true,
        );
        if (conversationId == null || conversationId.isEmpty) {
          Get.back();
        } else {
          Get.off(() => FamilyConversationPage(conversationId: conversationId));
        }
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not send',
      ),
    );
  }

  static String _mimeFor(String fileName, MessageAttachmentType type) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return switch (type) {
      MessageAttachmentType.photo => 'image/jpeg',
      MessageAttachmentType.pdf => 'application/pdf',
      MessageAttachmentType.document => 'application/octet-stream',
    };
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
