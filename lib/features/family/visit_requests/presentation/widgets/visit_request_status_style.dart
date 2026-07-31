import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../../family_visit_requests_constants.dart';

/// Color + label treatment for a [VisitRequestStatus], shared by the
/// status pill on every list row/card and the small colored dot on "My
/// Requests" cards - so every screen in this feature stays visually
/// consistent with a single source of truth.
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
      color: AppColors.criticalRed,
      background: AppColors.criticalBackground,
    ),
    VisitRequestStatus.rescheduleRequested: VisitRequestStatusStyle(
      label: 'Reschedule Requested',
      color: AppColors.nightPurple,
      background: AppColors.nightBackground,
    ),
    VisitRequestStatus.completed: VisitRequestStatusStyle(
      label: 'Completed',
      color: FamilyVisitRequestsColors.neutralStatusForeground,
      background: FamilyVisitRequestsColors.neutralStatusBackground,
    ),
    VisitRequestStatus.cancelled: VisitRequestStatusStyle(
      label: 'Cancelled',
      color: FamilyVisitRequestsColors.neutralStatusForeground,
      background: FamilyVisitRequestsColors.neutralStatusBackground,
    ),
  };

  factory VisitRequestStatusStyle.of(VisitRequestStatus status) => _values[status]!;
}
