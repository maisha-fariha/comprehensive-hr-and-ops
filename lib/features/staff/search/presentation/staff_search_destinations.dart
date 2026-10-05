import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../hr/communication/presentation/pages/communication_page.dart';
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
import '../../medication/presentation/pages/staff_medication_page.dart';
import '../../staff_shell.dart';
import '../../tasks_messages/presentation/pages/staff_tasks_messages_page.dart';
import '../domain/entities/staff_search_record.dart';

/// One entry of the web tenant sidebar (`tenantNavItems`) as listed in the
/// header "Search pages..." palette.
class StaffSearchDestination {
  final String label;

  /// Any one of these grants access (web `can(me, ...permission)`).
  final List<String> permissions;

  /// Tenant module that must be enabled (web `hasModule`).
  final String? module;

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  /// Null when the Staff app has no screen for this web page.
  final VoidCallback? open;

  const StaffSearchDestination({
    required this.label,
    required this.permissions,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.module,
    this.open,
  });

  bool get hasStaffPage => open != null;
}

void _openTab(int index) => Get.offAll(() => StaffShell(initialIndex: index));

/// Web `tenantNavItems` in sidebar order, mapped to Staff screens.
List<StaffSearchDestination> staffSearchDestinations() {
  return [
    StaffSearchDestination(
      label: 'Dashboard',
      permissions: const ['dashboard:read'],
      icon: Icons.dashboard_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      open: () => _openTab(0),
    ),
    StaffSearchDestination(
      label: 'Residences',
      permissions: const ['residences:read'],
      icon: Icons.home_work_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      open: () => Get.to(() => const StaffResidencesPage()),
    ),
    StaffSearchDestination(
      label: 'Clients',
      permissions: const ['clients:read'],
      icon: Icons.groups_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => Get.to(() => const StaffClientsPage()),
    ),
    StaffSearchDestination(
      label: 'Admissions',
      permissions: const ['admissions:read'],
      icon: Icons.how_to_reg_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => Get.to(() => const StaffAdmissionsPage()),
    ),
    const StaffSearchDestination(
      label: 'Users & Access',
      permissions: ['users:read', 'roles:read'],
      icon: Icons.admin_panel_settings_outlined,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
    ),
    StaffSearchDestination(
      label: 'Scheduling',
      permissions: const ['scheduling:read'],
      module: 'scheduling',
      icon: Icons.calendar_month_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => _openTab(1),
    ),
    StaffSearchDestination(
      label: 'Attendance',
      permissions: const ['attendance:read'],
      module: 'attendance',
      icon: Icons.access_time_rounded,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => Get.to(() => const StaffAttendancePage()),
    ),
    StaffSearchDestination(
      label: 'Handovers',
      permissions: const ['shift-handovers:read'],
      module: 'scheduling',
      icon: Icons.swap_horiz_rounded,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => Get.to(() => const StaffShiftHandoversPage()),
    ),
    StaffSearchDestination(
      label: 'Recurring Checks',
      permissions: const ['recurring-checks:read'],
      module: 'scheduling',
      icon: Icons.fact_check_outlined,
      iconBackground: AppColors.urgentBackground,
      iconColor: AppColors.urgentAmber,
      open: () => Get.to(() => const StaffRecurringChecksPage()),
    ),
    StaffSearchDestination(
      label: 'Task Management',
      permissions: const ['tasks:read'],
      icon: Icons.task_alt_rounded,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      open: () => Get.to(() => const StaffTasksMessagesPage()),
    ),
    StaffSearchDestination(
      label: 'Daily Logs',
      permissions: const ['daily-logs:read'],
      icon: Icons.edit_note_rounded,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => _openTab(2),
    ),
    StaffSearchDestination(
      label: 'Emergency',
      permissions: const ['emergency:read'],
      icon: Icons.warning_amber_rounded,
      iconBackground: AppColors.urgentBackground,
      iconColor: AppColors.criticalRed,
      open: () => Get.to(() => const StaffEmergencyPage()),
    ),
    StaffSearchDestination(
      label: 'Incidents',
      permissions: const ['incidents:read'],
      module: 'incidents',
      icon: Icons.report_gmailerrorred_outlined,
      iconBackground: AppColors.urgentBackground,
      iconColor: AppColors.criticalRed,
      open: () => Get.to(() => const StaffIncidentsListPage()),
    ),
    StaffSearchDestination(
      label: 'Medication MAR',
      permissions: const ['mar:read'],
      module: 'mar',
      icon: Icons.medication_outlined,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
      open: () => Get.to(() => const StaffMedicationPage()),
    ),
    StaffSearchDestination(
      label: 'Inventory',
      permissions: const ['inventory:read'],
      module: 'inventory',
      icon: Icons.inventory_2_outlined,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
      open: () => Get.to(() => const StaffInventoryPage()),
    ),
    const StaffSearchDestination(
      label: 'Reports & Analytics',
      permissions: ['reports:read'],
      module: 'reports',
      icon: Icons.insert_chart_outlined_rounded,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
    ),
    const StaffSearchDestination(
      label: 'Compliance & Audit',
      permissions: ['compliance:read'],
      module: 'compliance',
      icon: Icons.verified_user_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
    ),
    StaffSearchDestination(
      label: 'Daily Activity',
      permissions: const ['client-activities:read'],
      icon: Icons.directions_walk_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      open: () => Get.to(() => const StaffDailyActivityPage()),
    ),
    const StaffSearchDestination(
      label: 'Finance & Payroll',
      permissions: ['payroll:read'],
      module: 'payroll',
      icon: Icons.account_balance_wallet_outlined,
      iconBackground: AppColors.urgentBackgroundSoft,
      iconColor: AppColors.urgentAmber,
    ),
    StaffSearchDestination(
      label: 'Documents Management',
      permissions: const ['documents:read'],
      module: 'documents',
      icon: Icons.folder_outlined,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
      open: () => Get.to(() => const StaffDocumentsPage()),
    ),
    StaffSearchDestination(
      label: 'Appointments',
      permissions: const ['appointments:read'],
      module: 'appointments',
      icon: Icons.event_available_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      open: () => Get.to(() => const StaffAppointmentsPage()),
    ),
    StaffSearchDestination(
      label: 'Training',
      permissions: const ['training:read'],
      module: 'training',
      icon: Icons.school_outlined,
      iconBackground: AppColors.urgentBackgroundSoft,
      iconColor: AppColors.urgentAmber,
      open: () => Get.to(() => const StaffTrainingPage()),
    ),
    const StaffSearchDestination(
      label: 'Support & Tickets',
      permissions: ['tickets:view_own', 'tickets:view_tenant'],
      icon: Icons.support_agent_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
    ),
    StaffSearchDestination(
      label: 'Communication',
      permissions: const ['messaging:read'],
      module: 'messaging',
      icon: Icons.forum_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () =>
          Get.to(() => const CommunicationPage(showStaffBottomNav: true)),
    ),
    const StaffSearchDestination(
      label: 'Settings',
      permissions: ['settings:read'],
      icon: Icons.settings_outlined,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
    ),
  ];
}

/// Permission a record group needs before it is listed.
String staffSearchRecordPermission(StaffSearchRecordType type) {
  switch (type) {
    case StaffSearchRecordType.client:
      return 'clients:read';
    case StaffSearchRecordType.document:
      return 'documents:read';
    case StaffSearchRecordType.medication:
      return 'mar:read';
  }
}

String staffSearchRecordGroupLabel(StaffSearchRecordType type) {
  switch (type) {
    case StaffSearchRecordType.client:
      return 'Clients';
    case StaffSearchRecordType.document:
      return 'Documents';
    case StaffSearchRecordType.medication:
      return 'Medications';
  }
}

void openStaffSearchRecord(StaffSearchRecord record) {
  switch (record.type) {
    case StaffSearchRecordType.client:
      Get.to(() => const StaffClientsPage());
    case StaffSearchRecordType.document:
      Get.to(() => const StaffDocumentsPage());
    case StaffSearchRecordType.medication:
      Get.to(() => const StaffMedicationPage());
  }
}
