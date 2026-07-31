/// Which kind of avatar glyph a conversation row renders: plain initials, or
/// an icon standing in for a team/group chat that has no single person's
/// initials to show.
enum ConversationAvatarType { initials, team, group }

/// Color accent applied to a conversation row's avatar background/foreground,
/// matching the reference design's palette of tinted circular avatars.
enum ConversationAccent { orange, blue, green, purple }

/// Which optional attachment kind is selectable on the "New Message" compose
/// screen.
enum MessageAttachmentType { photo, pdf, document }
