import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../domain/entities/visit_request_detail.dart';

/// "Purpose & Notes" card: uppercase captions with purpose and notes values.
class PurposeNotesCard extends StatelessWidget {
  final VisitRequestDetail detail;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
  static const Color _captionColor = Color(0xFF6B7A8D);
  static const Color _valueColor = Color(0xFF1A2B48);
  static const Color _divider = Color(0xFFE2E8F0);

  const PurposeNotesCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.06),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CaptionValue(caption: 'PURPOSE', value: detail.purpose),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveHeight(context, 16),
            ),
            child: const Divider(height: 1, thickness: 1, color: _divider),
          ),
          _CaptionValue(caption: 'NOTES', value: detail.notes),
        ],
      ),
    );
  }
}

class _CaptionValue extends StatelessWidget {
  final String caption;
  final String value;

  const _CaptionValue({required this.caption, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
            color: PurposeNotesCard._captionColor,
            letterSpacing: 0.7,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            color: PurposeNotesCard._valueColor,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
