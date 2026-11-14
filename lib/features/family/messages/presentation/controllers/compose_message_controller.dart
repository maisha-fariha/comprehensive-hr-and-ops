import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../profile_settings/domain/entities/family_linked_client.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/repositories/family_messages_repository.dart';
import 'family_messages_controller.dart';

/// Web Message Care Team priorities (`general` omitted from the POST body).
enum MessageCarePriority {
  general,
  routine,
  high;

  String get apiValue => name;

  String get label => switch (this) {
        MessageCarePriority.general => 'General',
        MessageCarePriority.routine => 'Routine',
        MessageCarePriority.high => 'Urgent',
      };
}

class ComposeMessageController extends GetxController {
  final FamilyMessagesRepository repository;
  final UserSession session;

  ComposeMessageController({
    FamilyMessagesRepository? repository,
    UserSession? session,
  })  : repository = repository ?? GetIt.instance<FamilyMessagesRepository>(),
        session = session ?? Get.find<UserSession>();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final Rx<MessageCarePriority> priority = MessageCarePriority.general.obs;
  final RxBool isSending = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool loadingResidents = true.obs;
  final RxList<MessageAttachment> attachments = <MessageAttachment>[].obs;
  final RxList<FamilyLinkedClient> residents = <FamilyLinkedClient>[].obs;
  final RxnString clientId = RxnString();
  final RxnString bodyError = RxnString();
  final RxnString clientError = RxnString();
  final RxnString formError = RxnString();

  static const maxAttachments = 5;
  static const notLinkedMessage =
      "Your account isn't linked to a resident yet. Ask the care home to "
      'link you, then you can start a new conversation.';

  bool get hasLinkedResident => residents.isNotEmpty;
  bool get canSend =>
      hasLinkedResident &&
      !isSending.value &&
      !isUploading.value &&
      !loadingResidents.value;

  @override
  void onInit() {
    super.onInit();
    loadResidents();
  }

  Future<void> loadResidents() async {
    loadingResidents.value = true;
    formError.value = null;
    final result = await repository.getLinkedResidents();
    loadingResidents.value = false;
    result.when(
      success: (rows) {
        residents.assignAll(rows);
        if (rows.isEmpty) {
          clientId.value = null;
          formError.value = notLinkedMessage;
          return;
        }
        final selected = session.selectedClientId;
        final match = rows.where((r) => r.id == selected);
        final pick = match.isNotEmpty ? match.first : rows.first;
        clientId.value = pick.id;
        if (session.selectedClientId != pick.id) {
          session.selectClient(pick.id);
        }
      },
      failure: (error) {
        formError.value = error.message;
        final selected = session.selectedClientId;
        if (selected != null && selected.isNotEmpty) {
          clientId.value = selected;
          residents.assignAll([
            FamilyLinkedClient(
              id: selected,
              initials: 'R',
              name: 'Resident',
              subtitle: '',
              statusLabel: 'active',
            ),
          ]);
        }
      },
    );
  }

  void selectResident(String id) {
    clientId.value = id;
    clientError.value = null;
    session.selectClient(id);
  }

  void setPriority(MessageCarePriority value) => priority.value = value;

  void removeAttachment(MessageAttachment attachment) {
    attachments.remove(attachment);
  }

  Future<void> pickAttachment() async {
    if (isUploading.value || isSending.value) return;
    if (attachments.length >= maxAttachments) {
      AppSnackbar.show(
        'Attachment limit',
        'You can attach up to $maxAttachments files.',
        force: true,
      );
      return;
    }

    final result = await AppFilePicker.pickFiles(
      type: FileType.any,
      withData: false,
      allowMultiple: true,
    );
    final files = result?.files ?? const [];
    if (files.isEmpty) return;

    final remaining = maxAttachments - attachments.length;
    final toUpload = files.take(remaining).toList();
    if (files.length > remaining) {
      AppSnackbar.show(
        'Attachment limit',
        'Only $maxAttachments files can be attached. Extra files were skipped.',
        force: true,
      );
    }

    isUploading.value = true;
    for (final file in toUpload) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;
      final upload = await repository.uploadAttachment(
        localPath: path,
        fileName: file.name,
        fileType: _mimeFor(file.name),
      );
      upload.when(
        success: attachments.add,
        failure: (error) => AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not upload attachment',
        ),
      );
    }
    isUploading.value = false;
  }

  bool validate() {
    bodyError.value = null;
    clientError.value = null;
    formError.value = null;
    var ok = true;
    if (!hasLinkedResident) {
      formError.value = notLinkedMessage;
      ok = false;
    }
    final id = clientId.value?.trim() ?? '';
    if (hasLinkedResident && id.isEmpty) {
      clientError.value = 'Choose a resident.';
      ok = false;
    }
    if (messageController.text.trim().isEmpty) {
      bodyError.value = 'Your message is required.';
      ok = false;
    }
    return ok;
  }

  /// Returns the new conversation id on success (may be empty), or `null` on
  /// validation / API failure. Callers must dismiss the sheet before opening
  /// the thread — navigating while the modal is open leaves it stuck.
  Future<String?> sendMessage() async {
    if (!validate() || isSending.value) return null;
    final id = clientId.value?.trim() ?? '';
    final body = messageController.text.trim();
    final subject = subjectController.text.trim();

    isSending.value = true;
    final result = await repository.startConversation(
      clientId: id,
      body: body,
      subject: subject.isEmpty ? null : subject,
      priority: priority.value.apiValue,
      attachments: List<MessageAttachment>.from(attachments),
    );
    isSending.value = false;

    String? conversationId;
    result.when(
      success: (id) {
        conversationId = id ?? '';
        subjectController.clear();
        messageController.clear();
        attachments.clear();
        priority.value = MessageCarePriority.general;
        if (Get.isRegistered<FamilyMessagesController>()) {
          Get.find<FamilyMessagesController>().refresh();
        }
        AppSnackbar.show(
          'Message sent',
          "The care home's management will reply here.",
          force: true,
        );
      },
      failure: (error) {
        formError.value = error.message;
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not send',
        );
      },
    );
    return conversationId;
  }

  static String _mimeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  @override
  void onClose() {
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
