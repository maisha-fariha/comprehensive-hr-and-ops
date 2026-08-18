import 'package:flutter/foundation.dart';

/// The single "Next Appointment" card shown on the Family Dashboard.
@immutable
class FamilyNextAppointment {
  final String id;
  final String dateTimeLabel;
  final String title;
  final String location;
  final String statusLabel;

  const FamilyNextAppointment({
    required this.id,
    required this.dateTimeLabel,
    required this.title,
    required this.location,
    required this.statusLabel,
  });
}
