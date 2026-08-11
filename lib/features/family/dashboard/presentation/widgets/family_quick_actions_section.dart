import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_quick_action.dart';

/// "Quick Actions" heading + equal-width row of shortcut tiles.
class FamilyQuickActionsSection extends StatelessWidget {
  final List<FamilyQuickAction> actions;
  final ValueChanged<FamilyQuickAction>? onActionTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _iconFg = Color(0xFF0E7C7B);
  static const Color _iconBg = Color(0xFFE8F5F3);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const FamilyQuickActionsSection({
    super.key,
    required this.actions,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            color: _titleColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: _QuickActionTile(
                    action: actions[i],
                    onTap: onActionTap == null ? null : () => onActionTap!(actions[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final FamilyQuickAction action;
  final VoidCallback? onTap;

  const _QuickActionTile({required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 8,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: FamilyQuickActionsSection._border),
          boxShadow: [
            BoxShadow(
              color: FamilyQuickActionsSection._shadow.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
            ),
            BoxShadow(
              color: FamilyQuickActionsSection._shadow.withValues(alpha: 0.05),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: FamilyQuickActionsSection._iconBg,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(
                action.asset,
                size: 20,
                color: FamilyQuickActionsSection._iconFg,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                color: FamilyQuickActionsSection._titleColor,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
