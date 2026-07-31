import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// The soft-tinted "Reason: ..." / "Notes: ..." caption box shown below a
/// Missed/Refused dose card's status row.
class DoseNoteBox extends StatelessWidget {
  final String label;
  final String text;
  final Color background;

  const DoseNoteBox({super.key, required this.label, required this.text, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
