import 'package:flutter/foundation.dart';

/// A single recipient chip shown in the "To" field of the "New Message"
/// compose screen.
@immutable
class MessageRecipient {
  final String id;
  final String name;
  final String initials;

  const MessageRecipient({
    required this.id,
    required this.name,
    required this.initials,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || (other is MessageRecipient && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
