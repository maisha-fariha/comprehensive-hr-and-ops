import 'package:flutter/foundation.dart';

/// A staff-side shift-swap / cover / handover request.
@immutable
class StaffShiftSwap {
  final String id;
  final String kindLabel;
  final String statusLabel;
  final String fromShiftLabel;
  final String? toShiftLabel;
  final String counterpartName;
  final String? note;
  final bool isIncoming;
  final bool canRespond;
  final bool canCancel;

  const StaffShiftSwap({
    required this.id,
    required this.kindLabel,
    required this.statusLabel,
    required this.fromShiftLabel,
    this.toShiftLabel,
    required this.counterpartName,
    this.note,
    required this.isIncoming,
    required this.canRespond,
    required this.canCancel,
  });
}
