import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';

/// Shared header: plain menu, centered title, bordered trailing action
/// (search on Team/Reports, compose on Messages) — matched to the reference.
class TeamReportsHeader extends StatelessWidget {
  final TeamReportsTab selectedTab;
  final VoidCallback? onMenuTap;
  final VoidCallback? onTrailingTap;

  const TeamReportsHeader({
    super.key,
    required this.selectedTab,
    this.onMenuTap,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMessagesTab = selectedTab == TeamReportsTab.messages;

    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onMenuTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 7),
                  child: Icon(
                    Icons.menu_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 22),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Team & Reports',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTrailingTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: ResponsiveHelper.getResponsiveSize(context, 36),
                  height: ResponsiveHelper.getResponsiveSize(context, 36),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 10),
                    ),
                    border: Border.all(color: AppColors.searchBorder),
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon(
                    isMessagesTab
                        ? TeamReportsAssets.composeMessage
                        : TeamReportsAssets.search,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
