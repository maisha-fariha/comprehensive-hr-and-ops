import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_conversation.dart';
import '../../domain/entities/hr_message_contact.dart';

abstract final class CommunicationMapper {
  static List<HrConversation> conversationsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => conversationFrom(JsonCodec.asMap(item)))
        .toList();
  }

  static HrConversation conversationFrom(Map<String, dynamic> json) {
    final members = JsonCodec.listAt(json, 'members');
    final messages = JsonCodec.listAt(json, 'messages');
    Map<String, dynamic>? lastMessage;
    DateTime? lastAt;
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
    final kind = _kindFromType(type, members.length);
    final createdAt = JsonCodec.dateTime(json['createdAt']);
    lastAt ??= createdAt;
    final title = JsonCodec.stringOr(json['title'], 'Conversation');
    final unread = JsonCodec.integerOr(json['unreadCount'], 0);
    final monitored = JsonCodec.boolean(json['isMonitored']) ?? false;

    return HrConversation(
      id: JsonCodec.stringOr(json['id'], title),
      title: title,
      preview: JsonCodec.stringOr(
        lastMessage?['body'] ?? json['preview'],
        monitored ? 'Monitored conversation' : 'No messages yet',
      ),
      dateLabel: lastAt == null ? '' : IsoDateRange.formatShortDate(lastAt.toLocal()),
      subtitle: _subtitle(kind, members.length, monitored),
      kind: kind,
      memberCount: members.isEmpty ? 1 : members.length,
      unreadCount: unread,
      isActive: unread > 0 || lastAt != null,
      isGroup: kind != ConversationFilter.direct,
      isMonitored: monitored,
    );
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

  static String _subtitle(
    ConversationFilter kind,
    int memberCount,
    bool monitored,
  ) {
    final base = switch (kind) {
      ConversationFilter.direct => 'Direct message',
      ConversationFilter.family => 'Family channel · $memberCount people',
      ConversationFilter.group ||
      ConversationFilter.all =>
        'Residence group · $memberCount people',
    };
    return monitored ? '$base · Monitored' : base;
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
