import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/corrective_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'stat_tile_card.dart';

class _CorrectiveStatStyle {
  final String svgAsset;
  final Color color;
  final Color background;

  const _CorrectiveStatStyle({required this.svgAsset, required this.color, required this.background});
}

const Map<CorrectiveStatTag, _CorrectiveStatStyle> _correctiveStatStyles = {
  CorrectiveStatTag.open: _CorrectiveStatStyle(
    svgAsset: AppAssets.messageCircle,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
  CorrectiveStatTag.inProgress: _CorrectiveStatStyle(
    svgAsset: AppAssets.clock,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
  ),
  CorrectiveStatTag.completed: _CorrectiveStatStyle(
    svgAsset: AppAssets.checkCircle,
    color: AppColors.activeGreen,
    background: AppColors.activeIconBackground,
  ),
  CorrectiveStatTag.overdue: _CorrectiveStatStyle(
    svgAsset: AppAssets.alertTriangle,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
};

/// The "Corrective" tab's 2x2 stat grid (Open Actions / In Progress /
/// Completed / Overdue).
class CorrectiveStatsGrid extends StatelessWidget {
  final List<CorrectiveStat> stats;

  const CorrectiveStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
        crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
        mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 82),
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        final style = _correctiveStatStyles[stat.tag]!;
        return StatTileCard(
          svgAsset: style.svgAsset,
          iconColor: style.color,
          iconBackground: style.background,
          value: stat.value,
          valueColor: style.color,
          label: stat.label,
        );
      },
    );
  }
}
