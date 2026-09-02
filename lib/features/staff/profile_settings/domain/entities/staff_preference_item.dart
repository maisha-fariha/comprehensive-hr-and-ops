import 'package:flutter/foundation.dart';

enum StaffPreferenceType {
  notifications,
  changePassword,
  helpCenter,
  contactSupport,
  privacySecurity,
}

@immutable
class StaffPreferenceItem {
  final StaffPreferenceType type;
  final String label;

  const StaffPreferenceItem({required this.type, required this.label});
}
