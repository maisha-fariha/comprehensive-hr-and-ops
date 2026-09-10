import 'package:flutter/foundation.dart';

import 'scheduling_enums.dart';

/// A single shift-swap request card on the Requests tab.
@immutable
class ShiftRequest {
  final String id;
  final String staffName;
  final String staffInitials;
  final RequestStatus status;

  /// e.g. "Requested 2h ago" or "Approved yesterday".
  final String timingLabel;

  /// e.g. "Tue May 13 · Morning" — the shift the requester wants to give up.
  final String givingLabel;

  /// e.g. "Wed May 14 · Morning" — the shift the requester wants instead.
  final String receivingLabel;

  /// Manager may call `POST /shift-swaps/:id/decide` only when the API status
  /// is `awaiting_manager`. `awaiting_peer` returns 409 until the colleague
  /// responds — those cards stay visible in Pending without Approve/Decline.
  final bool canManagerDecide;

  const ShiftRequest({
    required this.id,
    required this.staffName,
    required this.staffInitials,
    required this.status,
    required this.timingLabel,
    required this.givingLabel,
    required this.receivingLabel,
    this.canManagerDecide = false,
  });
}
