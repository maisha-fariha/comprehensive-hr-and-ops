import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../domain/repositories/family_messages_repository.dart';
import 'family_messages_controller.dart';

class ComposeMessageController extends GetxController {
  final FamilyMessagesRepository repository;
  final UserSession session;

  ComposeMessageController({
    FamilyMessagesRepository? repository,
    UserSession? session,
  })  : repository = repository ?? GetIt.instance<FamilyMessagesRepository>(),
        session = session ?? Get.find<UserSession>();

  final TextEditingController messageController = TextEditingController();
  final RxSet<MessageAttachmentType> selectedAttachments = <MessageAttachmentType>{}.obs;
  final RxBool isPriority = false.obs;
  final RxBool isSending = false.obs;

  void toggleAttachment(MessageAttachmentType type) {
    if (selectedAttachments.contains(type)) {
      selectedAttachments.remove(type);
    } else {
      selectedAttachments.add(type);
    }
  }

  void togglePriority(bool value) => isPriority.value = value;

  Future<void> sendMessage() async {
    final body = messageController.text.trim();
    if (body.isEmpty || isSending.value) return;
    final clientId = session.selectedClientId;
    if (clientId == null || clientId.isEmpty) {
      Get.snackbar(
        'Cannot send',
        'Open Home first so we know which family member this is for.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSending.value = true;
    final result = await repository.startConversation(
      clientId: clientId,
      body: body,
      highPriority: isPriority.value,
    );
    isSending.value = false;
    result.when(
      success: (_) {
        if (Get.isRegistered<FamilyMessagesController>()) {
          Get.find<FamilyMessagesController>().refresh();
        }
        Get.back();
      },
      failure: (error) => Get.snackbar(
        'Could not send',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
