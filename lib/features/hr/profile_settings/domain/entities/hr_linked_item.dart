import 'package:flutter/foundation.dart';

@immutable
class HrLinkedItem {
  /// Residence id from `GET /residences` — required to open detail.
  final String id;
  final String initials;
  final String name;
  final String subtitle;
  final String statusLabel;

  const HrLinkedItem({
    this.id = '',
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.statusLabel,
  });
}
