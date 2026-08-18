import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/corrective_stat.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import 'stat_tile_card.dart';

class _CorrectiveStatStyle {
  final String svgAsset;
  final Color color;
  final Color background;

  const _CorrectiveStatStyle({
    required this.svgAsset,
    required this.color,
    required this.background,
  });
}

const Map<CorrectiveStatTag, _CorrectiveStatStyle> _correctiveStatStyles = {
  CorrectiveStatTag.open: _CorrectiveStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_action.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
  ),
  CorrectiveStatTag.inProgress: _CorrectiveStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_in_progress.svg',
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
  ),
  CorrectiveStatTag.completed: _CorrectiveStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_completed.svg',
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
  ),
  CorrectiveStatTag.overdue: _CorrectiveStatStyle(
    svgAsset: 'assets/icons/tasks_compliance/tasks_alert.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
  ),
};

/// Corrective tab 2x2 stat grid — matched to the Corrective reference.
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
        mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
        crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 10),
        mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 78),
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
