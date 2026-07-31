import 'package:flutter/foundation.dart';

/// A single row in the Review tab's "Client Status Overview" card (shown
/// beneath the submitted-logs list). The reference screenshot cuts this
/// section off after its heading, so the row content here is a reasonable
/// placeholder consistent with the rest of the app's tone.
@immutable
class ClientStatusSummary {
  final String id;
  final String clientName;
  final String statusLabel;
  final bool isOnTrack;

  const ClientStatusSummary({
    required this.id,
    required this.clientName,
    required this.statusLabel,
    this.isOnTrack = true,
  });
}
