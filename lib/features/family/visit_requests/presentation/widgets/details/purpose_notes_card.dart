import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/surface_card.dart';
import '../../../domain/entities/visit_request_detail.dart';

/// "Purpose & Notes" card: a small all-caps "PURPOSE" caption + value, then
/// a "NOTES" caption + value.
class PurposeNotesCard extends StatelessWidget {
  final VisitRequestDetail detail;

  const PurposeNotesCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CaptionValue(caption: 'PURPOSE', value: detail.purpose),
          Padding(
            padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 14)),
            child: Divider(height: 1, color: AppColors.dividerLight),
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
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
            color: AppColors.textFaint,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: AppColors.textBody,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
