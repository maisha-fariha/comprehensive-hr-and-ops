import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'corrective_action_card.dart';
import 'corrective_stats_grid.dart';
import 'section_count_badge.dart';

/// Body content of the "Corrective" tab: the 2x2 stat grid + the "Active
/// Corrective Actions" list.
class CorrectiveTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  const CorrectiveTabView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CorrectiveStatsGrid(stats: overview.correctiveStats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(
          title: 'Active Corrective Actions',
          trailing: SectionCountBadge(count: overview.correctiveActionsCount),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (final action in overview.correctiveActions) ...[
          CorrectiveActionCard(action: action),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}
