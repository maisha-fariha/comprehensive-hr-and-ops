import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/compliance_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'stat_tile_card.dart';

class _ComplianceStatStyle {
  final String svgAsset;
  final Color color;
  final Color background;

  const _ComplianceStatStyle({required this.svgAsset, required this.color, required this.background});
}

const Map<ComplianceStatTag, _ComplianceStatStyle> _complianceStatStyles = {
  ComplianceStatTag.completed: _ComplianceStatStyle(
    svgAsset: AppAssets.checkCircle,
    color: AppColors.activeGreen,
    background: AppColors.activeIconBackground,
  ),
  ComplianceStatTag.pendingReview: _ComplianceStatStyle(
    svgAsset: AppAssets.clock,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
  ),
  ComplianceStatTag.needsAttention: _ComplianceStatStyle(
    svgAsset: AppAssets.alertTriangle,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
};

/// The "Compliance" tab's 3-column stat row (Completed / Pending Review /
/// Needs Attention), directly below the "Overall Compliance" hero card.
class ComplianceStatsRow extends StatelessWidget {
  final List<ComplianceStat> stats;

  const ComplianceStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Builder(builder: (context) {
              final stat = stats[i];
              final style = _complianceStatStyles[stat.tag]!;
              return StatTileCard(
                svgAsset: style.svgAsset,
                iconColor: style.color,
                iconBackground: style.background,
                value: stat.value,
                valueColor: style.color,
                label: stat.label,
                layout: StatTileLayout.vertical,
              );
            }),
          ),
        ],
      ],
    );
  }
}
