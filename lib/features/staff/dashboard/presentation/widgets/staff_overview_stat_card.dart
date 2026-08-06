import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_dashboard_enums.dart';
import '../../domain/entities/staff_overview_stat.dart';

class _StatTagStyle {
  final String asset;
  final Color accent;
  final Color iconBackground;
  final Color? valueColor;
  final bool showAsStatusPill;

  const _StatTagStyle({
    required this.asset,
    required this.accent,
    required this.iconBackground,
    this.valueColor,
    this.showAsStatusPill = false,
  });
}

const Map<StaffStatTag, _StatTagStyle> _statTagStyles = {
  StaffStatTag.onShift: _StatTagStyle(
    asset: 'assets/icons/staff_core/on_shift.svg',
    accent: Color(0xFF2E8C58),
    iconBackground: Color(0xFFEAF6F0),
    showAsStatusPill: true,
  ),
  StaffStatTag.clients: _StatTagStyle(
    asset: 'assets/icons/staff_core/clients.svg',
    accent: Color(0xFF2A5DA6),
    iconBackground: Color(0xFFEAF0F9),
    valueColor: AppColors.textHeading,
  ),
  StaffStatTag.tasks: _StatTagStyle(
    asset: 'assets/icons/staff_core/tasks_due.svg',
    accent: Color(0xFFB4791C),
    iconBackground: Color(0xFFFCF5ED),
    valueColor: Color(0xFFB4791C),
  ),
  StaffStatTag.medications: _StatTagStyle(
    asset: 'assets/icons/staff_core/medication_due.svg',
    accent: Color(0xFFD64545),
    iconBackground: Color(0xFFFBEDED),
    valueColor: Color(0xFFD64545),
  ),
};

/// A single tile in the Staff Dashboard's "Today's Overview" stat grid.
class StaffOverviewStatCard extends StatelessWidget {
  final StaffOverviewStat stat;
  final VoidCallback? onTap;

  const StaffOverviewStatCard({super.key, required this.stat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 36);
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 8);
    final topBar = ResponsiveHelper.getResponsiveHeight(context, 2.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.05),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: topBar,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      style.accent,
                      style.accent.withValues(alpha: 0.33),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              color: style.iconBackground,
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveRadius(context, 10),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon(style.asset, size: 18, color: style.accent),
                          ),
                          const Spacer(),
                          Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: style.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: style.accent.withValues(alpha: 0.33), width: 4)
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (style.showAsStatusPill)
                        Container(
                          padding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: style.iconBackground,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveRadius(context, 8),
                            ),
                          ),
                          child: Text(
                            stat.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                              color: style.accent,
                              height: 1.1,
                            ),
                          ),
                        )
                      else
                        Text(
                          stat.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
                            color: style.valueColor ?? AppColors.textHeading,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                      Text(
                        stat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
