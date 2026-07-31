import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// The flat white app-bar-style header shared by every Medication tab:
/// a menu icon, the "Medication MAR" title + "Oversight · N residences"
/// subtitle centered between it and a search icon.
///
/// NOTE: there is no existing SVG for a hamburger/menu glyph in
/// `assets/icons/{dashboard,common,nav}`, and the Figma asset-download tool
/// is unavailable this round, so [Icons.menu_rounded] is used as a
/// placeholder — see the feature's implementation report.
class MedicationHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;

  const MedicationHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onMenuTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            top: 8,
            bottom: 12,
          ),
          child: Row(
            children: [
              _HeaderIconButton(
                icon: Icons.menu_rounded,
                onTap: onMenuTap,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSearchTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 7),
                  child: const AppSvgIcon(AppAssets.search, size: 20, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 7),
        child: Icon(
          icon,
          size: ResponsiveHelper.getResponsiveSize(context, 22),
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
