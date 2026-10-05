import 'package:flutter/material.dart';

import '../../domain/entities/family_visit_requests_enums.dart';

/// Color + label treatment for a [VisitRequestStatus], shared across Visit
/// Requests list/cards. Colours are the web badge variants (pending /
/// rescheduled = warning, approved = success, rejected = danger, cancelled =
/// neutral, completed = info).
class VisitRequestStatusStyle {
  final String label;
  final Color color;
  final Color background;

  const VisitRequestStatusStyle({
    required this.label,
    required this.color,
    required this.background,
  });

  static const Color _warningFg = Color(0xFFE9A23B);
  static const Color _warningBg = Color(0xFFFFF7E8);

  static const Map<VisitRequestStatus, VisitRequestStatusStyle> _values = {
    VisitRequestStatus.pending: VisitRequestStatusStyle(
      label: 'Pending',
      color: _warningFg,
      background: _warningBg,
    ),
    VisitRequestStatus.approved: VisitRequestStatusStyle(
      label: 'Approved',
      color: Color(0xFF3FA66D),
      background: Color(0xFFE9F5EE),
    ),
    VisitRequestStatus.rejected: VisitRequestStatusStyle(
      label: 'Rejected',
      color: Color(0xFFD64545),
      background: Color(0xFFFBEAEA),
    ),
    VisitRequestStatus.rescheduleRequested: VisitRequestStatusStyle(
      label: 'Rescheduled',
      color: _warningFg,
      background: _warningBg,
    ),
    VisitRequestStatus.completed: VisitRequestStatusStyle(
      label: 'Completed',
      color: Color(0xFF61758D),
      background: Color(0xFFEEF3F8),
    ),
    VisitRequestStatus.cancelled: VisitRequestStatusStyle(
      label: 'Cancelled',
      color: Color(0xFF5A6B80),
      background: Color(0xFFF4F5F7),
    ),
    VisitRequestStatus.other: VisitRequestStatusStyle(
      label: '—',
      color: Color(0xFF5A6B80),
      background: Color(0xFFF4F5F7),
    ),
  };

  factory VisitRequestStatusStyle.of(VisitRequestStatus status) =>
      _values[status]!;
}
