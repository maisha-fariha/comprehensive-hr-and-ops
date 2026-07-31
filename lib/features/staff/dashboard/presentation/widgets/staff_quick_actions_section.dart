import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/staff_quick_action.dart';

/// "Quick Actions" heading + a row of shortcut buttons.
///
/// The reference screenshot cuts off before the actual buttons are shown —
/// only the section header is confirmed by the design. The row below is a
/// reasonable placeholder built with the exact same visual language as the
/// HR Manager Dashboard's `QuickActionsSection`/`QuickActionButton`, using
/// only already-exported icon assets.
class StaffQuickActionsSection extends StatelessWidget {
  final List<StaffQuickAction> actions;
  final ValueChanged<StaffQuickAction>? onActionTap;

  const StaffQuickActionsSection({super.key, required this.actions, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.heading3.copyWith(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
          ),
        ),
        if (actions.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                Expanded(
                  child: _StaffQuickActionButton(
                    action: actions[i],
                    onTap: onActionTap == null ? null : () => onActionTap!(actions[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _StaffQuickActionButton extends StatelessWidget {
  final StaffQuickAction action;
  final VoidCallback? onTap;

  const _StaffQuickActionButton({required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 46);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.button(
        padding: ResponsiveHelper.getResponsivePadding(context, top: 16, bottom: 13, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: AppColors.quickActionCreateShiftBg,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(action.asset, size: 20, color: AppColors.secondaryTeal),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 9)),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
