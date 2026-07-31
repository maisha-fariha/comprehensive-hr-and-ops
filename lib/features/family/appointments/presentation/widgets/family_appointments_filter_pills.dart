import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// The "Date range" / "All types" filter pill row shown below the tab bar
/// on the Family Appointments list screen.
///
/// These are display-only mock filters (no backing filter logic exists
/// yet), matching the current scope of the feature - front-end only, no
/// real data filtering, in line with the analogous dropdown fields on the
/// Staff Incidents "Create Incident" form.
class FamilyAppointmentsFilterPills extends StatelessWidget {
  const FamilyAppointmentsFilterPills({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _FilterPill(label: 'Date range', leadingIcon: AppAssets.navCalendar)),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        const Expanded(child: _FilterPill(label: 'All types')),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final String? leadingIcon;

  const _FilterPill({required this.label, this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            AppSvgIcon(leadingIcon!, size: 15, color: AppColors.textSecondary),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textBody,
              ),
            ),
          ),
          const AppSvgIcon(AppAssets.chevronDown, size: 14, color: AppColors.textFaint),
        ],
      ),
    );
  }
}
