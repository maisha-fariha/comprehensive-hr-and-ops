import 'package:gems_core/gems_core.dart';

import '../entities/conversation_preview.dart';
import '../entities/family_conversation_thread.dart';
import '../entities/message_attachment.dart';

abstract class FamilyMessagesRepository {
  Future<Result<List<ConversationPreview>>> getConversations();

  Future<Result<FamilyConversationThread>> getConversation(String id);

  /// `POST /uploads?category=messages` → URL for [attachments].
  Future<Result<MessageAttachment>> uploadAttachment({
    required String localPath,
    required String fileName,
    required String fileType,
  });

  Future<Result<void>> sendInConversation({
    required String conversationId,
    required String body,
    bool highPriority = false,
    List<MessageAttachment> attachments = const [],
  });

  Future<Result<void>> startConversation({
    required String clientId,
    required String body,
    bool highPriority = false,
    List<MessageAttachment> attachments = const [],
  });
}
