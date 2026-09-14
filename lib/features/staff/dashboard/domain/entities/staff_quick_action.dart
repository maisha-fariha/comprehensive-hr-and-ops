import 'package:flutter/foundation.dart';

/// A single tile in the Staff Dashboard's "Quick Actions" list.
@immutable
class StaffQuickAction {
  final String id;
  final String asset;
  final String label;
  final String subtitle;
  final String trailing;

  const StaffQuickAction({
    required this.id,
    required this.asset,
    required this.label,
    this.subtitle = '',
    this.trailing = '',
  });
}
