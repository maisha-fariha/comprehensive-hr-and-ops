import 'package:flutter/foundation.dart';

import 'family_linked_client.dart';
import 'family_preference_item.dart';
import 'family_profile.dart';

/// Aggregate root for everything shown on the "Profile & Settings" screen.
///
/// The "App Settings" toggle defaults ([pushNotificationsEnabled] /
/// [darkModeEnabled]) are the one piece of content not visible in the
/// reference screenshot (the section header is visible but its rows are
/// cropped) — a minimal, plausible completion per the feature brief.
@immutable
class FamilyProfileSettingsOverview {
  final FamilyProfile profile;
  final List<FamilyLinkedClient> linkedClients;
  final List<FamilyPreferenceItem> preferenceItems;
  final bool pushNotificationsEnabled;
  final bool darkModeEnabled;

  const FamilyProfileSettingsOverview({
    required this.profile,
    required this.linkedClients,
    required this.preferenceItems,
    required this.pushNotificationsEnabled,
    required this.darkModeEnabled,
  });
}
