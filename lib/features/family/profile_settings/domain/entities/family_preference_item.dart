import 'package:flutter/foundation.dart';

/// Which "Preferences & Support" row a [FamilyPreferenceItem] represents —
/// drives the icon/tint used in the presentation layer.
enum FamilyPreferenceType {
  notifications,
  changePassword,
  helpCenter,
  contactSupport,
  privacySecurity,
}

/// A single row in the "Preferences & Support" section: icon + label +
/// chevron, no subtitle.
@immutable
class FamilyPreferenceItem {
  final FamilyPreferenceType type;
  final String label;

  const FamilyPreferenceItem({required this.type, required this.label});
}
