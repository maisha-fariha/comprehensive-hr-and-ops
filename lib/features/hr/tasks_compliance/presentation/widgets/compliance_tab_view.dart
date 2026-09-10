import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'compliance_checklist_tile.dart';
import 'compliance_overview_card.dart';
import 'compliance_requirement_tile.dart';
import 'compliance_stats_row.dart';

/// Compliance tab body: score, counters, checklist, upcoming reviews.
class ComplianceTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  static const Color _badgeSoft = Color(0xFFEAF0F9);
  static const Color _badgeFg = Color(0xFF2A5DA6);

  const ComplianceTabView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = overview.complianceChecklistItems;
    final reviews = overview.upcomingReviews;
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ComplianceOverviewCard(summary: overview.complianceSummary),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ComplianceStatsRow(stats: overview.complianceStats),
        SizedBox(height: sectionGap),
        _SectionHeader(
          title: 'Compliance Checklist',
          count: overview.complianceChecklistCount,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (items.isEmpty)
          const _EmptyHint('No outstanding compliance checks.')
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            ComplianceChecklistTile(item: items[i]),
          ],
        SizedBox(height: sectionGap),
        _SectionHeader(
          title: 'Upcoming Compliance Reviews',
          count: overview.upcomingReviewsCount,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (reviews.isEmpty)
          const _EmptyHint('No upcoming compliance reviews.')
        else
          for (var i = 0; i < reviews.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            ComplianceRequirementTile(item: reviews[i]),
          ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
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
          count: count,
          background: ComplianceTabView._badgeSoft,
          foreground: ComplianceTabView._badgeFg,
        ),
      ],
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

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
