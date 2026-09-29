import 'package:gems_core/gems_core.dart';

import '../entities/communication_enums.dart';
import '../entities/hr_conversation.dart';
import '../entities/hr_message_contact.dart';

class CommunicationResidenceOption {
  final String id;
  final String name;

  const CommunicationResidenceOption({required this.id, required this.name});
}

class CommunicationClientOption {
  final String id;
  final String name;
  final String? residenceName;

  const CommunicationClientOption({
    required this.id,
    required this.name,
    this.residenceName,
  });
}

abstract class CommunicationRepository {
  Future<Result<List<HrConversation>>> getConversations();

  Future<Result<List<HrMessageContact>>> getContacts();

  Future<Result<List<CommunicationResidenceOption>>> getResidences();

  Future<Result<List<CommunicationClientOption>>> getClients();

  Future<Result<List<HrChatMessage>>> getMessages(String conversationId);

  /// `POST /conversations` — type: direct | residence_group | family_support.
  Future<Result<HrConversation>> startConversation({
    required ConversationCreateType type,
    List<String> memberUserIds,
    String? title,
    String? residenceId,
    String? clientId,
  });

  Future<Result<HrChatMessage>> sendMessage({
    required String conversationId,
    required String body,
  });

  Future<Result<void>> markThreadRead(String conversationId);

  Future<Result<void>> markAllRead();

  Future<Result<void>> addMembers({
    required String conversationId,
    required List<String> memberUserIds,
  });

  Future<Result<void>> removeMember({
    required String conversationId,
    required String memberId,
  });

  Future<Result<HrConversation>> updateConversation({
    required String conversationId,
    String? title,
    bool? archived,
  });
}
