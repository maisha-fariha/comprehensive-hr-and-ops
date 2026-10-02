import 'package:flutter/foundation.dart';

import 'family_notification.dart';

/// Family screen a notification tap opens.
enum FamilyNotificationDestination {
  home,
  appointments,
  appointmentDetail,
  messages,
  conversation,
  dailyUpdates,
  documents,
  supportTickets,
  supportTicket,
}

@immutable
class FamilyNotificationTarget {
  final FamilyNotificationDestination destination;
  final String? id;

  const FamilyNotificationTarget(this.destination, [this.id]);

  /// Port of the web bell's `notificationHref(entityType, entityId, metaJson)`
  /// mapped onto Family screens. Returns `null` for entity types that only
  /// exist on the staff dashboard (shifts, tasks, incidents, medication,
  /// invoices, training, ...): those are marked read without navigating.
  static FamilyNotificationTarget? resolve(FamilyNotification notification) {
    final type = _entityType(notification);
    if (type == null) return null;
    final meta = notification.meta;

    String? idFrom(List<String> metaKeys) {
      final direct = notification.entityId;
      if (direct != null && direct.isNotEmpty) return direct;
      for (final key in [...metaKeys, 'id']) {
        final value = meta[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return null;
    }

    FamilyNotificationTarget withId(
      String? id,
      FamilyNotificationDestination detail,
      FamilyNotificationDestination list,
    ) {
      return id == null
          ? FamilyNotificationTarget(list)
          : FamilyNotificationTarget(detail, id);
    }

    switch (type) {
      case 'appointment':
        return withId(
          idFrom(const ['appointmentId']),
          FamilyNotificationDestination.appointmentDetail,
          FamilyNotificationDestination.appointments,
        );
      case 'conversation':
        return withId(
          idFrom(const ['conversationId']),
          FamilyNotificationDestination.conversation,
          FamilyNotificationDestination.messages,
        );
      case 'support_ticket':
        return withId(
          idFrom(const ['ticketId']),
          FamilyNotificationDestination.supportTicket,
          FamilyNotificationDestination.supportTickets,
        );
      case 'family_update':
      case 'daily_log':
      case 'care_flag':
        return const FamilyNotificationTarget(
          FamilyNotificationDestination.dailyUpdates,
        );
      case 'document':
        return const FamilyNotificationTarget(
          FamilyNotificationDestination.documents,
        );
      case 'client':
        return const FamilyNotificationTarget(
          FamilyNotificationDestination.home,
        );
    }
    return null;
  }

  static String? _entityType(FamilyNotification notification) {
    final explicit = notification.entityType;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final key =
        notification.eventKey ??
        (notification.meta['eventKey'] is String
            ? notification.meta['eventKey'] as String
            : null);
    if (key == null || key.isEmpty) return null;
    if (key.startsWith('appointments.')) return 'appointment';
    if (key.startsWith('messaging.')) return 'conversation';
    if (key.startsWith('family.')) return 'family_update';
    if (key.startsWith('care.') || key.startsWith('daily_logs.')) {
      return 'care_flag';
    }
    if (key.startsWith('documents.')) return 'document';
    if (key.startsWith('tickets.') || key.startsWith('support.')) {
      return 'support_ticket';
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is FamilyNotificationTarget &&
      other.destination == destination &&
      other.id == id;

  @override
  int get hashCode => Object.hash(destination, id);

  @override
  String toString() => 'FamilyNotificationTarget($destination, $id)';
}
