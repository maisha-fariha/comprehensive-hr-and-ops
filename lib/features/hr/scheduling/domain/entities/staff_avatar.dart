import 'package:flutter/foundation.dart';

/// A single staff member's initials, shown inside a small circular avatar
/// in a facepile (Calendar/Board shift cards) or standalone (Requests
/// cards).
@immutable
class StaffAvatar {
  final String initials;

  const StaffAvatar(this.initials);
}
