import 'package:flutter/foundation.dart';

@immutable
class FamilyNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final bool isRead;

  const FamilyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.isRead = false,
  });
}
