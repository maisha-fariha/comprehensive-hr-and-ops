import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Full-width filled teal primary button, used for both the "+ Create
/// Appointment" button pinned to the Appointments list and the "Submit
/// Request" button pinned to the bottom of the Create Appointment form.
///
/// Icon note: the leading "+"/paper-plane glyphs have no matching SVG in
/// `assets/icons/*`, so this uses built-in Material icons as temporary
/// stand-ins, matching the pattern already used by the Staff Incidents
/// feature's `StaffPrimaryButton`.
class FamilyPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const FamilyPrimaryButton({super.key, required this.label,  this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        elevation: 4,
        color: AppColors.secondaryTeal,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        shadowColor: AppColors.shadowNavy.withValues(alpha: 0.22),
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
                    fontFamily: 'Manrope',
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
