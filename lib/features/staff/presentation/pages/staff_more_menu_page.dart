import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../attendance/presentation/pages/staff_attendance_page.dart';
import '../../incidents/presentation/pages/staff_incidents_list_page.dart';
import '../../profile_settings/presentation/pages/staff_profile_settings_page.dart';
import '../widgets/staff_menu_entry.dart';

/// "More" tab of the Staff bottom navigation — a navigation hub for the
/// feature areas that don't have a dedicated bottom-nav slot in the Figma
/// bottom bar (Home/Schedule/Clients/MAR-Tasks/More only has 5 slots).
///
/// This menu itself isn't a distinct Figma frame; it's a pragmatic way to
/// make Attendance, Incidents and Profile & Settings reachable end-to-end.
class StaffMoreMenuPage extends StatelessWidget {
  const StaffMoreMenuPage({super.key});

  static const _entries = <StaffMenuEntry>[
    StaffMenuEntry(
      icon: Icons.access_time_rounded,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      title: 'Attendance',
      subtitle: 'Clock in/out and shift history',
    ),
    StaffMenuEntry(
      icon: Icons.report_gmailerrorred_outlined,
      iconBackground: AppColors.urgentBackground,
      iconColor: AppColors.criticalRed,
      title: 'Incidents',
      subtitle: 'My reports & all residence incidents',
    ),
    StaffMenuEntry(
      icon: Icons.person_outline_rounded,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
      title: 'Profile & Settings',
      subtitle: 'Account, assigned clients & preferences',
    ),
  ];

  void _open(BuildContext context, int index) {
    switch (index) {
      case 0:
        Get.to(() => const StaffAttendancePage());
        break;
      case 1:
        Get.to(() => const StaffIncidentsListPage());
        break;
      case 2:
        Get.to(() => const StaffProfileSettingsPage());
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
            return StaffMenuTile(
              entry: entry,
              onTap: () => _open(context, index),
            );
          },
        ),
      ),
    );
  }
}
