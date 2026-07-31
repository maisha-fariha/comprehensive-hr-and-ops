import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/open_position.dart';
import '../../domain/entities/scheduling_enums.dart';

/// A single row in the Board tab's "Open Positions" list, e.g.
/// "RN Needed — Urgent — Morning Shift · Pinecrest Manor — [Post]".
class BoardOpenPositionCard extends StatelessWidget {
  final OpenPosition position;
  final VoidCallback? onPostTap;

  const BoardOpenPositionCard({super.key, required this.position, this.onPostTap});

  @override
  Widget build(BuildContext context) {
    final isUrgent = position.urgency == OpenPositionUrgency.urgent;
    final badgeColor = isUrgent ? AppColors.criticalRed : AppColors.infoBlue;
    final badgeBackground = isUrgent ? AppColors.criticalBackground : AppColors.infoBackground;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxLarge);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.quickActionLogNoteBg,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxLarge),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(AppAssets.users, size: 18, color: AppColors.infoBlue),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        position.roleTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                    StatusBadge.chip(
                      label: isUrgent ? 'Urgent' : 'Open',
                      background: badgeBackground,
                      foreground: badgeColor,
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  position.subtitle,
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
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          GestureDetector(
            onTap: onPostTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
                ),
              ),
              child: Text(
                'Post',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
