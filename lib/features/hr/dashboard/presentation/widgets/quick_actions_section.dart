import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/quick_action.dart';
import 'quick_action_button.dart';

/// "Quick Actions" heading + the row of 4 shortcut buttons.
class QuickActionsSection extends StatelessWidget {
  final List<QuickAction> actions;
  final ValueChanged<QuickAction>? onActionTap;

  const QuickActionsSection({super.key, required this.actions, this.onActionTap});

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
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: QuickActionButton(
                  action: actions[i],
                  onTap: onActionTap == null ? null : () => onActionTap!(actions[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
