import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/conversation_preview.dart';
import '../../domain/repositories/family_messages_repository.dart';

/// GetX controller for the "Messages" conversation list screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the search-query state
/// backing the "Search people or groups" search bar.
class FamilyMessagesController extends BaseController<List<ConversationPreview>> {
  final FamilyMessagesRepository repository;

  FamilyMessagesController({required this.repository}) {
    loadConversations();
  }

  final RxString searchQuery = ''.obs;

  List<ConversationPreview> get conversations => state.value.data ?? const [];

  /// Conversations matching [searchQuery], filtered by name or subtitle.
  List<ConversationPreview> get visibleConversations {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return conversations;
    return conversations
        .where(
          (conversation) =>
              conversation.name.toLowerCase().contains(query) ||
              conversation.subtitle.toLowerCase().contains(query),
        )
        .toList();
  }

  void updateSearchQuery(String query) => searchQuery.value = query;

  Future<void> loadConversations() async {
    setLoading(true);
    final result = await repository.getConversations();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadConversations();
}
