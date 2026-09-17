import 'package:flutter/foundation.dart';

import 'family_support_ticket.dart';
import 'family_support_ticket_message.dart';

@immutable
class FamilySupportTicketThread {
  final FamilySupportTicket ticket;
  final List<FamilySupportTicketMessage> messages;

  const FamilySupportTicketThread({
    required this.ticket,
    required this.messages,
  });
}
