import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// The small "Only approved documents are shared." caption line shown
/// directly under the "Documents" title.
///
/// No existing SVG matches a shield-check glyph and the Figma
/// asset-download tool is unavailable this round (monthly quota exhausted),
/// so this uses Material `Icons.verified_user_rounded` as a temporary
/// stand-in — see the feature's implementation report.
class FamilyDocumentsCaption extends StatelessWidget {
  final String text;

  const FamilyDocumentsCaption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.secondaryTeal,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
