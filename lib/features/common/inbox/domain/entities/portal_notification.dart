import 'package:flutter/foundation.dart';

@immutable
class PortalNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final bool isRead;

  const PortalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.isRead = false,
  });

  PortalNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? timeLabel,
    bool? isRead,
  }) {
    return PortalNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timeLabel: timeLabel ?? this.timeLabel,
      isRead: isRead ?? this.isRead,
    );
  }
}
