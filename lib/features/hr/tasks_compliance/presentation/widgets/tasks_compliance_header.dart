import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/widgets/hr_company_brand.dart';
import '../../../presentation/widgets/hr_header_primary_action.dart';

/// Tasks & Compliance header: company brand (no hamburger), title, New Task, search.
class TasksComplianceHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNewTaskTap;

  const TasksComplianceHeader({
    super.key,
    this.title = 'Tasks & Compliance',
    required this.subtitle,
    this.onSearchTap,
    this.onNewTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            top: 4,
            bottom: 6,
          ),
          child: Row(
            children: [
              const Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: HrCompanyBrand(maxNameWidth: 100),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          17,
                        ),
                        color: AppColors.textHeading,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 2),
                      ),
                      Text(
                        subtitle,
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
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onNewTaskTap != null) ...[
                HrHeaderPrimaryAction(
                  actionKey: const ValueKey('tasks-header-new-task'),
                  label: 'Task',
                  onTap: onNewTaskTap!,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              ],
              GestureDetector(
                onTap: onSearchTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: ResponsiveHelper.getResponsiveSize(context, 36),
                  height: ResponsiveHelper.getResponsiveSize(context, 36),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 10),
                    ),
                    border: Border.all(color: AppColors.searchBorder),
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(
                    AppAssets.search,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
