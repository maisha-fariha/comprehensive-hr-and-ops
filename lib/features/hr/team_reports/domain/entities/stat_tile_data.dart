import 'package:flutter/foundation.dart';

/// A single small "icon + value + label" tile shown in the compact stat rows
/// at the top of the Team, Reports and Messages tabs. Generic over the
/// tag enum so each tab can drive its own icon/color styling in the
/// presentation layer while sharing one entity shape.
@immutable
class StatTileData<T> {
  final String id;
  final T tag;
  final String value;
  final String label;

  const StatTileData({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
  });
}
