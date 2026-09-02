import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/family_conversation_thread.dart';
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

  FamilyConversationThread? get thread => state.value.data;

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
    if (body.isEmpty || isSending.value) return;
    isSending.value = true;
    final result = await repository.sendInConversation(
      conversationId: conversationId,
      body: body,
    );
    isSending.value = false;
    result.when(
      success: (_) async {
        textController.clear();
        await load();
      },
      failure: (error) => Get.snackbar(
        'Could not send',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  @override
  Future<void> refresh() => load();

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
