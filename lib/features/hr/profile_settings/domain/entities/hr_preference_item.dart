import 'package:flutter/foundation.dart';

enum HrPreferenceType {
  notifications,
  changePassword,
  helpCenter,
  contactSupport,
  privacySecurity,
}

@immutable
class HrPreferenceItem {
  final HrPreferenceType type;
  final String label;

  const HrPreferenceItem({required this.type, required this.label});
}
