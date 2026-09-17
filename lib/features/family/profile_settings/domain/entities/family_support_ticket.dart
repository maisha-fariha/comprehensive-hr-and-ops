import 'package:flutter/foundation.dart';

@immutable
class FamilySupportTicket {
  final String id;
  final String subject;
  final String status;
  final String priority;
  final String createdAtLabel;

  const FamilySupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAtLabel,
  });
}
