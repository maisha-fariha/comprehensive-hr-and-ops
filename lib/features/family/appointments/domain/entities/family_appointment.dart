import 'package:flutter/foundation.dart';

import 'family_appointments_enums.dart';

/// A single row shown on the Family Appointments list, across all 3 tabs
/// ("All", "Upcoming", "Completed").
///
/// The same underlying appointments back both the "All" and "Upcoming"
/// tabs in the Figma screenshots (identical rows/grouping in both), while
/// the "Completed" tab shows a disjoint set of past appointments - the
/// presentation layer filters/groups this flat list by [status] and
/// [iconKind] rather than the model itself owning a "tab"/"section" field.
@immutable
class FamilyAppointment {
  final String id;
  final String dateTimeLabel;
  final FamilyAppointmentStatus status;
  final String title;
  final String location;
  final FamilyAppointmentIconKind iconKind;
  final String type;
  final DateTime? scheduledAt;
  final String? notes;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionReason;

  const FamilyAppointment({
    required this.id,
    required this.dateTimeLabel,
    required this.status,
    required this.title,
    required this.location,
    required this.iconKind,
    this.type = '',
    this.scheduledAt,
    this.notes,
    this.decidedBy,
    this.decidedAt,
    this.decisionReason,
  });

  /// True when care staff rejected the request and left a decision trail.
  bool get hasRejectionDecision =>
      status == FamilyAppointmentStatus.rejected &&
      ((decisionReason != null && decisionReason!.trim().isNotEmpty) ||
          (decidedBy != null && decidedBy!.trim().isNotEmpty) ||
          decidedAt != null);

  String get rejectionSummary {
    final parts = <String>[];
    final reason = decisionReason?.trim();
    if (reason != null && reason.isNotEmpty) parts.add(reason);
    final by = decidedBy?.trim();
    final at = decidedAt;
    if (by != null && by.isNotEmpty && at != null) {
      parts.add('— $by · ${_shortDecisionTime(at)}');
    } else if (by != null && by.isNotEmpty) {
      parts.add('— $by');
    } else if (at != null) {
      parts.add('— ${_shortDecisionTime(at)}');
    }
    return parts.join(' ');
  }

  static String _shortDecisionTime(DateTime value) {
    final d = value.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $hour:$minute';
  }
}
