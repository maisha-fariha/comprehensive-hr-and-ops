import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_conversation.dart';
import '../../domain/entities/hr_message_contact.dart';

abstract final class CommunicationMapper {
  static List<HrConversation> conversationsFrom(
    dynamic body, {
    String? currentUserId,
  }) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(
          (item) => conversationFrom(
            JsonCodec.asMap(item),
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  static HrConversation conversationFrom(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final members = JsonCodec.listAt(json, 'members');
    final participants = _participants(members);
    final messages = JsonCodec.listAt(json, 'messages');
    Map<String, dynamic>? lastMessage = JsonCodec.mapAt(json, 'lastMessage');
    DateTime? lastAt = lastMessage == null
        ? null
        : JsonCodec.dateTime(lastMessage['createdAt']);
    for (final raw in messages.whereType<Map>()) {
      final row = JsonCodec.asMap(raw);
      final at = JsonCodec.dateTime(row['createdAt']);
      if (lastMessage == null ||
          (at != null && (lastAt == null || at.isAfter(lastAt)))) {
        lastMessage = row;
        lastAt = at;
      }
    }
    final type = (json['type'] ?? '').toString().toLowerCase();
    final peopleCount = participants.isNotEmpty
        ? participants.length
        : (members.isEmpty ? 1 : members.length);
    final kind = _kindFromType(type, peopleCount);
    final createdAt = JsonCodec.dateTime(json['createdAt']);
    lastAt ??= createdAt;
    final rawTitle = JsonCodec.string(json['title']);
    final title = (rawTitle != null && rawTitle.trim().isNotEmpty)
        ? rawTitle.trim()
        : _fallbackTitle(
            kind: kind,
            members: members,
            currentUserId: currentUserId,
          );
    final unread = JsonCodec.integerOr(json['unreadCount'], 0);
    final monitored = JsonCodec.boolean(json['isMonitored']) ?? false;
    final archived = JsonCodec.dateTime(json['archivedAt']) != null ||
        (JsonCodec.boolean(json['archived']) ?? false);

    return HrConversation(
      id: JsonCodec.stringOr(json['id'], title),
      title: title,
      preview: JsonCodec.stringOr(
        lastMessage?['body'] ?? json['preview'],
        'No messages yet',
      ),
      dateLabel: lastAt == null ? '' : IsoDateRange.formatShortDate(lastAt.toLocal()),
      subtitle: _subtitle(kind, peopleCount),
      kind: kind,
      memberCount: peopleCount,
      unreadCount: unread,
      isActive: unread > 0 || lastAt != null,
      isGroup: kind != ConversationFilter.direct,
      isMonitored: monitored,
      isArchived: archived,
      participants: participants,
    );
  }

  static List<HrConversationParticipant> _participants(List<dynamic> members) {
    final people = <HrConversationParticipant>[];
    for (final raw in members.whereType<Map>()) {
      final row = JsonCodec.asMap(raw);
      if (row['leftAt'] != null) continue;
      final user = JsonCodec.mapAt(row, 'user') ?? row;
      final userId = JsonCodec.string(row['userId'] ?? user['id']);
      if (userId == null || userId.isEmpty) continue;
      final name = IsoDateRange.personName(user);
      people.add(
        HrConversationParticipant(
          userId: userId,
          name: name == 'Unknown' ? 'Participant' : name,
        ),
      );
    }
    return people;
  }

  static String _fallbackTitle({
    required ConversationFilter kind,
    required List<dynamic> members,
    String? currentUserId,
  }) {
    if (kind == ConversationFilter.direct ||
        kind == ConversationFilter.family) {
      final other = _otherMemberName(members, currentUserId);
      if (other != null) return other;
      // Web uses "Conversation" when a family thread has no title and no
      // other person still in it (they left, or only you remain).
      return kind == ConversationFilter.family
          ? 'Conversation'
          : 'Direct message';
    }
    return 'Group conversation';
  }

  /// Untitled direct and family threads use the other person's name,
  /// the same way the web titles a guardian chat "Gurdian One".
  static String? _otherMemberName(
    List<dynamic> members,
    String? currentUserId,
  ) {
    for (final raw in members.whereType<Map>()) {
      final row = JsonCodec.asMap(raw);
      if (row['leftAt'] != null) continue;
      final user = JsonCodec.mapAt(row, 'user') ?? row;
      final userId = JsonCodec.string(row['userId'] ?? user['id']);
      if (currentUserId != null && userId != null && userId == currentUserId) {
        continue;
      }
      final name = IsoDateRange.personName(user);
      if (name != 'Unknown' && name.isNotEmpty) return name;
    }
    return null;
  }

  static List<HrMessageContact> contactsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          return HrMessageContact(
            id: JsonCodec.stringOr(json['id'], ''),
            name: JsonCodec.stringOr(json['name'], 'Unknown'),
            roles: JsonCodec.listAt(json, 'roles')
                .map((role) => role?.toString() ?? '')
                .where((role) => role.isNotEmpty)
                .toList(),
            relationship: JsonCodec.string(json['relationship']),
            residenceIds: JsonCodec.listAt(json, 'residenceIds')
                .map((id) => id?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toList(),
          );
        })
        .where((contact) => contact.id.isNotEmpty)
        .toList();
  }

  static List<HrChatMessage> messagesFrom(
    dynamic body, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    final rows = JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(
          (item) => messageFrom(
            JsonCodec.asMap(item),
            currentUserId: currentUserId,
            currentUserEmail: currentUserEmail,
          ),
        )
        .where((message) => message.text.isNotEmpty || message.id.isNotEmpty)
        .toList();
    rows.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return rows;
  }

  static HrChatMessage messageFrom(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    final sender = JsonCodec.mapAt(json, 'sender') ?? {};
    final senderId = JsonCodec.string(
      json['senderId'] ?? sender['id'],
    );
    final senderEmail = (JsonCodec.string(sender['email']) ?? '').toLowerCase();
    final senderName = IsoDateRange.personName(
      sender.isEmpty ? json['senderName'] : sender,
    );
    final mine = _isMine(
      senderId: senderId,
      senderEmail: senderEmail,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
    final at = JsonCodec.dateTime(json['createdAt']);
    return HrChatMessage(
      id: JsonCodec.stringOr(json['id'], 'message'),
      senderName: mine
          ? 'You'
          : (senderName == 'Unknown' ? 'Teammate' : senderName),
      senderInitials: IsoDateRange.initials(
        mine ? 'You' : senderName,
        fallback: 'TM',
      ),
      text: JsonCodec.stringOr(json['body'] ?? json['text'], ''),
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      direction:
          mine ? ChatMessageDirection.outgoing : ChatMessageDirection.incoming,
      sortKey: at?.millisecondsSinceEpoch ?? 0,
    );
  }

  static ConversationFilter _kindFromType(String type, int memberCount) {
    if (type.contains('direct') || type == 'dm') {
      return ConversationFilter.direct;
    }
    if (type.contains('family')) {
      return ConversationFilter.family;
    }
    if (type.contains('group') || type.contains('residence')) {
      return ConversationFilter.group;
    }
    return memberCount > 2
        ? ConversationFilter.group
        : ConversationFilter.direct;
  }

  static String _subtitle(ConversationFilter kind, int memberCount) {
    return switch (kind) {
      ConversationFilter.direct => 'Direct message',
      ConversationFilter.family =>
        memberCount == 1 ? '1 person' : '$memberCount people',
      ConversationFilter.group ||
      ConversationFilter.all =>
        'Residence group · $memberCount people',
    };
  }

  static bool _isMine({
    required String? senderId,
    required String senderEmail,
    required String? currentUserId,
    required String? currentUserEmail,
  }) {
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        senderId != null &&
        senderId == currentUserId) {
      return true;
    }
    final email = (currentUserEmail ?? '').trim().toLowerCase();
    return email.isNotEmpty && senderEmail == email;
  }

  const CommunicationMapper._();
}
