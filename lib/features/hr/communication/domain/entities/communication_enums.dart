enum CommunicationTab { messages, communicationLog }

enum ConversationFilter { all, direct, group, family }

enum ChatMessageDirection { incoming, outgoing }

/// API `type` values for `POST /conversations`.
enum ConversationCreateType { direct, residenceGroup, familySupport }

extension ConversationCreateTypeApi on ConversationCreateType {
  String get apiValue => switch (this) {
        ConversationCreateType.direct => 'direct',
        ConversationCreateType.residenceGroup => 'residence_group',
        ConversationCreateType.familySupport => 'family_support',
      };
}
