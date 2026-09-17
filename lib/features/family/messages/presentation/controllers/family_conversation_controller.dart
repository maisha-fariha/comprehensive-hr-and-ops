import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/family_conversation_thread.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/repositories/family_messages_repository.dart';

class FamilyConversationController
    extends BaseController<FamilyConversationThread> {
  final String conversationId;
  final FamilyMessagesRepository repository;

  FamilyConversationController({
    required this.conversationId,
    FamilyMessagesRepository? repository,
  }) : repository = repository ?? GetIt.instance<FamilyMessagesRepository>() {
    load();
  }

  final TextEditingController textController = TextEditingController();
  final RxBool isSending = false.obs;
  final RxBool isPriority = false.obs;
  final RxBool isUploading = false.obs;
  final RxList<MessageAttachment> attachments = <MessageAttachment>[].obs;

  FamilyConversationThread? get thread => state.value.data;

  void togglePriority(bool value) => isPriority.value = value;

  void removeAttachment(MessageAttachment attachment) {
    attachments.remove(attachment);
  }

  Future<void> pickAttachment(MessageAttachmentType type) async {
    if (isUploading.value || isSending.value) return;

    final result = await FilePicker.platform.pickFiles(
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

  Future<void> load() async {
    setLoading(true);
    final result = await repository.getConversation(conversationId);
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> send() async {
    final body = textController.text.trim();
    if ((body.isEmpty && attachments.isEmpty) || isSending.value) return;
    isSending.value = true;
    final result = await repository.sendInConversation(
      conversationId: conversationId,
      body: body.isEmpty ? '(Attachment)' : body,
      highPriority: isPriority.value,
      attachments: List<MessageAttachment>.from(attachments),
    );
    isSending.value = false;
    result.when(
      success: (_) async {
        textController.clear();
        attachments.clear();
        isPriority.value = false;
        await load();
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
  Future<void> refresh() => load();

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
