import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/roles/user_session.dart';
import '../../attendance/presentation/pages/staff_attendance_page.dart';
import '../../incidents/presentation/pages/staff_incidents_list_page.dart';
import '../../profile_settings/presentation/pages/staff_profile_settings_page.dart';
import '../widgets/staff_menu_entry.dart';

class StaffMoreMenuPage extends StatelessWidget {
  const StaffMoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();

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
        child: Obx(() {
          final entries = <StaffMenuEntry>[
            const StaffMenuEntry(
              icon: Icons.access_time_rounded,
              iconBackground: AppColors.infoBackground,
              iconColor: AppColors.infoBlue,
              title: 'Attendance',
              subtitle: 'Clock in/out and shift history',
            ),
            if (session.canAccessIncidents)
              const StaffMenuEntry(
                icon: Icons.report_gmailerrorred_outlined,
                iconBackground: AppColors.urgentBackground,
                iconColor: AppColors.criticalRed,
                title: 'Incidents',
                subtitle: 'My reports & all residence incidents',
              ),
            const StaffMenuEntry(
              icon: Icons.person_outline_rounded,
              iconBackground: AppColors.nightBackground,
              iconColor: AppColors.nightPurple,
              title: 'Profile & Settings',
              subtitle: 'Account, assigned clients & preferences',
            ),
          ];

          return ListView.separated(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: AppDimens.screenPaddingHorizontal,
              vertical: 20,
            ),
            itemCount: entries.length,
            separatorBuilder: (context, index) => SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, 12),
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return StaffMenuTile(
                entry: entry,
                onTap: () => _open(entry.title),
              );
            },
          );
        }),
      ),
    );
  }

  void _open(String title) {
    if (title == 'Attendance') {
      Get.to(() => const StaffAttendancePage());
    } else if (title == 'Incidents') {
      Get.to(() => const StaffIncidentsListPage());
    } else if (title == 'Profile & Settings') {
      Get.to(() => const StaffProfileSettingsPage());
    }
  }
}
