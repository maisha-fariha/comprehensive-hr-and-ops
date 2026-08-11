import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_attention_alert.dart';
import 'family_attention_alert_tile.dart';

/// "Needs Attention" card: red severity dot, count badge, "View all", and
/// alert rows.
class FamilyNeedsAttentionCard extends StatelessWidget {
  final List<FamilyAttentionAlert> alerts;
  final VoidCallback? onViewAll;
  final ValueChanged<FamilyAttentionAlert>? onAlertTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _viewAllColor = Color(0xFF0E7C7B);
  static const Color _dotColor = Color(0xFFE53935);
  static const Color _countBg = Color(0xFFFDECEC);
  static const Color _countFg = Color(0xFFE53935);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const FamilyNeedsAttentionCard({
    super.key,
    required this.alerts,
    this.onViewAll,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 24);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        left: 18,
        right: 18,
        top: 18,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 8),
                      height: ResponsiveHelper.getResponsiveSize(context, 8),
                      decoration: const BoxDecoration(
                        color: _dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                    Flexible(
                      child: Text(
                        'Needs Attention',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: _titleColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                    Container(
                      constraints: BoxConstraints(
                        minWidth: ResponsiveHelper.getResponsiveSize(context, 22),
                        minHeight: ResponsiveHelper.getResponsiveSize(context, 22),
                      ),
                      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6),
                      decoration: const BoxDecoration(
                        color: _countBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${alerts.length}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                          color: _countFg,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              GestureDetector(
                onTap: onViewAll,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'View all',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: _viewAllColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          for (var i = 0; i < alerts.length; i++)
            FamilyAttentionAlertTile(
              alert: alerts[i],
              showDivider: i != alerts.length - 1,
              onTap: onAlertTap == null ? null : () => onAlertTap!(alerts[i]),
            ),
        ],
      ),
    );
  }
}
