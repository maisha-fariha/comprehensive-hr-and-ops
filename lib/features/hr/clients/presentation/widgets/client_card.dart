import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../../profile_settings/presentation/widgets/hr_initials_avatar.dart';
import '../../domain/entities/client_summary.dart';

class ClientCard extends StatelessWidget {
  final ClientSummary client;
  final String? residenceName;
  final VoidCallback? onTap;

  const ClientCard({
    super.key,
    required this.client,
    this.residenceName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = client;
    final level = careLevelColors(c.careLevel);
    final age = c.age;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Row(
          children: [
            HrInitialsAvatar(
              initials: c.initials,
              imageUrl: c.photoUrl,
              size: 46,
              background: AppColors.infoBackground,
              foreground: AppColors.infoBlue,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.base(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                            fontWeight: AppFontWeight.semiBold,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                      Text(
                        c.shortId,
                        style: AppTextStyles.base(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                          fontWeight: AppFontWeight.medium,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    [
                      residenceName ?? c.residenceName ?? 'No residence',
                      if (c.room != null) 'Room ${c.room}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: AppFontWeight.regular,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (c.careLevel != null)
                        StatusBadge.chip(
                          label: '${hrHumanize(c.careLevel)} care',
                          background: level.$1,
                          foreground: level.$2,
                        ),
                      StatusBadge.chip(
                        label: hrHumanize(c.status),
                        background: c.isActive
                            ? AppColors.activeBackground
                            : AppColors.filterButtonBackground,
                        foreground: c.isActive
                            ? AppColors.activeGreen
                            : AppColors.textSecondary,
                      ),
                      if (c.dateOfBirth != null)
                        Text(
                          'DOB ${hrFormatDate(c.dateOfBirth)}'
                          '${age == null ? '' : ' ($age)'}',
                          style: AppTextStyles.base(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            fontWeight: AppFontWeight.medium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.iconChevron),
          ],
        ),
      ),
    );
  }
}

/// Background/foreground colors for a care level badge.
(Color, Color) careLevelColors(String? level) {
  switch (level?.toLowerCase()) {
    case 'high':
    case 'critical':
      return (AppColors.criticalBackgroundSoft, AppColors.criticalRed);
    case 'medium':
    case 'moderate':
      return (AppColors.urgentBackground, AppColors.urgentAmber);
    default:
      return (AppColors.infoBackground, AppColors.infoBlue);
  }
}
