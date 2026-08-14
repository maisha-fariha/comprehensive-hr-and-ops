import 'package:flutter/foundation.dart';

@immutable
class HrLinkedItem {
  final String initials;
  final String name;
  final String subtitle;
  final String statusLabel;

  const HrLinkedItem({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.statusLabel,
  });
}
