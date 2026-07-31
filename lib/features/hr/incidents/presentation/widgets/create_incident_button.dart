import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Full-width filled teal "+ Create Incident" button pinned near the bottom
/// of every Incidents list tab (Open/Under Review/Closed all share it).
///
/// Icon note: the leading "+" has no matching SVG in `assets/icons/*`, so
/// this uses the built-in Material `Icons.add` as a temporary stand-in.
class CreateIncidentButton extends StatelessWidget {
  final VoidCallback onTap;

  const CreateIncidentButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.secondaryTeal,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: ResponsiveHelper.getResponsiveSize(context, 20), color: Colors.white),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                Text(
                  'Create Incident',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
