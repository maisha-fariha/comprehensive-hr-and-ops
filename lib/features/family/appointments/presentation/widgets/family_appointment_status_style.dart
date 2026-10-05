import 'package:flutter/material.dart';

import '../../domain/entities/family_appointments_enums.dart';

/// Status pill colours for a Family appointment card, matching the web
/// Family Portal badge variants (pending/rescheduled = warning, approved =
/// success, rejected = danger, cancelled = neutral, completed = info).
@immutable
class FamilyAppointmentStatusStyle {
  final Color background;
  final Color foreground;

  const FamilyAppointmentStatusStyle({required this.background, required this.foreground});

  static const FamilyAppointmentStatusStyle _warning = FamilyAppointmentStatusStyle(
    background: Color(0xFFFFF7E8),
    foreground: Color(0xFFE9A23B),
  );
  static const FamilyAppointmentStatusStyle _success = FamilyAppointmentStatusStyle(
    background: Color(0xFFE9F5EE),
    foreground: Color(0xFF3FA66D),
  );
  static const FamilyAppointmentStatusStyle _danger = FamilyAppointmentStatusStyle(
    background: Color(0xFFFBEAEA),
    foreground: Color(0xFFD64545),
  );
  static const FamilyAppointmentStatusStyle _info = FamilyAppointmentStatusStyle(
    background: Color(0xFFEEF3F8),
    foreground: Color(0xFF61758D),
  );
  static const FamilyAppointmentStatusStyle _neutral = FamilyAppointmentStatusStyle(
    background: Color(0xFFF4F5F7),
    foreground: Color(0xFF5A6B80),
  );

  factory FamilyAppointmentStatusStyle.of(FamilyAppointmentStatus status) {
    switch (status) {
      case FamilyAppointmentStatus.pending:
      case FamilyAppointmentStatus.rescheduleRequested:
        return _warning;
      case FamilyAppointmentStatus.approved:
        return _success;
      case FamilyAppointmentStatus.rejected:
        return _danger;
      case FamilyAppointmentStatus.completed:
        return _info;
      case FamilyAppointmentStatus.cancelled:
      case FamilyAppointmentStatus.other:
        return _neutral;
    }
  }
}
