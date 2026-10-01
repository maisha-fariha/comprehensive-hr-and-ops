import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/roles/user_session.dart';
import '../admissions/presentation/pages/admissions_page.dart';
import '../appointments/presentation/pages/hr_appointments_page.dart';
import '../clients/presentation/pages/clients_page.dart';
import '../communication/presentation/pages/communication_page.dart';
import '../daily_activity/presentation/pages/daily_activity_page.dart';
import '../daily_logs/presentation/pages/daily_logs_page.dart';
import '../documents/presentation/pages/hr_documents_page.dart';
import '../emergency/presentation/pages/emergency_page.dart';
import '../handovers/presentation/pages/handovers_page.dart';
import '../hr_shell.dart';
import '../inventory/presentation/pages/inventory_page.dart';
import '../medication/presentation/pages/medication_page.dart';
import '../training/presentation/pages/hr_training_page.dart';
import '../profile_settings/presentation/pages/hr_profile_settings_page.dart';
import '../recurring_checks/presentation/pages/recurring_checks_page.dart';
import '../residences/presentation/pages/residences_page.dart';
import '../tasks_compliance/presentation/pages/tasks_compliance_page.dart';
import '../team_reports/presentation/pages/team_reports_page.dart';

/// A page the Manager can navigate to from the More menu or the
/// "Search pages" sheet on the dashboard.
class ManagerDestination {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback open;

  /// Extra words matched by the "Search pages" sheet.
  final List<String> keywords;

  /// Listed in the More menu (bottom-nav tabs are not).
  final bool inMoreMenu;

  const ManagerDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.open,
    this.keywords = const [],
    this.inMoreMenu = true,
  });

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        subtitle.toLowerCase().contains(q) ||
        keywords.any((k) => k.contains(q));
  }
}

UserSession? _session() {
  try {
    return Get.find<UserSession>();
  } catch (_) {
    return null;
  }
}

void _openTab(int index) => Get.offAll(() => HrShell(initialIndex: index));

/// Every manager destination the signed-in user has permission to open.
List<ManagerDestination> managerDestinations() {
  final session = _session();
  bool can(String permission) => session?.can(permission) ?? true;

  return [
    ManagerDestination(
      title: 'Dashboard',
      subtitle: 'Today at a glance',
      icon: Icons.dashboard_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => _openTab(0),
      keywords: const ['home', 'overview'],
      inMoreMenu: false,
    ),
    if (can('residences'))
      ManagerDestination(
        title: 'Residences',
        subtitle: 'Homes, capacity & rooms',
        icon: Icons.home_work_outlined,
        iconBackground: AppColors.quickActionCreateShiftBg,
        iconColor: AppColors.secondaryTeal,
        open: () => Get.to(() => const ResidencesPage()),
        keywords: const ['homes', 'beds', 'rooms', 'houses'],
      ),
    if (session?.canAccessClients ?? true)
      ManagerDestination(
        title: 'Clients',
        subtitle: 'Client directory & care profiles',
        icon: Icons.people_outline_rounded,
        iconBackground: AppColors.activeBackground,
        iconColor: AppColors.activeGreen,
        open: () => Get.to(() => const ClientsPage()),
        keywords: const ['residents', 'directory', 'care plan'],
      ),
    if (can('admissions:read'))
      ManagerDestination(
        title: 'Admissions',
        subtitle: 'Referrals, waitlist, intake forms and admitting',
        icon: Icons.person_add_alt_1_outlined,
        iconBackground: AppColors.quickActionCreateShiftBg,
        iconColor: AppColors.secondaryTeal,
        open: () => Get.to(() => const AdmissionsPage()),
        keywords: const ['admissions', 'admission', 'referral', 'referrals', 'waitlist', 'intake', 'admit'],
      ),
    ManagerDestination(
      title: 'Scheduling',
      subtitle: 'Shifts, coverage & swap requests',
      icon: Icons.calendar_month_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => _openTab(1),
      keywords: const ['schedule', 'shifts', 'rota'],
      inMoreMenu: false,
    ),
    ManagerDestination(
      title: 'Attendance',
      subtitle: 'Check-ins, lateness & overtime',
      icon: Icons.access_time_rounded,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      open: () => _openTab(2),
      keywords: const ['clock', 'timesheet'],
      inMoreMenu: false,
    ),
    ManagerDestination(
      title: 'Incidents',
      subtitle: 'Alerts & incident reports',
      icon: Icons.report_gmailerrorred_rounded,
      iconBackground: AppColors.criticalBackgroundSoft,
      iconColor: AppColors.criticalRed,
      open: () => _openTab(3),
      keywords: const ['alerts'],
      inMoreMenu: false,
    ),
    if (can('emergency:read'))
      ManagerDestination(
        title: 'Emergency',
        subtitle: 'Raised alarms and who is responding',
        icon: Icons.crisis_alert_rounded,
        iconBackground: AppColors.criticalBackgroundSoft,
        iconColor: AppColors.criticalRed,
        open: () => Get.to(() => const EmergencyPage()),
        keywords: const ['emergency', 'alarm', 'alarms', 'sos', 'alert'],
      ),
    ManagerDestination(
      title: 'Daily Logs',
      subtitle: 'Review queue, missing logs & resident days',
      icon: Icons.assignment_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      open: () => Get.to(() => const DailyLogsPage()),
      keywords: const ['handovers', 'logs', 'notes'],
    ),
    if (can('shift-handovers:read'))
      ManagerDestination(
        title: 'Shift Handovers',
        subtitle: 'What one shift tells the next',
        icon: Icons.edit_note_rounded,
        iconBackground: AppColors.activeBackground,
        iconColor: AppColors.secondaryTeal,
        open: () => Get.to(() => const HandoversPage()),
        keywords: const ['handover', 'handovers', 'shift notes'],
      ),
    if (can('recurring-checks:read'))
      ManagerDestination(
        title: 'Recurring Checks',
        subtitle: 'Scheduled resident checks, due and recorded',
        icon: Icons.timer_outlined,
        iconBackground: AppColors.activeBackground,
        iconColor: AppColors.secondaryTeal,
        open: () => Get.to(() => const RecurringChecksPage()),
        keywords: const ['recurring', 'checks', 'welfare', 'vitals', 'schedule'],
      ),
    if (can('mar:read'))
      ManagerDestination(
        title: 'Medication',
        subtitle: 'MAR oversight across all residences',
        icon: Icons.medication_outlined,
        iconBackground: AppColors.activeBackground,
        iconColor: AppColors.activeGreen,
        open: () => Get.to(() => const MedicationPage()),
        keywords: const ['mar', 'meds'],
      ),
    if (can('client-activities:read'))
      ManagerDestination(
        title: 'Daily Activity',
        subtitle: 'What residents did — outings, programmes and observations',
        icon: Icons.monitor_heart_outlined,
        iconBackground: AppColors.quickActionCreateShiftBg,
        iconColor: AppColors.secondaryTeal,
        open: () => Get.to(() => const DailyActivityPage()),
        keywords: const ['activity', 'activities', 'daily activity', 'outing', 'programme', 'school', 'resident history'],
      ),
    if (can('appointments:read'))
      ManagerDestination(
        title: 'Appointments',
        subtitle: 'Family visit requests, approvals and bookings',
        icon: Icons.event_available_rounded,
        iconBackground: AppColors.urgentBackground,
        iconColor: AppColors.urgentAmber,
        open: () => Get.to(() => const HrAppointmentsPage()),
        keywords: const ['appointments', 'appointment', 'visits', 'family visit', 'approvals', 'booking'],
      ),
    if (can('inventory:read'))
      ManagerDestination(
        title: 'Inventory',
        subtitle: 'Stock, counts, transfers & purchasing',
        icon: Icons.inventory_2_outlined,
        iconBackground: AppColors.urgentBackground,
        iconColor: AppColors.urgentAmber,
        open: () => Get.to(() => const InventoryPage()),
        keywords: const ['inventory', 'stock', 'supplies', 'items', 'counts', 'transfers', 'purchasing', 'orders', 'suppliers'],
      ),
    if (can('documents:read'))
      ManagerDestination(
        title: 'Documents',
        subtitle: 'Certificates, care plans & policies on file',
        icon: Icons.folder_copy_outlined,
        iconBackground: AppColors.infoBackground,
        iconColor: AppColors.infoBlue,
        open: () => Get.to(() => const HrDocumentsPage()),
        keywords: const ['documents', 'documentation', 'certificates', 'files', 'compliance', 'expiry', 'registry'],
      ),
    if (can('training:read'))
      ManagerDestination(
        title: 'Training',
        subtitle: 'Courses, assignments, sittings & certificates',
        icon: Icons.school_outlined,
        iconBackground: AppColors.nightBackground,
        iconColor: AppColors.nightPurple,
        open: () => Get.to(() => const HrTrainingPage()),
        keywords: const ['training', 'course', 'courses', 'certificate', 'quiz', 'assignment', 'learning'],
      ),
    ManagerDestination(
      title: 'Tasks & Compliance',
      subtitle: 'Due tasks, compliance checks & corrective actions',
      icon: Icons.fact_check_outlined,
      iconBackground: AppColors.urgentBackground,
      iconColor: AppColors.urgentAmber,
      open: () => Get.to(() => const TasksCompliancePage()),
      keywords: const ['tasks', 'compliance', 'audit'],
    ),
    ManagerDestination(
      title: 'Team & Reports',
      subtitle: 'Staff roster, reports & messages',
      icon: Icons.groups_outlined,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
      open: () => Get.to(() => const TeamReportsPage()),
      keywords: const ['staff', 'users', 'reports'],
    ),
    ManagerDestination(
      title: 'Communication',
      subtitle: 'Announcements & messages',
      icon: Icons.chat_bubble_outline_rounded,
      iconBackground: AppColors.quickActionMessageBg,
      iconColor: AppColors.quickActionMessageIcon,
      open: () => Get.to(() => const CommunicationPage()),
      keywords: const ['messages', 'chat', 'announcements'],
      inMoreMenu: false,
    ),
    ManagerDestination(
      title: 'Profile & Settings',
      subtitle: 'Account, residences & preferences',
      icon: Icons.person_outline_rounded,
      iconBackground: AppColors.criticalBackgroundSoft,
      iconColor: AppColors.criticalRed,
      open: () => Get.to(() => const HrProfileSettingsPage()),
      keywords: const ['profile', 'password', 'account', 'settings'],
    ),
  ];
}
