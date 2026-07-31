import 'package:flutter/foundation.dart';

/// A resident/client linked to the family member's account, shown in the
/// "Linked Clients" section.
@immutable
class FamilyLinkedClient {
  final String initials;
  final String name;

  /// "Residence · Room number" subtext line.
  final String subtitle;
  final String statusLabel;

  const FamilyLinkedClient({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.statusLabel,
  });
}
