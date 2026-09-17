import 'package:flutter/foundation.dart';

@immutable
class FamilySupportTicketMessage {
  final String id;
  final String body;
  final bool fromFamily;
  final String sentAtLabel;

  const FamilySupportTicketMessage({
    required this.id,
    required this.body,
    required this.fromFamily,
    required this.sentAtLabel,
  });
}
