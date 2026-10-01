import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A queue tab and the query it sends (`status` or `type`).
class HrAppointmentTab {
  final String id;
  final String label;
  final String? status;
  final String? type;

  const HrAppointmentTab(this.id, this.label, {this.status, this.type});
}

/// Foreground / background pair for the web's badge variants.
class HrAppointmentTone {
  final Color foreground;
  final Color background;

  const HrAppointmentTone(this.foreground, this.background);

  static const warning = HrAppointmentTone(AppColors.urgentAmber, AppColors.urgentBackground);
  static const success = HrAppointmentTone(AppColors.activeGreen, AppColors.activeBackground);
  static const danger = HrAppointmentTone(AppColors.criticalRed, AppColors.criticalBackgroundSoft);
  static const info = HrAppointmentTone(AppColors.infoBlue, AppColors.infoBackground);
  static const neutral =
      HrAppointmentTone(AppColors.textSecondary, AppColors.filterButtonBackground);
  static const purple = HrAppointmentTone(Color(0xFF7656D6), Color(0xFFF1EAFE));
  static const secondary =
      HrAppointmentTone(AppColors.secondaryTeal, AppColors.quickActionCreateShiftBg);
}

abstract final class HrAppointmentsLabels {
  static const tabs = [
    HrAppointmentTab('pending', 'Pending', status: 'pending'),
    HrAppointmentTab('approved', 'Approved', status: 'approved'),
    HrAppointmentTab('family', 'Family visits', type: 'family_visit'),
    HrAppointmentTab('external', 'External', type: 'external'),
    HrAppointmentTab('closed', 'Rejected', status: 'rejected'),
    HrAppointmentTab('all', 'All'),
  ];

  static const statusOptions = [
    ('', 'Any status'),
    ('pending', 'Pending'),
    ('approved', 'Approved'),
    ('rejected', 'Rejected'),
    ('cancelled', 'Cancelled'),
    ('completed', 'Completed'),
  ];

  static const typeOptions = [
    ('', 'Any type'),
    ('family_visit', 'Family visit'),
    ('external', 'External'),
  ];

  /// The form's type choices.
  static const formTypes = [
    ('family_visit', 'Family visit'),
    ('external', 'External appointment'),
  ];

  static HrAppointmentTone statusTone(String status) => switch (status) {
        'pending' => HrAppointmentTone.warning,
        'approved' => HrAppointmentTone.success,
        'rejected' => HrAppointmentTone.danger,
        'completed' => HrAppointmentTone.info,
        _ => HrAppointmentTone.neutral,
      };

  static HrAppointmentTone typeTone(String type) =>
      type == 'family_visit' ? HrAppointmentTone.purple : HrAppointmentTone.info;

  static String formTypeLabel(String type) =>
      formTypes.firstWhere((t) => t.$1 == type, orElse: () => formTypes.first).$2;
}
