import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../../family_visit_requests_constants.dart';

/// Small rounded "Visit"/"Appointment" tag pill shown on every request row/
/// card. The plain list rows show text only; the Request Details summary
/// card additionally shows a small leading icon (see [showIcon]).
///
/// Icon note: no "visit"/"appointment" glyphs exist in `assets/icons/*`
/// yet, so this uses Material `Icons.*` placeholders for the optional
/// leading icon.
class VisitRequestTypeTag extends StatelessWidget {
  final VisitRequestType type;
  final bool showIcon;

  const VisitRequestTypeTag({super.key, required this.type, this.showIcon = false});

  bool get _isVisit => type == VisitRequestType.visit;

  String get _label => _isVisit ? 'Visit' : 'Appointment';

  Color get _foreground => _isVisit ? AppColors.secondaryTeal : AppColors.infoBlue;

  Color get _background => _isVisit ? FamilyVisitRequestsColors.visitTagBackground : AppColors.infoBackground;

  IconData get _icon => _isVisit ? Icons.person_outline_rounded : Icons.event_note_outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 10, vertical: 5),
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
            Icon(_icon, size: ResponsiveHelper.getResponsiveSize(context, 14), color: _foreground),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
          ],
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: _foreground,
            ),
          ),
        ],
      ),
    );
  }
}
