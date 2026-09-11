import 'package:gems_core/gems_core.dart';

import '../entities/hr_conversation.dart';
import '../entities/hr_message_contact.dart';

abstract class CommunicationRepository {
  Future<Result<List<HrConversation>>> getConversations();

  Future<Result<List<HrMessageContact>>> getContacts();

  Future<Result<List<HrChatMessage>>> getMessages(String conversationId);

  Future<Result<HrConversation>> startConversation({
    required String title,
    required List<String> memberUserIds,
    String? clientId,
    bool isMonitored = false,
  });

  Future<Result<HrChatMessage>> sendMessage({
    required String conversationId,
    required String body,
  });

  Future<Result<void>> markThreadRead(String conversationId);

  Future<Result<void>> markAllRead();

  /// `POST /conversations/{id}/members`
  Future<Result<void>> addMembers({
    required String conversationId,
    required List<String> memberUserIds,
  });

  /// `DELETE /conversations/{id}/members/{memberId}`
  Future<Result<void>> removeMember({
    required String conversationId,
    required String memberId,
  });

  /// `PATCH /conversations/{id}` — rename (and optional archive).
  Future<Result<HrConversation>> updateConversation({
    required String conversationId,
    String? title,
    bool? archived,
  });
}
