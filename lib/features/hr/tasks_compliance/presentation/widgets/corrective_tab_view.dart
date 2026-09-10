import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/corrective_action.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'corrective_action_card.dart';
import 'corrective_stats_grid.dart';

/// Corrective tab:
/// - Active → `GET /compliance/corrective-actions?status=open,in_progress`
/// - Overdue badge → `GET /compliance/corrective-actions?overdue=true`
/// - Recent Resolutions → `GET /compliance/corrective-actions?status=completed`
/// Detail uses list-row fields only (no separate GET).
class CorrectiveTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  static const Color _badgeSoft = Color(0xFFEAF0F9);
  static const Color _badgeFg = Color(0xFF2A5DA6);
  static const Color _overdueBg = Color(0xFFFBEDED);
  static const Color _overdueFg = Color(0xFFD64545);

  const CorrectiveTabView({super.key, required this.overview});

  void _showActionDetail(CorrectiveAction action) {
    Get.snackbar(
      action.title,
      [
        action.status.name,
        if (action.assignee.name.isNotEmpty) 'Assigned: ${action.assignee.name}',
        if (action.dueDateLabel.isNotEmpty) action.dueDateLabel,
        if (action.locationName.isNotEmpty)
          '${action.locationCategory} · ${action.locationName}',
      ].where((part) => part.trim().isNotEmpty).join(' · '),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);
    final active = overview.correctiveActions;
    final resolved = overview.recentResolutions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CorrectiveStatsGrid(stats: overview.correctiveStats),
        SizedBox(height: sectionGap),
        Row(
          children: [
            Expanded(
              child: Text(
                'Active Corrective Actions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            if (overview.correctiveOverdueCount > 0) ...[
              _PillBadge(
                label: '${overview.correctiveOverdueCount} Overdue',
                background: _overdueBg,
                foreground: _overdueFg,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            ],
            _SoftCountBadge(
              count: overview.correctiveActionsCount,
              background: _badgeSoft,
              foreground: _badgeFg,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (active.isEmpty)
          const _EmptyHint('No active corrective actions.')
        else
          for (var i = 0; i < active.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            CorrectiveActionCard(
              action: active[i],
              onReviewTap: () => _showActionDetail(active[i]),
            ),
          ],
        SizedBox(height: sectionGap),
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Resolutions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            _SoftCountBadge(
              count: overview.recentResolutionsCount,
              background: _badgeSoft,
              foreground: _badgeFg,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (resolved.isEmpty)
          const _EmptyHint('No recent resolutions.')
        else
          for (var i = 0; i < resolved.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            CorrectiveActionCard(
              action: resolved[i],
              onReviewTap: () => _showActionDetail(resolved[i]),
            ),
          ],
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

class _PillBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: foreground,
          height: 1.1,
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
