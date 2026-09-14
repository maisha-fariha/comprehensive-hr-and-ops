import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_quick_action.dart';

/// "Quick Actions" list driven by `GET /mobile/home` tiles + attendance.
class StaffQuickActionsSection extends StatelessWidget {
  final List<StaffQuickAction> actions;
  final ValueChanged<StaffQuickAction>? onActionTap;
  final bool clockBusy;

  const StaffQuickActionsSection({
    super.key,
    required this.actions,
    this.onActionTap,
    this.clockBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveHeight(context, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _QuickActionCard(
            item: actions[i],
            busy: clockBusy && actions[i].id == 'clock-in-out',
            onTap: onActionTap == null ? null : () => onActionTap!(actions[i]),
          ),
        ],
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final StaffQuickAction item;
  final VoidCallback? onTap;
  final bool busy;

  const _QuickActionCard({
    required this.item,
    this.onTap,
    this.busy = false,
  });

  _QuickActionChrome get _chrome {
    switch (item.id) {
      case 'clock-in-out':
        return const _QuickActionChrome(
          iconColor: Colors.white,
          iconBackground: Color(0xFF2E8C58),
          trailingColor: Color(0xFF2E8C58),
        );
      default:
        return const _QuickActionChrome(
          iconColor: Color(0xFF2A5DA6),
          iconBackground: Color(0xFFEAF0F9),
          trailingColor: AppColors.textSecondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 44);
    final chrome = _chrome;

    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowNavy.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: chrome.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: chrome.iconColor,
                      ),
                    )
                  : AppSvgIcon(item.asset, size: 20, color: chrome.iconColor),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 3),
                    ),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.trailing.isNotEmpty) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                item.trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: chrome.trailingColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionChrome {
  final Color iconColor;
  final Color iconBackground;
  final Color trailingColor;

  const _QuickActionChrome({
    required this.iconColor,
    required this.iconBackground,
    required this.trailingColor,
  });
}
