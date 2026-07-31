import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../staff_tasks_messages_constants.dart';

/// Centered pill divider shown between groups of messages in the thread,
/// e.g. "Today".
class DateDivider extends StatelessWidget {
  final String label;

  const DateDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: StaffTasksMessagesColors.dateDividerBackground,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 999)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
