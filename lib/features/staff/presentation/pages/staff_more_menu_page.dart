import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/roles/user_role.dart';
import '../../../../core/roles/user_session.dart';
import '../../attendance/presentation/pages/staff_attendance_page.dart';
import '../../extras/presentation/pages/staff_admissions_page.dart';
import '../../extras/presentation/pages/staff_client_activities_page.dart';
import '../../extras/presentation/pages/staff_emergency_page.dart';
import '../../extras/presentation/pages/staff_inventory_page.dart';
import '../../extras/presentation/pages/staff_shift_handovers_page.dart';
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
            if (session.canReadEmergency)
              const StaffMenuEntry(
                icon: Icons.warning_amber_rounded,
                iconBackground: AppColors.urgentBackground,
                iconColor: AppColors.criticalRed,
                title: 'Emergency',
                subtitle: 'Active alarms and response alerts',
              ),
            if (session.canAccessHandovers)
              const StaffMenuEntry(
                icon: Icons.swap_horiz_rounded,
                iconBackground: AppColors.infoBackground,
                iconColor: AppColors.infoBlue,
                title: 'Shift handovers',
                subtitle: 'Write and acknowledge handovers',
              ),
            if (session.canAccessClientActivities)
              const StaffMenuEntry(
                icon: Icons.directions_walk_outlined,
                iconBackground: AppColors.activeBackground,
                iconColor: AppColors.activeGreen,
                title: 'Client activities',
                subtitle: 'Record outings, school, and programs',
              ),
            if (session.canAccessInventory)
              const StaffMenuEntry(
                icon: Icons.inventory_2_outlined,
                iconBackground: AppColors.nightBackground,
                iconColor: AppColors.nightPurple,
                title: 'Inventory',
                subtitle: 'Stock on hand at your residence',
              ),
            if (session.canAccessAdmissions &&
                session.staffKind == StaffKind.nurse)
              const StaffMenuEntry(
                icon: Icons.how_to_reg_outlined,
                iconBackground: AppColors.infoBackground,
                iconColor: AppColors.infoBlue,
                title: 'Admissions',
                subtitle: 'Referrals and assessments',
              ),
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
    switch (title) {
      case 'Emergency':
        Get.to(() => const StaffEmergencyPage());
      case 'Shift handovers':
        Get.to(() => const StaffShiftHandoversPage());
      case 'Client activities':
        Get.to(() => const StaffClientActivitiesPage());
      case 'Inventory':
        Get.to(() => const StaffInventoryPage());
      case 'Admissions':
        Get.to(() => const StaffAdmissionsPage());
      case 'Attendance':
        Get.to(() => const StaffAttendancePage());
      case 'Incidents':
        Get.to(() => const StaffIncidentsListPage());
      case 'Profile & Settings':
        Get.to(() => const StaffProfileSettingsPage());
    }
  }
}
