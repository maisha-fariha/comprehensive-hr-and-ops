import 'package:flutter/foundation.dart';

/// A single staff member's initials, shown inside a small circular avatar
/// in a shift card's facepile.
@immutable
class ShiftAvatar {
  final String initials;

  const ShiftAvatar(this.initials);
}
