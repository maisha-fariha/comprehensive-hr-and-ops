import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/compliance_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

class _ComplianceStatStyle {
  final String svgAsset;
  final Color color;
  final Color background;

  const _ComplianceStatStyle({
    required this.svgAsset,
    required this.color,
    required this.background,
  });
}

const Map<ComplianceStatTag, _ComplianceStatStyle> _complianceStatStyles = {
  ComplianceStatTag.completed: _ComplianceStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_completed.svg',
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
  ),
  ComplianceStatTag.pendingReview: _ComplianceStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_clock.svg',
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
  ),
  ComplianceStatTag.needsAttention: _ComplianceStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_alert.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
  ),
};

/// Compliance tab 3-column stat row — vertical tiles with circular icon wells.
class ComplianceStatsRow extends StatelessWidget {
  final List<ComplianceStat> stats;

  const ComplianceStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(
              child: _ComplianceStatTile(
                stat: stats[i],
                style: _complianceStatStyles[stats[i].tag]!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComplianceStatTile extends StatelessWidget {
  final ComplianceStat stat;
  final _ComplianceStatStyle style;

  const _ComplianceStatTile({required this.stat, required this.style});

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 36);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 8);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(radius),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(style.svgAsset, size: 17, color: style.color),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              color: style.color,
              height: 1.1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
