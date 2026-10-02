import 'package:flutter/foundation.dart';

@immutable
class FamilyNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final bool isRead;

  /// Target hints from `GET /notifications` used to route a tap, e.g.
  /// `entityType: appointment`, `eventKey: appointments.decided`,
  /// `metaJson: {appointmentId: ...}`.
  final String? entityType;
  final String? entityId;
  final String? eventKey;
  final Map<String, dynamic> meta;

  const FamilyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.isRead = false,
    this.entityType,
    this.entityId,
    this.eventKey,
    this.meta = const {},
  });

  FamilyNotification copyWith({bool? isRead}) {
    return FamilyNotification(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      isRead: isRead ?? this.isRead,
      entityType: entityType,
      entityId: entityId,
      eventKey: eventKey,
      meta: meta,
    );
  }
}
