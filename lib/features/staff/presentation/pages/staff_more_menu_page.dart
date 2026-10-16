import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/roles/permission_gate.dart';
import '../../../../core/roles/user_session.dart';
import '../../attendance/presentation/pages/staff_attendance_page.dart';
import '../../daily_activity/presentation/pages/staff_daily_activity_page.dart';
import '../../extras/presentation/pages/staff_admissions_page.dart';
import '../../extras/presentation/pages/staff_appointments_page.dart';
import '../../extras/presentation/pages/staff_clients_page.dart';
import '../../extras/presentation/pages/staff_documents_page.dart';
import '../../extras/presentation/pages/staff_emergency_page.dart';
import '../../extras/presentation/pages/staff_inventory_page.dart';
import '../../extras/presentation/pages/staff_recurring_checks_page.dart';
import '../../extras/presentation/pages/staff_residences_page.dart';
import '../../extras/presentation/pages/staff_shift_handovers_page.dart';
import '../../extras/presentation/pages/staff_training_page.dart';
import '../../incidents/presentation/pages/staff_incidents_list_page.dart';
import '../../../hr/communication/presentation/pages/communication_page.dart';
import '../open_staff_profile.dart';
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
            if (session.can('residences:read'))
              const StaffMenuEntry(
                icon: Icons.home_work_outlined,
                iconBackground: AppColors.activeBackground,
                iconColor: AppColors.activeGreen,
                title: 'Residence',
                subtitle: 'Your assigned home and residence details',
              ),
            if (session.canAccessClients)
              const StaffMenuEntry(
                icon: Icons.groups_outlined,
                iconBackground: AppColors.infoBackground,
                iconColor: AppColors.infoBlue,
                title: 'Clients',
                subtitle: 'Client directory, profiles, and admissions',
              ),
            if (session.can('recurring-checks:read'))
              const StaffMenuEntry(
                icon: Icons.fact_check_outlined,
                iconBackground: AppColors.urgentBackground,
                iconColor: AppColors.urgentAmber,
                title: 'Recurring Checks',
                subtitle: 'Due recurring checks assigned to you',
              ),
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
                title: 'Daily Activity',
                subtitle: 'Outings, school, programmes, and observations',
              ),
            if (session.canAccessMessaging)
              const StaffMenuEntry(
                icon: Icons.forum_outlined,
                iconBackground: AppColors.infoBackground,
                iconColor: AppColors.infoBlue,
                title: 'Communication',
                subtitle: 'Direct, group, and family conversations',
              ),
            if (session.canAccessDocuments)
              const StaffMenuEntry(
                icon: Icons.folder_outlined,
                iconBackground: AppColors.nightBackground,
                iconColor: AppColors.nightPurple,
                title: 'Documents Management',
                subtitle: 'Care plans, certificates, and filings',
              ),
            if (session.canAccessAppointments)
              const StaffMenuEntry(
                icon: Icons.event_available_outlined,
                iconBackground: AppColors.activeBackground,
                iconColor: AppColors.activeGreen,
                title: 'Appointments',
                subtitle: 'Visits and scheduled appointments',
              ),
            if (session.canAccessTraining)
              const StaffMenuEntry(
                icon: Icons.school_outlined,
                iconBackground: AppColors.urgentBackgroundSoft,
                iconColor: AppColors.urgentAmber,
                title: 'Training',
                subtitle: 'Assignments, quizzes, and certificates',
              ),
            if (session.canAccessInventory)
              const StaffMenuEntry(
                icon: Icons.inventory_2_outlined,
                iconBackground: AppColors.nightBackground,
                iconColor: AppColors.nightPurple,
                title: 'Inventory',
                subtitle: 'Stock on hand at your residence',
              ),
            if (session.can('admissions:read'))
              const StaffMenuEntry(
                icon: Icons.how_to_reg_outlined,
                iconBackground: AppColors.infoBackground,
                iconColor: AppColors.infoBlue,
                title: 'Admissions',
                subtitle: 'Referrals and assessments',
              ),
            if (session.can('attendance:read'))
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
      case 'Residence':
        openPermittedPage(
          title: title,
          anyOf: const ['residences:read'],
          builder: () => const StaffResidencesPage(),
        );
      case 'Clients':
        openPermittedPage(
          title: title,
          anyOf: const ['clients:read'],
          builder: () => const StaffClientsPage(),
        );
      case 'Recurring Checks':
        openPermittedPage(
          title: title,
          anyOf: const ['recurring-checks:read'],
          builder: () => const StaffRecurringChecksPage(),
        );
      case 'Emergency':
        openPermittedPage(
          title: title,
          anyOf: const ['emergency:read', 'emergency:raise'],
          builder: () => const StaffEmergencyPage(),
        );
      case 'Shift handovers':
        openPermittedPage(
          title: title,
          anyOf: const ['shift-handovers:read'],
          builder: () => const StaffShiftHandoversPage(),
        );
      case 'Daily Activity':
        openPermittedPage(
          title: title,
          anyOf: const ['client-activities:read'],
          builder: () => const StaffDailyActivityPage(),
        );
      case 'Communication':
        openPermittedPage(
          title: title,
          anyOf: const ['messaging:read'],
          builder: () => const CommunicationPage(showStaffBottomNav: true),
        );
      case 'Documents Management':
        openPermittedPage(
          title: title,
          anyOf: const ['documents:read'],
          builder: () => const StaffDocumentsPage(),
        );
      case 'Appointments':
        openPermittedPage(
          title: title,
          anyOf: const ['appointments:read'],
          builder: () => const StaffAppointmentsPage(),
        );
      case 'Training':
        openPermittedPage(
          title: title,
          anyOf: const ['training:read'],
          builder: () => const StaffTrainingPage(),
        );
      case 'Inventory':
        openPermittedPage(
          title: title,
          anyOf: const ['inventory:read'],
          builder: () => const StaffInventoryPage(),
        );
      case 'Admissions':
        openPermittedPage(
          title: title,
          anyOf: const ['admissions:read'],
          builder: () => const StaffAdmissionsPage(),
        );
      case 'Attendance':
        openPermittedPage(
          title: title,
          anyOf: const ['attendance:read'],
          builder: () => const StaffAttendancePage(),
        );
      case 'Incidents':
        openPermittedPage(
          title: title,
          anyOf: const ['incidents:read'],
          builder: () => const StaffIncidentsListPage(),
        );
      case 'Profile & Settings':
        openStaffProfile();
    }
  }
}
