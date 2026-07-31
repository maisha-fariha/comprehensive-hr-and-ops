import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Full-width filled teal primary button, used for both the "+ Create
/// Incident" button pinned to the incidents list and the "Submit Incident"
/// button pinned to the bottom of the Create Incident form.
///
/// Icon note: the leading "+"/paper-plane glyphs have no matching SVG in
/// `assets/icons/*`, so this uses built-in Material icons as temporary
/// stand-ins (flagged in the feature's final report).
class StaffPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const StaffPrimaryButton({super.key, required this.label, required this.icon, required this.onTap});

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
                Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 20), color: Colors.white),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                Text(
                  label,
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
