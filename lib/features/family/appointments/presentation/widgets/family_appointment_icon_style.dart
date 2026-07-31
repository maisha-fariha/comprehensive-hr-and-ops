import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';

/// Resolved (background, icon color, glyph) triple for a single
/// Family Appointment card's leading icon box.
///
/// Icon note: none of "medical cross" / "tooth" / "physiotherapy figure" /
/// "two people" have a matching SVG in `assets/icons/*` yet, so this uses
/// built-in Material icons as temporary stand-ins (flagged in the feature's
/// final report).
@immutable
class FamilyAppointmentIconStyle {
  final Color background;
  final Color color;
  final IconData icon;

  const FamilyAppointmentIconStyle({required this.background, required this.color, required this.icon});

  /// Resolves the style for [appointment] - completed appointments always
  /// render with a single muted grey style regardless of [FamilyAppointment.iconKind],
  /// matching the Figma "Completed - Appointments" screenshot; every other
  /// appointment is styled by its [FamilyAppointmentIconKind].
  factory FamilyAppointmentIconStyle.of(FamilyAppointment appointment) {
    final icon = _iconFor(appointment.iconKind);

    if (appointment.status == FamilyAppointmentStatus.completed) {
      return FamilyAppointmentIconStyle(background: AppColors.dividerLight, color: AppColors.textSecondary, icon: icon);
    }

    switch (appointment.iconKind) {
      case FamilyAppointmentIconKind.dental:
        return FamilyAppointmentIconStyle(background: AppColors.infoBackground, color: AppColors.infoBlue, icon: icon);
      case FamilyAppointmentIconKind.medical:
      case FamilyAppointmentIconKind.physiotherapy:
      case FamilyAppointmentIconKind.familyVisit:
        return FamilyAppointmentIconStyle(background: AppColors.activeBackground, color: AppColors.activeGreen, icon: icon);
    }
  }

  static IconData _iconFor(FamilyAppointmentIconKind kind) {
    switch (kind) {
      case FamilyAppointmentIconKind.medical:
        return Icons.add_rounded;
      case FamilyAppointmentIconKind.dental:
        return Icons.medical_services_outlined;
      case FamilyAppointmentIconKind.physiotherapy:
        return Icons.accessibility_new_rounded;
      case FamilyAppointmentIconKind.familyVisit:
        return Icons.people_alt_outlined;
    }
  }
}
