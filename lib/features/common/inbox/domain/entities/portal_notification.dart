import 'package:flutter/foundation.dart';

@immutable
class PortalNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final bool isRead;
  final DateTime? createdAt;

  /// Web bell fields (`entityType`, `entityId`, `eventKey`, `eventLabel`, `metaJson`).
  final String? entityType;
  final String? entityId;
  final String? eventKey;
  final String? eventLabel;
  final Map<String, dynamic> meta;

  const PortalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.isRead = false,
    this.createdAt,
    this.entityType,
    this.entityId,
    this.eventKey,
    this.eventLabel,
    this.meta = const {},
  });

  PortalNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? timeLabel,
    bool? isRead,
    DateTime? createdAt,
    String? entityType,
    String? entityId,
    String? eventKey,
    String? eventLabel,
    Map<String, dynamic>? meta,
  }) {
    return PortalNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timeLabel: timeLabel ?? this.timeLabel,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      eventKey: eventKey ?? this.eventKey,
      eventLabel: eventLabel ?? this.eventLabel,
      meta: meta ?? this.meta,
    );
  }
}
