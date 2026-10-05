import 'package:flutter/foundation.dart';

/// One row in Evidence → Parties Notified (web create-incident parity).
@immutable
class IncidentPartyNotification {
  final String party;
  final bool notified;
  final String contactName;
  final String dateNotified;

  const IncidentPartyNotification({
    required this.party,
    this.notified = false,
    this.contactName = '',
    this.dateNotified = '',
  });

  IncidentPartyNotification copyWith({
    bool? notified,
    String? contactName,
    String? dateNotified,
  }) {
    return IncidentPartyNotification(
      party: party,
      notified: notified ?? this.notified,
      contactName: contactName ?? this.contactName,
      dateNotified: dateNotified ?? this.dateNotified,
    );
  }

  Map<String, dynamic> toJson() => {
        'party': party,
        'notified': notified,
        if (contactName.trim().isNotEmpty) 'contactName': contactName.trim(),
        if (dateNotified.trim().isNotEmpty) 'dateNotified': dateNotified.trim(),
      };
}
