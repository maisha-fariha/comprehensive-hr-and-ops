import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../constants/app_colors.dart';

/// Shown when [RoleGuardMiddleware] blocks navigation into a portal the
/// current session isn't authorized for.
class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.criticalRed),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                const Text(
                  "You don't have access to this area.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
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
