import 'package:flutter/foundation.dart';

/// A single tile in the Family Dashboard "Quick Actions" row.
@immutable
class FamilyQuickAction {
  final String id;
  final String label;
  final String asset;

  const FamilyQuickAction({
    required this.id,
    required this.label,
    required this.asset,
  });
}
