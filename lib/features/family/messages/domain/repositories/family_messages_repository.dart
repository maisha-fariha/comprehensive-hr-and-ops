import 'package:gems_core/gems_core.dart';

import '../../../profile_settings/domain/entities/family_linked_client.dart';
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

  /// `GET /family/clients` with display names for the Resident picker.
  Future<Result<List<FamilyLinkedClient>>> getLinkedResidents();

  /// `POST /family/messages/:id/read`. Opening a thread clears its badge.
  Future<Result<void>> markConversationRead(String conversationId);

  /// `POST /family/messages/:id/hide` or `/unhide`.
  Future<Result<void>> setHidden(String conversationId, {required bool hidden});

  /// `POST /family/messages/:id/leave`. [confirm] is sent only after
  /// `LAST_RELATIVE`.
  Future<Result<void>> leaveConversation(
    String conversationId, {
    bool confirm = false,
  });

  /// Web `POST /family/messages` — `{ clientId, body, subject?, priority?,
  /// attachments? }`. [priority] is `routine` / `high`; omit for `general`.
  Future<Result<String?>> startConversation({
    required String clientId,
    required String body,
    String? subject,
    String? priority,
    List<MessageAttachment> attachments = const [],
  });
}
