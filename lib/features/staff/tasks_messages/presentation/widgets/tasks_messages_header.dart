import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White header for Tasks & Messages: bordered back chevron + centered title
/// + optional New Task (BUG_Report009).
class TasksMessagesHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onNewTaskTap;

  const TasksMessagesHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onNewTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final buttonRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    final backButton = GestureDetector(
      onTap: onBack ?? Get.back,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: 3.14159,
          child: const AppSvgIcon(
            AppAssets.chevronRight,
            size: 18,
            color: AppColors.textHeading,
          ),
        ),
      ),
    );

    final newTaskButton = onNewTaskTap == null
        ? SizedBox(width: buttonSize)
        : GestureDetector(
            key: const Key('staff-tasks-new-task'),
            onTap: onNewTaskTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 10,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 16),
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 2),
                  ),
                  Text(
                    'New Task',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );

    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          top: 8,
          bottom: 12,
        ),
        child: SizedBox(
          height: buttonSize,
          child: Row(
            children: [
              backButton,
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 18),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
              newTaskButton,
            ],
          ),
        ),
      ),
    );
  }
}
