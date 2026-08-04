import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/assignee.dart';
import '../../domain/entities/compliance_checklist_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'compliance_checklist_tile.dart';
import 'compliance_overview_card.dart';
import 'compliance_stats_row.dart';

/// Compliance tab body: overview card, stats row, checklist, and upcoming
/// reviews — matched to the Compliance tab reference.
class ComplianceTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  static const Color _badgeSoft = Color(0xFFEAF0F9);
  static const Color _badgeFg = Color(0xFF2A5DA6);

  /// UI-only 4th checklist row shown in the reference when the mock list
  /// is shorter than [overview.complianceChecklistCount].
  static const ComplianceChecklistItem _hipaaItem = ComplianceChecklistItem(
    id: 'hipaa-documentation-audit',
    title: 'HIPAA Documentation Audit',
    category: 'Privacy',
    assignee: Assignee(
      initials: 'DL',
      name: 'Diego L.',
      colorTag: AssigneeColorTag.blue,
    ),
    dateLabel: 'May 10',
    status: ComplianceItemStatus.completed,
  );

  const ComplianceTabView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...overview.complianceChecklistItems,
      if (overview.complianceChecklistItems.length < overview.complianceChecklistCount)
        _hipaaItem,
    ];
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ComplianceOverviewCard(summary: overview.complianceSummary),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            ComplianceStatsRow(stats: overview.complianceStats),
            SizedBox(height: sectionGap),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Compliance Checklist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                _SoftCountBadge(
                  count: overview.complianceChecklistCount,
                  background: _badgeSoft,
                  foreground: _badgeFg,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: cardGap),
              ComplianceChecklistTile(item: items[i]),
            ],
            SizedBox(height: sectionGap),
            Text(
              'Upcoming Compliance Reviews',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            const _UpcomingReviewsCard(),
          ],
        );
      },
    );
  }
}

class _SoftCountBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const _SoftCountBadge({
    required this.count,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}

class _UpcomingReviewsCard extends StatelessWidget {
  const _UpcomingReviewsCard();

  static const _items = [
    _ReviewItem(day: '18', month: 'May', title: 'Quarterly Fire Safety Review', supervisor: 'Mike T.'),
    _ReviewItem(day: '22', month: 'May', title: 'Infection Control Audit', supervisor: 'Sarah J.'),
    _ReviewItem(day: '28', month: 'May', title: 'Resident Care Plan Review', supervisor: 'Aisha N.'),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
            _ReviewRow(item: _items[i]),
          ],
        ],
      ),
    );
  }
}

class _ReviewItem {
  final String day;
  final String month;
  final String title;
  final String supervisor;

  const _ReviewItem({
    required this.day,
    required this.month,
    required this.title,
    required this.supervisor,
  });
}

class _ReviewRow extends StatelessWidget {
  final _ReviewItem item;

  const _ReviewRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateBox = ResponsiveHelper.getResponsiveSize(context, 44);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      child: Row(
        children: [
          Container(
            width: dateBox,
            height: dateBox,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.day,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                    height: 1.1,
                  ),
                ),
                Text(
                  item.month,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                    color: AppColors.textMuted,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Text(
                  'Supervisor: ${item.supervisor}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
