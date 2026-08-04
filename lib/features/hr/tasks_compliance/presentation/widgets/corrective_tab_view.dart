import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'corrective_action_card.dart';
import 'corrective_stats_grid.dart';

/// Corrective tab body: stats grid, Active Corrective Actions, and Recent
/// Resolutions — matched to the Corrective tab reference.
class CorrectiveTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  static const Color _badgeSoft = Color(0xFFEAF0F9);
  static const Color _badgeFg = Color(0xFF2A5DA6);

  const CorrectiveTabView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);

    return LayoutBuilder(
      builder: (context, constraints) {
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
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                _SoftCountBadge(
                  count: overview.correctiveActionsCount,
                  background: _badgeSoft,
                  foreground: _badgeFg,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (var i = 0; i < overview.correctiveActions.length; i++) ...[
              if (i > 0) SizedBox(height: cardGap),
              CorrectiveActionCard(action: overview.correctiveActions[i]),
            ],
            SizedBox(height: sectionGap),
            Text(
              'Recent Resolutions',
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
            const _RecentResolutionsCard(),
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

/// UI-only Recent Resolutions list (no domain model yet).
class _RecentResolutionsCard extends StatelessWidget {
  const _RecentResolutionsCard();

  static const _items = [
    _ResolutionItem(
      title: 'Emergency Exit Signage Fixed',
      completedBy: 'Mike T.',
      initials: 'MT',
      avatarBg: Color(0xFFF0ECFB),
      avatarFg: Color(0xFF6A4BC7),
      date: 'May 9',
    ),
    _ResolutionItem(
      title: 'Temperature Log Compliance',
      completedBy: 'Diego L.',
      initials: 'DL',
      avatarBg: Color(0xFFEAF0F9),
      avatarFg: Color(0xFF2A5DA6),
      date: 'May 7',
    ),
    _ResolutionItem(
      title: 'Hand Hygiene Retraining',
      completedBy: 'Sarah J.',
      initials: 'SJ',
      avatarBg: Color(0xFFEAF6F0),
      avatarFg: Color(0xFF2E8C58),
      date: 'May 5',
    ),
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
            _ResolutionRow(item: _items[i]),
          ],
        ],
      ),
    );
  }
}

class _ResolutionItem {
  final String title;
  final String completedBy;
  final String initials;
  final Color avatarBg;
  final Color avatarFg;
  final String date;

  const _ResolutionItem({
    required this.title,
    required this.completedBy,
    required this.initials,
    required this.avatarBg,
    required this.avatarFg,
    required this.date,
  });
}

class _ResolutionRow extends StatelessWidget {
  final _ResolutionItem item;

  const _ResolutionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 36);
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 18);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F0),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 10),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              'assets/icons/tasks_compliance/tasks_tick.svg',
              size: 16,
              color: Color(0xFF2E8C58),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Row(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: item.avatarBg,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.initials,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 8),
                          color: item.avatarFg,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                    Flexible(
                      child: Text(
                        'Completed by ${item.completedBy}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Text(
            item.date,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
