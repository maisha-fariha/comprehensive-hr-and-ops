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

  const FamilyAppointment({
    required this.id,
    required this.dateTimeLabel,
    required this.status,
    required this.title,
    required this.location,
    required this.iconKind,
    this.type = '',
    this.scheduledAt,
  });
}
