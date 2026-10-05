import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../domain/entities/family_conversation_thread.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/repositories/family_messages_repository.dart';
import 'family_messages_controller.dart';
import '../../../../../core/media/app_file_picker.dart';

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

  /// Last thread from the server plus messages confirmed by a POST since.
  FamilyConversationThread? _serverThread;

  /// Outgoing bubbles appended before the server confirmed them.
  final List<FamilyChatMessage> _localMessages = [];

  /// Bumped on every load and every confirmed send so a slower, older GET
  /// cannot overwrite a message that was appended after it started.
  int _loadGeneration = 0;

  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (!silent) setLoading(true);
    final result = await repository.getConversation(conversationId);
    if (generation == _loadGeneration) {
      result.when(
        success: (thread) {
          _serverThread = thread;
          _publish();
        },
        failure: (error) {
          if (thread == null) setError(error.message);
        },
      );
    }
    if (!silent) setLoading(false);
  }

  /// Mirrors the web reply flow: the input clears as soon as Send is tapped,
  /// the message shows straight away, and a failure restores the text.
  Future<void> send() async {
    final body = textController.text.trim();
    if ((body.isEmpty && attachments.isEmpty) || isSending.value) return;

    final text = body.isEmpty ? '(Attachment)' : body;
    final sentAttachments = List<MessageAttachment>.from(attachments);
    final wasPriority = isPriority.value;
    final local = FamilyChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      direction: FamilyMessageDirection.outgoing,
      timeLabel: IsoDateRange.timeLabel(DateTime.now()),
      senderName: 'You',
      delivery: FamilyMessageDelivery.sending,
    );

    textController.clear();
    attachments.clear();
    isPriority.value = false;
    _localMessages.add(local);
    _publish();

    isSending.value = true;
    final result = await repository.sendInConversation(
      conversationId: conversationId,
      body: text,
      highPriority: wasPriority,
      attachments: sentAttachments,
    );
    isSending.value = false;
    _localMessages.remove(local);

    result.when(
      success: (message) {
        if (message == null) {
          _localMessages.add(
            local.copyWith(delivery: FamilyMessageDelivery.queued),
          );
          _publish();
          return;
        }
        _loadGeneration++;
        final base = _serverThread;
        if (base != null) {
          _serverThread = base.copyWith(
            messages: [
              ...base.messages,
              message.copyWith(
                direction: FamilyMessageDirection.outgoing,
                senderName: 'You',
                timeLabel:
                    message.timeLabel.isEmpty ? local.timeLabel : null,
              ),
            ],
          );
        }
        _publish();
        if (Get.isRegistered<FamilyMessagesController>()) {
          Get.find<FamilyMessagesController>().refresh();
        }
        load(silent: true);
      },
      failure: (error) {
        _publish();
        final typed = textController.text;
        if (body.isNotEmpty) {
          textController.text = typed.isEmpty ? body : '$body\n$typed';
          textController.selection = TextSelection.collapsed(
            offset: textController.text.length,
          );
        }
        attachments.insertAll(0, sentAttachments);
        isPriority.value = wasPriority;
        AppErrorDialog.showResultError(error, fallbackTitle: 'Could not send');
      },
    );
  }

  void _publish() {
    final base = _serverThread;
    if (base == null) return;
    final serverOutgoing = {
      for (final message in base.messages)
        if (message.direction == FamilyMessageDirection.outgoing) message.text,
    };
    _localMessages.removeWhere(
      (message) =>
          message.delivery == FamilyMessageDelivery.queued &&
          serverOutgoing.contains(message.text),
    );
    setSuccess(
      _localMessages.isEmpty
          ? base
          : base.copyWith(messages: [...base.messages, ..._localMessages]),
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
