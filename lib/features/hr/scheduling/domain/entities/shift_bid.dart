import 'package:flutter/foundation.dart';

/// A staff bid on an open shift (`staff[].status == bid_pending`).
///
/// [bidId] is the assignment id passed to
/// `POST /shifts/{shiftId}/bids/{bidId}/accept`.
@immutable
class ShiftBid {
  final String bidId;
  final String staffId;
  final String staffName;
  final String note;

  const ShiftBid({
    required this.bidId,
    required this.staffId,
    required this.staffName,
    this.note = '',
  });
}
