import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../constants/app_colors.dart';

/// Generic placeholder for role-module screens that are not yet implemented
/// (e.g. the other Manager tabs: Schedule, Attendance, Alerts, More). Keeps
/// bottom-navigation fully functional while those Figma screens are built
/// out in follow-up work, without fabricating UI that isn't in scope yet.
class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonPage({
    super.key,
    required this.title,
    this.icon = Icons.hourglass_top_rounded,
  });

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
                Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 40), color: AppColors.secondaryTeal),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                Text(
                  '$title — Coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
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
