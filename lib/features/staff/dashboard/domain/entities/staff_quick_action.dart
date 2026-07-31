import 'package:flutter/foundation.dart';

/// A single tile in the Staff Dashboard's "Quick Actions" row.
///
/// The reference screenshot cuts this row off before it's fully visible, so
/// its icon asset is stored directly on the entity (rather than mapped from
/// an enum, as the HR Dashboard's `QuickAction` does) since there's no
/// design-confirmed fixed set of action types yet.
@immutable
class StaffQuickAction {
  final String id;
  final String asset;
  final String label;

  const StaffQuickAction({required this.id, required this.asset, required this.label});
}
