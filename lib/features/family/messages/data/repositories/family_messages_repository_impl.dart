import 'package:gems_core/gems_core.dart';

import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../domain/repositories/family_messages_repository.dart';

/// Local implementation of [FamilyMessagesRepository].
///
/// There is no backend endpoint for this screen yet, so this returns the
/// exact static content shown in the reference screenshot for the "Messages"
/// conversation list. Replace the body of this method with a real
/// `ApiService`/`BaseRepository` call (see
/// `flutter_gems/lib/repositories/todo_repository.dart` for the established
/// pattern) once an API contract exists - the domain layer and every widget
/// above it will keep working unchanged.
class FamilyMessagesRepositoryImpl implements FamilyMessagesRepository {
  static const List<ConversationPreview> _conversations = [
    ConversationPreview(
      id: 'sarah-m',
      name: 'Sarah M.',
      subtitle: 'Care Manager • Sunrise Home',
      avatarType: ConversationAvatarType.initials,
      initials: 'SM',
      accent: ConversationAccent.orange,
      timeLabel: '9:30 AM',
      previewText: "Hi Emily, here's the update you requested about John's progress this week...",
      unreadCount: 2,
    ),
    ConversationPreview(
      id: 'sunrise-home-team',
      name: 'Sunrise Home Team',
      subtitle: 'General Updates',
      avatarType: ConversationAvatarType.team,
      initials: '',
      accent: ConversationAccent.blue,
      timeLabel: 'Yesterday',
      previewText: 'Reminder: Family BBQ on May 24 at 11:00 AM in the courtyard.',
      unreadCount: 1,
    ),
    ConversationPreview(
      id: 'activities-team',
      name: 'Activities Team',
      subtitle: 'Recreation',
      avatarType: ConversationAvatarType.initials,
      initials: 'AT',
      accent: ConversationAccent.green,
      timeLabel: 'May 10',
      previewText: 'Photos from the garden outing have been shared.',
    ),
    ConversationPreview(
      id: 'therapy-team',
      name: 'Therapy Team',
      subtitle: 'Physiotherapy',
      avatarType: ConversationAvatarType.initials,
      initials: 'TT',
      accent: ConversationAccent.purple,
      timeLabel: 'May 8',
      previewText: 'Physiotherapy schedule for next week is confirmed.',
    ),
    ConversationPreview(
      id: 'johns-care-circle',
      name: "John's Care Circle",
      subtitle: 'Family Group',
      avatarType: ConversationAvatarType.group,
      initials: '',
      accent: ConversationAccent.orange,
      timeLabel: 'May 6',
      previewText: 'Michael: Thanks for the update!',
    ),
  ];

  @override
  Future<Result<List<ConversationPreview>>> getConversations() async {
    return Result.success(_conversations);
  }
}
