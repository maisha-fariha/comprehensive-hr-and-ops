import 'package:flutter/foundation.dart';

enum FamilySearchHitType { dailyLog, appointment, message, document, unknown }

@immutable
class FamilySearchHit {
  final String id;
  final FamilySearchHitType type;
  final String title;
  final String subtitle;

  const FamilySearchHit({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });
}
