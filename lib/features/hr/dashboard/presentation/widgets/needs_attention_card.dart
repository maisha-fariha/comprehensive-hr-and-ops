import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/attention_alert.dart';
import 'attention_alert_tile.dart';

/// "Needs Attention" card: a severity dot + counter badge in the header and
/// a short list of items that require the manager's action.
class NeedsAttentionCard extends StatelessWidget {
  final List<AttentionAlert> alerts;
  final VoidCallback? onViewAll;
  final ValueChanged<AttentionAlert>? onAlertTap;

  const NeedsAttentionCard({
    super.key,
    required this.alerts,
    this.onViewAll,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, left: 17, right: 17, top: 16, bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveSize(context, 7),
                    height: ResponsiveHelper.getResponsiveSize(context, 7),
                    decoration: const BoxDecoration(
                      color: AppColors.criticalRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                  Text(
                    'Needs Attention',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                  Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: ResponsiveHelper.getResponsiveSize(context, 19),
                    padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6.4),
                    decoration: BoxDecoration(
                      color: AppColors.criticalBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${alerts.length}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                        color: AppColors.criticalRed,
                      ),
                    ),
                  ),
                ],
              ),
              ViewAllLink(onTap: onViewAll),
            ],
          ),
          for (var i = 0; i < alerts.length; i++)
            AttentionAlertTile(
              alert: alerts[i],
              showDivider: i != alerts.length - 1,
              onTap: onAlertTap == null ? null : () => onAlertTap!(alerts[i]),
            ),
        ],
      ),
    );
  }
}
