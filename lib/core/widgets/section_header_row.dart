import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Reusable "title + trailing" row used for every card/section heading on
/// the dashboard ("Today's Overview", "Today's Schedule", "Quick Actions",
/// "Needs Attention"). The trailing slot is intentionally generic so callers
/// can plug in a "View all" link, a timestamp label, or nothing at all.
class SectionHeaderRow extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeaderRow({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// The teal "View all" text link used in card headers.
class ViewAllLink extends StatelessWidget {
  final VoidCallback? onTap;

  const ViewAllLink({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        'View all',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
          color: AppColors.secondaryTeal,
        ),
      ),
    );
  }
}
