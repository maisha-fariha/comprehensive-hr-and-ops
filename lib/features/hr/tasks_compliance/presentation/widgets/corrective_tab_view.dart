import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'corrective_action_card.dart';
import 'corrective_stats_grid.dart';

/// Corrective tab: live actions from `/compliance/corrective-actions`.
/// Sign-off is not available on mobile, so Review is informational.
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
              CorrectiveActionCard(
                action: overview.correctiveActions[i],
                onReviewTap: () => Get.snackbar(
                  'Read-only',
                  'Corrective actions cannot be signed off from the mobile app.',
                  snackPosition: SnackPosition.BOTTOM,
                ),
              ),
            ],
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
