import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// A small teal trailing text link with an optional leading icon, used for
/// section-header actions whose label isn't the standard "View all" (which
/// already has a dedicated [ViewAllLink] in `core/widgets`) - e.g. "Filter"
/// and "Mark all read".
class TeamReportsTextLink extends StatelessWidget {
  final String label;
  final String? asset;
  final VoidCallback? onTap;

  const TeamReportsTextLink({super.key, required this.label, this.asset, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null) ...[
            AppSvgIcon(asset!, size: 12, color: AppColors.secondaryTeal),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.secondaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}
