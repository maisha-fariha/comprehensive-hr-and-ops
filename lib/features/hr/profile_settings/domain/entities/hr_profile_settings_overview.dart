import 'package:flutter/foundation.dart';

import 'hr_linked_item.dart';
import 'hr_preference_item.dart';
import 'hr_profile.dart';

@immutable
class HrProfileSettingsOverview {
  final HrProfile profile;
  final List<HrLinkedItem> linkedItems;
  final List<HrPreferenceItem> preferenceItems;
  final bool pushNotificationsEnabled;
  final bool darkModeEnabled;

  const HrProfileSettingsOverview({
    required this.profile,
    required this.linkedItems,
    required this.preferenceItems,
    required this.pushNotificationsEnabled,
    required this.darkModeEnabled,
  });
}
