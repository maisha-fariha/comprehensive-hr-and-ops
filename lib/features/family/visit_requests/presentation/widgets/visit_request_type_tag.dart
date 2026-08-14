import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_visit_requests_enums.dart';

/// Small rounded "Visit" / "Appointment" type pill on request rows and cards.
class VisitRequestTypeTag extends StatelessWidget {
  final VisitRequestType type;
  final bool showIcon;

  static const Color _visitFg = Color(0xFF0E7C7B);
  static const Color _visitBg = Color(0xFFE6F4F1);
  static const Color _appointmentFg = Color(0xFF2A5DA6);
  static const Color _appointmentBg = Color(0xFFEAF0F9);

  const VisitRequestTypeTag({
    super.key,
    required this.type,
    this.showIcon = false,
  });

  bool get _isVisit => type == VisitRequestType.visit;

  String get _label => _isVisit ? 'Visit' : 'Appointment';

  Color get _foreground => _isVisit ? _visitFg : _appointmentFg;

  Color get _background => _isVisit ? _visitBg : _appointmentBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _isVisit ? Icons.person_outline_rounded : Icons.event_note_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 14),
              color: _foreground,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
          ],
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: _foreground,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
