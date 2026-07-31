import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'compliance_checklist_tile.dart';
import 'compliance_overview_card.dart';
import 'compliance_stats_row.dart';
import 'section_count_badge.dart';

/// Body content of the "Compliance" tab: the "Overall Compliance" hero
/// card, its 3-column stat row, and the "Compliance Checklist" list.
class ComplianceTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  const ComplianceTabView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComplianceOverviewCard(summary: overview.complianceSummary),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        ComplianceStatsRow(stats: overview.complianceStats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(
          title: 'Compliance Checklist',
          trailing: SectionCountBadge(count: overview.complianceChecklistCount),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (final item in overview.complianceChecklistItems) ...[
          ComplianceChecklistTile(item: item),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}
