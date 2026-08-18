import 'package:flutter/foundation.dart';

/// A single tile in the Family Dashboard "Today at a Glance" 2×2 grid.
@immutable
class FamilyGlanceItem {
  final String id;
  final String label;
  final String value;

  const FamilyGlanceItem({
    required this.id,
    required this.label,
    required this.value,
  });
}
