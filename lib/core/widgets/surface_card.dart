import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../constants/app_colors.dart';

/// White, bordered, drop-shadowed surface used for every card on the
/// dashboard (Needs Attention, overview stats, schedule, quick actions).
/// The two shadow/radius combinations seen in the Figma design are exposed
/// via named constructors so every card stays pixel-accurate without
/// duplicating `BoxDecoration` boilerplate at each call site.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final List<BoxShadow> Function(BuildContext context) shadowBuilder;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    required this.radius,
    required this.shadowBuilder,
  });

  factory SurfaceCard.card({
    Key? key,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return SurfaceCard(
      key: key,
      radius: 18,
      padding: padding,
      shadowBuilder: (context) => [
        BoxShadow(
          color: AppColors.shadowNavy.withValues(alpha: 0.04),
          offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
          blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
        ),
        BoxShadow(
          color: AppColors.shadowNavy.withValues(alpha: 0.04),
          offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
          blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
        ),
      ],
      child: child,
    );
  }

  factory SurfaceCard.button({
    Key? key,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return SurfaceCard(
      key: key,
      radius: 16,
      padding: padding,
      shadowBuilder: (context) => [
        BoxShadow(
          color: AppColors.shadowNavy.withValues(alpha: 0.04),
          offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
          blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
        ),
        BoxShadow(
          color: AppColors.shadowNavy.withValues(alpha: 0.03),
          offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
          blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
        ),
      ],
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, radius),
        ),
        boxShadow: shadowBuilder(context),
      ),
      child: child,
    );
  }
}
