import 'package:flutter/foundation.dart';

import 'family_appointments_enums.dart';

/// A single row shown on the Family Visits & Appointments list. The
/// presentation layer splits this flat list into "Upcoming Visits" /
/// "Past Visits" with [isPastAt].
@immutable
class FamilyAppointment {
  final String id;
  final String dateTimeLabel;
  final FamilyAppointmentStatus status;

  /// Pill text: the raw API status humanised exactly like the web
  /// (`pending` -> "Pending", `cancelled` -> "Cancelled").
  final String statusLabel;
  final String title;
  final String location;
  final FamilyAppointmentIconKind iconKind;
  final String type;
  final DateTime? scheduledAt;
  final String clientName;
  final String? notes;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionReason;

  const FamilyAppointment({
    required this.id,
    required this.dateTimeLabel,
    required this.status,
    required this.statusLabel,
    required this.title,
    required this.location,
    required this.iconKind,
    this.type = '',
    this.scheduledAt,
    this.clientName = '',
    this.notes,
    this.decidedBy,
    this.decidedAt,
    this.decisionReason,
  });

  /// Web `/family/appointments` "Past Visits" rule: closed statuses, or a
  /// slot that started more than 2 hours before [now].
  bool isPastAt(DateTime now) {
    switch (status) {
      case FamilyAppointmentStatus.completed:
      case FamilyAppointmentStatus.cancelled:
      case FamilyAppointmentStatus.rejected:
        return true;
      case FamilyAppointmentStatus.pending:
      case FamilyAppointmentStatus.approved:
      case FamilyAppointmentStatus.rescheduleRequested:
      case FamilyAppointmentStatus.other:
        final at = scheduledAt;
        if (at == null) return false;
        return at.isBefore(now.subtract(const Duration(hours: 2)));
    }
  }

  /// One-line status explanation shown under each web visit card.
  String? get statusDescription {
    switch (status) {
      case FamilyAppointmentStatus.pending:
        return 'Waiting for the care home to confirm your slot.';
      case FamilyAppointmentStatus.approved:
        return 'Confirmed by care home — see you then!';
      case FamilyAppointmentStatus.rejected:
        return 'The care home could not accommodate this specific time.';
      case FamilyAppointmentStatus.cancelled:
        return 'This visit was withdrawn.';
      case FamilyAppointmentStatus.completed:
        return 'Visit completed.';
      case FamilyAppointmentStatus.rescheduleRequested:
        return 'The care home proposed a new time for your review.';
      case FamilyAppointmentStatus.other:
        return null;
    }
  }

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
