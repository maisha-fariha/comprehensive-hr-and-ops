import 'package:flutter/foundation.dart';

/// The single "Recent Update" card shown on the Family Dashboard.
@immutable
class FamilyRecentUpdate {
  final String id;
  final String authorName;
  final String authorInitials;
  final String dateTimeLabel;
  final String statusLabel;
  final String body;
  final bool hasImage;

  const FamilyRecentUpdate({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.dateTimeLabel,
    required this.statusLabel,
    required this.body,
    this.hasImage = true,
  });
}
