import 'package:gems_core/gems_core.dart';

import '../entities/conversation_preview.dart';

/// Contract for fetching the Family "Messages" screen's conversation list.
/// The presentation layer only ever depends on this interface, so swapping
/// the mocked [FamilyMessagesRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class FamilyMessagesRepository {
  Future<Result<List<ConversationPreview>>> getConversations();
}
