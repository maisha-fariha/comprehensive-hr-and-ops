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

  /// `POST /family/messages/:id/messages` → the created message, or `null`
  /// when the write was queued offline and has no server copy yet.
  Future<Result<FamilyChatMessage?>> sendInConversation({
    required String conversationId,
    required String body,
    bool highPriority = false,
    List<MessageAttachment> attachments = const [],
  });

  /// `GET /family/clients` → ids of the residents this account is linked to.
  /// A new conversation needs one of them as `clientId`.
  Future<Result<List<String>>> getLinkedClientIds();

  /// `POST /family/messages` → id of the new conversation (`null` when the
  /// response has none, e.g. queued offline).
  Future<Result<String?>> startConversation({
    required String clientId,
    required String body,
    bool highPriority = false,
    List<MessageAttachment> attachments = const [],
  });
}
