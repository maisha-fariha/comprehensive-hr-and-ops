import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_appointments_enums.dart';

/// Resolved (label, background, foreground) triple for a Family
/// Appointment card's trailing status pill, rendered with `StatusBadge.pill`.
@immutable
class FamilyAppointmentStatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  const FamilyAppointmentStatusStyle({required this.label, required this.background, required this.foreground});

  factory FamilyAppointmentStatusStyle.of(FamilyAppointmentStatus status) {
    switch (status) {
      case FamilyAppointmentStatus.upcoming:
        return const FamilyAppointmentStatusStyle(
          label: 'Upcoming',
          background: AppColors.infoBackground,
          foreground: AppColors.infoBlue,
        );
      case FamilyAppointmentStatus.pending:
        return const FamilyAppointmentStatusStyle(
          label: 'Pending',
          background: AppColors.urgentBackground,
          foreground: AppColors.urgentAmber,
        );
      case FamilyAppointmentStatus.approved:
        return const FamilyAppointmentStatusStyle(
          label: 'Approved',
          background: AppColors.activeBackground,
          foreground: AppColors.activeGreen,
        );
      case FamilyAppointmentStatus.completed:
        return const FamilyAppointmentStatusStyle(
          label: 'Completed',
          background: AppColors.dividerLight,
          foreground: AppColors.textSecondary,
        );
      case FamilyAppointmentStatus.rejected:
        return const FamilyAppointmentStatusStyle(
          label: 'Rejected',
          background: AppColors.urgentBackground,
          foreground: AppColors.criticalRed,
        );
      case FamilyAppointmentStatus.cancelled:
        return const FamilyAppointmentStatusStyle(
          label: 'Cancelled',
          background: AppColors.dividerLight,
          foreground: AppColors.textSecondary,
        );
    }
  }
}
