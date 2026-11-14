import 'package:flutter/foundation.dart';

/// One row in Overview "Shared Activities" (from `/family/clients/:id/activities`).
@immutable
class FamilySharedActivity {
  final String id;
  final String title;
  final String description;
  final String dateLabel;
  final String activityType;
  final List<String> mediaUrls;

  const FamilySharedActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.dateLabel,
    this.activityType = '',
    this.mediaUrls = const [],
  });

  bool get isFamilyMemory =>
      activityType.toLowerCase().contains('memory') ||
      title.toLowerCase().contains('memory');
}
