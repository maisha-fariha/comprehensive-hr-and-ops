import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/residence_summary.dart';

class ResidenceCard extends StatelessWidget {
  final ResidenceSummary residence;
  final VoidCallback? onTap;

  const ResidenceCard({super.key, required this.residence, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = residence;
    final ratio = r.bedCapacity == 0
        ? 0.0
        : (r.residents / r.bedCapacity).clamp(0.0, 1.0);
    final barColor = r.atCapacity
        ? AppColors.urgentAmber
        : AppColors.secondaryTeal;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: AppTextStyles.base(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                          fontWeight: AppFontWeight.semiBold,
                          color: AppColors.textHeading,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      Text(
                        r.address ?? 'No address on file',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.base(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          fontWeight: AppFontWeight.regular,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                StatusBadge.pill(
                  label: r.statusLabel.toUpperCase(),
                  background: r.isActive
                      ? AppColors.activeBackground
                      : AppColors.filterButtonBackground,
                  foreground: r.isActive
                      ? AppColors.activeGreen
                      : AppColors.textSecondary,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Row(
              children: [
                if (r.residenceType != null) ...[
                  StatusBadge.chip(
                    label: hrHumanize(r.residenceType),
                    background: AppColors.infoBackground,
                    foreground: AppColors.infoBlue,
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                ],
                if (r.gpsRadiusMeters != null)
                  _meta(context, Icons.my_location_rounded, '${r.gpsRadiusMeters} m'),
                const Spacer(),
                Text(
                  '${r.residents}/${r.bedCapacity} Beds',
                  style: AppTextStyles.base(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    fontWeight: AppFontWeight.semiBold,
                    color: AppColors.textHeading,
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded, color: AppColors.iconChevron),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: ResponsiveHelper.getResponsiveHeight(context, 5),
                backgroundColor: AppColors.dividerLight,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.base(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
            fontWeight: AppFontWeight.medium,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
