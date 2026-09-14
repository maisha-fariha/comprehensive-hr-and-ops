import 'package:flutter/foundation.dart';

/// An upcoming appointment shown on Staff Schedule (nurse / caregiver).
@immutable
class StaffAppointment {
  final String id;
  final String title;
  final String dateTimeLabel;
  final String location;
  final String statusLabel;

  const StaffAppointment({
    required this.id,
    required this.title,
    required this.dateTimeLabel,
    required this.location,
    required this.statusLabel,
  });
}
