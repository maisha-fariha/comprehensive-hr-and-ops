import 'package:flutter/foundation.dart';

/// A contact from `GET /conversations/contacts` for starting a new thread.
@immutable
class MessageContact {
  final String id;
  final String name;
  final List<String> roles;

  const MessageContact({
    required this.id,
    required this.name,
    this.roles = const [],
  });

  String get subtitle => roles.isEmpty ? '' : roles.join(' · ');
}
