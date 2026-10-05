import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../documents/presentation/pages/family_documents_page.dart';
import '../../../family_shell.dart';
import '../../../messages/presentation/pages/family_conversation_page.dart';
import '../../../profile_settings/presentation/pages/family_support_ticket_thread_page.dart';
import '../../../profile_settings/presentation/pages/family_support_tickets_page.dart';
import '../../../visit_requests/presentation/pages/visit_request_details_page.dart';
import '../../domain/entities/family_notification_target.dart';

typedef FamilyNotificationNavigate =
    void Function(FamilyNotificationTarget target);

/// Opens the Family screen for a tapped notification. Shell tabs reset the
/// stack onto [FamilyShell] like the search page does; detail screens are
/// pushed on top of the notifications list.
abstract final class FamilyNotificationNavigator {
  /// [FamilyShell] tab index for list-level destinations.
  static int? shellTabFor(FamilyNotificationTarget target) {
    return switch (target.destination) {
      FamilyNotificationDestination.home => 0,
      FamilyNotificationDestination.dailyUpdates => 1,
      FamilyNotificationDestination.appointments => 2,
      FamilyNotificationDestination.messages => 3,
      _ => null,
    };
  }

  /// Page pushed for detail-level destinations.
  static Widget? pageFor(FamilyNotificationTarget target) {
    final id = target.id ?? '';
    return switch (target.destination) {
      FamilyNotificationDestination.appointmentDetail =>
        VisitRequestDetailsPage(requestId: id),
      FamilyNotificationDestination.conversation => FamilyConversationPage(
        conversationId: id,
      ),
      FamilyNotificationDestination.documents => const FamilyDocumentsPage(),
      FamilyNotificationDestination.supportTicket =>
        FamilySupportTicketThreadPage(ticketId: id),
      FamilyNotificationDestination.supportTickets =>
        const FamilySupportTicketsPage(),
      _ => null,
    };
  }

  static void open(FamilyNotificationTarget target) {
    final tab = shellTabFor(target);
    if (tab != null) {
      Get.offAll(() => FamilyShell(initialIndex: tab));
      return;
    }
    final page = pageFor(target);
    if (page != null) Get.to(() => page);
  }

  const FamilyNotificationNavigator._();
}
