import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';

/// Top app header shared by all three tabs: a hamburger menu button, the
/// "Team & Reports" title and a trailing action button whose icon swaps
/// from a search glyph (Team/Reports tabs) to a compose/pencil glyph
/// (Messages tab).
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

    return Row(
      children: [
        _HeaderIconButton(
          // No matching exported SVG for a hamburger/menu glyph; falls back
          // to a Material icon (see the feature's final report).
          materialIcon: Icons.menu_rounded,
          onTap: onMenuTap,
        ),
        Expanded(
          child: Text(
            'Team & Reports',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
              color: AppColors.textHeading,
            ),
          ),
        ),
        _HeaderIconButton(
          asset: isMessagesTab ? TeamReportsAssets.composeMessage : TeamReportsAssets.search,
          onTap: onTrailingTap,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String? asset;
  final IconData? materialIcon;
  final VoidCallback? onTap;

  const _HeaderIconButton({this.asset, this.materialIcon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 40);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
        ),
        alignment: Alignment.center,
        child: asset != null
            ? AppSvgIcon(asset!, size: 17, color: AppColors.textBody)
            : Icon(materialIcon, size: ResponsiveHelper.getResponsiveSize(context, 20), color: AppColors.textBody),
      ),
    );
  }
}
