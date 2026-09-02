import 'package:gems_core/gems_core.dart';

import '../entities/conversation_preview.dart';

abstract class FamilyMessagesRepository {
  Future<Result<List<ConversationPreview>>> getConversations();

  Future<Result<void>> sendInConversation({
    required String conversationId,
    required String body,
    bool highPriority = false,
  });

  Future<Result<void>> startConversation({
    required String clientId,
    required String body,
    bool highPriority = false,
  });
}
