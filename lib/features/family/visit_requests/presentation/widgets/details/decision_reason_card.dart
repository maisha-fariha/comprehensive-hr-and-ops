import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/network/iso_date_range.dart';
import '../../../domain/entities/visit_request_detail.dart';

/// Shows why a visit/appointment request was rejected using
/// `decidedBy`, `decidedAt`, and `decisionReason`.
class DecisionReasonCard extends StatelessWidget {
  final VisitRequestDetail detail;

  static const Color _cardBorder = Color(0xFFF4D6D6);
  static const Color _cardFill = Color(0xFFFDF0F0);
  static const Color _shadow = Color(0xFF142846);
  static const Color _captionColor = Color(0xFFC62828);
  static const Color _valueColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF8A97A8);
  static const Color _divider = Color(0xFFF4D6D6);

  const DecisionReasonCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final reason = detail.decisionReason?.trim();
    final by = detail.decidedBy?.trim();
    final at = detail.decidedAt;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      decoration: BoxDecoration(
        color: _cardFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY THIS WAS REJECTED',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
              color: _captionColor,
              letterSpacing: 0.7,
              height: 1.2,
            ),
          ),
          if (reason != null && reason.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Text(
              reason,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: _valueColor,
                height: 1.45,
              ),
            ),
          ],
          if ((by != null && by.isNotEmpty) || at != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
              child: const Divider(height: 1, thickness: 1, color: _divider),
            ),
            Text(
              [
                if (by != null && by.isNotEmpty) by,
                if (at != null) IsoDateRange.dateTimeLabel(at),
              ].join(' · '),
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: _metaColor,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
