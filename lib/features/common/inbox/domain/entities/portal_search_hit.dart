import 'package:flutter/foundation.dart';

enum PortalSearchHitType {
  client,
  staff,
  shift,
  incident,
  task,
  document,
  message,
  medication,
  attendance,
  unknown,
}

@immutable
class PortalSearchHit {
  final String id;
  final PortalSearchHitType type;
  final String title;
  final String subtitle;

  const PortalSearchHit({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });
}
