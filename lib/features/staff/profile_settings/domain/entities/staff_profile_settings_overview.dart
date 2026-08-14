import 'package:flutter/foundation.dart';

import 'staff_linked_item.dart';
import 'staff_preference_item.dart';
import 'staff_profile.dart';

@immutable
class StaffProfileSettingsOverview {
  final StaffProfile profile;
  final List<StaffLinkedItem> linkedItems;
  final List<StaffPreferenceItem> preferenceItems;
  final bool pushNotificationsEnabled;
  final bool darkModeEnabled;

  const StaffProfileSettingsOverview({
    required this.profile,
    required this.linkedItems,
    required this.preferenceItems,
    required this.pushNotificationsEnabled,
    required this.darkModeEnabled,
  });
}
