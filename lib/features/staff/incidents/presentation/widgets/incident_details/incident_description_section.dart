import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import 'section_label.dart';

/// "DESCRIPTION" section on Incident Details: narrative paragraphs plus a
/// left-accent care-recommendation callout.
///
/// Copy matches the Figma details reference (not yet on [IncidentDetail]).
class IncidentDescriptionSection extends StatelessWidget {
  static const String _paragraph1 =
      'Resident became verbally agitated during the evening group activity, '
      'raising his voice and using aggressive language toward another resident '
      'seated nearby.';

  static const String _paragraph2 =
      'Staff intervened immediately, separated the residents, and guided '
      'Michael T. to a quieter area. He was de-escalated within approximately '
      'ten minutes with no physical contact and no injuries to any party.';

  static const String _calloutMessage =
  '⚠ Second behavioral episode this week — recommend care plan and medication review by nursing team.';

  static const Color _bodyColor = Color(0xFF374151);
  static const Color _calloutBackground = Color(0xFFFFF8F1);
  static const Color _calloutAccent = Color(0xFFE68A2E);
  static const Color _calloutText = Color(0xFF70511C);

  const IncidentDescriptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('DESCRIPTION'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.04),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _paragraph1,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: _bodyColor,
                  height: 1.55,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
              Text(
                _paragraph2,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: _bodyColor,
                  height: 1.55,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
              const _DescriptionCallout(message: _calloutMessage),
            ],
          ),
        ),
      ],
    );
  }
}

class _DescriptionCallout extends StatelessWidget {
  final String message;

  const _DescriptionCallout({required this.message});

  @override
  Widget build(BuildContext context) {
    final accentWidth = ResponsiveHelper.getResponsiveWidth(context, 5);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: IncidentDescriptionSection._calloutBackground,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: accentWidth,
                color: IncidentDescriptionSection._calloutAccent,
              ),
              Expanded(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    left: 14,
                    right: 16,
                    top: 14,
                    bottom: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                            color: IncidentDescriptionSection._calloutText,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
