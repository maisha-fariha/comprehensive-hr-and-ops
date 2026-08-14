import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../family_visit_requests_constants.dart';

/// Icon-box + label/value row used by both the "Request Summary" and
/// "Patient & Family Information" cards on the Request Details screen: a
/// small light-teal rounded icon box on the left, and a small grey caption
/// above a bold value on the right.
class VisitRequestInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const VisitRequestInfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final boxSize = ResponsiveHelper.getResponsiveSize(context, 38);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: FamilyVisitRequestsColors.visitTagBackground,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 11),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 18), color: AppColors.secondaryTeal),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textFaint,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
