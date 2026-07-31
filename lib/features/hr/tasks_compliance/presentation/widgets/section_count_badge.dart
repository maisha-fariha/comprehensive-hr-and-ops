import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Small circular blue count badge used next to a section title, e.g.
/// "Tasks Due (8)", "Compliance Checklist (4)", "Active Corrective Actions
/// (4)". Note the count may exceed the number of items actually rendered
/// below it - Figma shows only a short preview list under each of these
/// headings.
class SectionCountBadge extends StatelessWidget {
  final int count;

  const SectionCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 22);

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6),
      decoration: const BoxDecoration(color: AppColors.infoBackground, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          color: AppColors.infoBlue,
          height: 1,
        ),
      ),
    );
  }
}
