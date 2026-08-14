import 'package:flutter/foundation.dart';

@immutable
class StaffLinkedItem {
  final String initials;
  final String name;
  final String subtitle;
  final String statusLabel;

  const StaffLinkedItem({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.statusLabel,
  });
}
