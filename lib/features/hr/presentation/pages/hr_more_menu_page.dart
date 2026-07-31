import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../daily_logs/presentation/pages/daily_logs_page.dart';
import '../../medication/presentation/pages/medication_page.dart';
import '../../tasks_compliance/presentation/pages/tasks_compliance_page.dart';
import '../../team_reports/presentation/pages/team_reports_page.dart';

/// "More" tab of the HR bottom navigation — a simple navigation hub for the
/// Manager feature areas that don't have a dedicated bottom-nav slot in the
/// Figma bottom bar (Home/Schedule/Attendance/Alerts/More only has 5 slots).
///
/// This menu itself isn't a distinct Figma frame; it's a pragmatic way to
/// make the Daily Logs, Medication, Tasks & Compliance and Team & Reports
/// screens reachable end-to-end until the real "More" destination/IA is
/// captured from Figma.
class HrMoreMenuPage extends StatelessWidget {
  const HrMoreMenuPage({super.key});

  static const _entries = <_MoreMenuEntry>[
    _MoreMenuEntry(
      icon: Icons.assignment_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      title: 'Daily Logs',
      subtitle: 'Shift logs, missing entries & handovers',
    ),
    _MoreMenuEntry(
      icon: Icons.medication_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      title: 'Medication',
      subtitle: 'MAR oversight across all residences',
    ),
    _MoreMenuEntry(
      icon: Icons.fact_check_outlined,
      iconBackground: AppColors.urgentBackground,
      iconColor: AppColors.urgentAmber,
      title: 'Tasks & Compliance',
      subtitle: 'Due tasks, compliance checks & corrective actions',
    ),
    _MoreMenuEntry(
      icon: Icons.groups_outlined,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
      title: 'Team & Reports',
      subtitle: 'Staff roster, reports & messages',
    ),
  ];

  void _open(BuildContext context, int index) {
    switch (index) {
      case 0:
        Get.to(() => const DailyLogsPage());
        break;
      case 1:
        Get.to(() => const MedicationPage());
        break;
      case 2:
        Get.to(() => const TasksCompliancePage());
        break;
      case 3:
        Get.to(() => const TeamReportsPage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'More',
          style: AppTextStyles.base(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: AppFontWeight.semiBold,
            color: AppColors.textHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: AppDimens.screenPaddingHorizontal,
            vertical: 20,
          ),
          itemCount: _entries.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return _MoreMenuTile(
              entry: entry,
              onTap: () => _open(context, index),
            );
          },
        ),
      ),
    );
  }
}

class _MoreMenuEntry {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _MoreMenuEntry({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class _MoreMenuTile extends StatelessWidget {
  final _MoreMenuEntry entry;
  final VoidCallback onTap;

  const _MoreMenuTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveWidth(context, AppDimens.iconBoxMedium),
              height: ResponsiveHelper.getResponsiveHeight(context, AppDimens.iconBoxMedium),
              decoration: BoxDecoration(
                color: entry.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxMedium),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                entry.icon,
                size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconMedium),
                color: entry.iconColor,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.title,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                      fontWeight: AppFontWeight.semiBold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    entry.subtitle,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: AppFontWeight.regular,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconMedium),
              color: AppColors.iconChevron,
            ),
          ],
        ),
      ),
    );
  }
}
