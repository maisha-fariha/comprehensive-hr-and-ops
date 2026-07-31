import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/family_linked_client.dart';
import '../../family_profile_settings_constants.dart';
import 'family_initials_avatar.dart';

/// A single row in the "Linked Clients" section: avatar, name + residence/
/// room subtext, and a trailing status pill (e.g. "Active").
class FamilyLinkedClientRow extends StatelessWidget {
  final FamilyLinkedClient client;

  const FamilyLinkedClientRow({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: AppDimens.cardPaddingHorizontal,
        vertical: 13,
      ),
      child: Row(
        children: [
          FamilyInitialsAvatar(
            initials: client.initials,
            background: FamilyProfileSettingsConstants.linkedClientAvatarBackground,
            foreground: FamilyProfileSettingsConstants.linkedClientAvatarForeground,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  client.name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  client.subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          StatusBadge.pill(
            label: client.statusLabel,
            background: AppColors.activeBackground,
            foreground: AppColors.activeGreen,
          ),
        ],
      ),
    );
  }
}
