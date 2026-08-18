import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_visit_requests_enums.dart';

/// Color + label treatment for a [VisitRequestStatus], shared across Visit
/// Requests list/cards so every screen stays visually consistent.
class VisitRequestStatusStyle {
  final String label;
  final Color color;
  final Color background;

  const VisitRequestStatusStyle({
    required this.label,
    required this.color,
    required this.background,
  });

  static const Map<VisitRequestStatus, VisitRequestStatusStyle> _values = {
    VisitRequestStatus.pending: VisitRequestStatusStyle(
      label: 'Pending',
      color: AppColors.urgentAmber,
      background: AppColors.urgentBackground,
    ),
    VisitRequestStatus.approved: VisitRequestStatusStyle(
      label: 'Approved',
      color: AppColors.activeGreen,
      background: AppColors.activeBackground,
    ),
    VisitRequestStatus.rejected: VisitRequestStatusStyle(
      label: 'Rejected',
      color: Color(0xFFB91C1C),
      background: Color(0xFFFBE9E9),
    ),
    VisitRequestStatus.rescheduleRequested: VisitRequestStatusStyle(
      label: 'Reschedule Requested',
      color: AppColors.nightPurple,
      background: AppColors.nightBackground,
    ),
    VisitRequestStatus.completed: VisitRequestStatusStyle(
      label: 'Completed',
      color: Color(0xFF64748B),
      background: Color(0xFFF1F5F9),
    ),
    VisitRequestStatus.cancelled: VisitRequestStatusStyle(
      label: 'Cancelled',
      color: Color(0xFF64748B),
      background: Color(0xFFF1F5F9),
    ),
  };

  factory VisitRequestStatusStyle.of(VisitRequestStatus status) =>
      _values[status]!;
}
