import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Shared auth header shell matching the login top portion:
/// navy→teal gradient, two light-opacity circle containers, bottom-left /
/// bottom-right radius, and a soft shadow so it can overlap the section below.
class AuthCurvedHeader extends StatelessWidget {
  final Widget child;
  final double bottomPadding;
  final double bottomRadius;

  const AuthCurvedHeader({
    super.key,
    required this.child,
    required this.bottomPadding,
    required this.bottomRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.60, 1.0],
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF16293F),
            Color(0xFF0E7C7B),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1A2F).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -ResponsiveHelper.getResponsiveHeight(context, 100),
            right: -ResponsiveHelper.getResponsiveWidth(context, 100),
            child: Container(
              width: ResponsiveHelper.getResponsiveSize(context, 230),
              height: ResponsiveHelper.getResponsiveSize(context, 230),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -ResponsiveHelper.getResponsiveHeight(context, 90),
            left: -ResponsiveHelper.getResponsiveWidth(context, 50),
            child: Container(
              width: ResponsiveHelper.getResponsiveSize(context, 180),
              height: ResponsiveHelper.getResponsiveSize(context, 180),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.getResponsiveWidth(context, 22),
                ResponsiveHelper.getResponsiveHeight(context, 8),
                ResponsiveHelper.getResponsiveWidth(context, 22),
                bottomPadding,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
