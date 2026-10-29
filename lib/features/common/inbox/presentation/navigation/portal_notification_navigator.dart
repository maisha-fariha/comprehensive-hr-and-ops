import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_role.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/appointments/presentation/pages/hr_appointments_page.dart';
import '../../../../hr/clients/presentation/pages/clients_page.dart';
import '../../../../hr/communication/presentation/pages/communication_page.dart';
import '../../../../hr/daily_logs/presentation/pages/daily_logs_page.dart';
import '../../../../hr/documents/presentation/pages/hr_documents_page.dart';
import '../../../../hr/emergency/presentation/pages/emergency_page.dart';
import '../../../../hr/handovers/presentation/pages/handovers_page.dart';
import '../../../../hr/hr_shell.dart';
import '../../../../hr/inventory/presentation/pages/inventory_page.dart';
import '../../../../hr/medication/presentation/pages/medication_page.dart';
import '../../../../hr/recurring_checks/presentation/pages/recurring_checks_page.dart';
import '../../../../hr/residences/presentation/pages/residences_page.dart';
import '../../../../hr/tasks_compliance/presentation/pages/tasks_compliance_page.dart';
import '../../../../hr/training/presentation/pages/hr_training_page.dart';
import '../../../../staff/attendance/presentation/pages/staff_attendance_page.dart';
import '../../../../staff/extras/presentation/pages/staff_appointments_page.dart';
import '../../../../staff/extras/presentation/pages/staff_clients_page.dart';
import '../../../../staff/extras/presentation/pages/staff_documents_page.dart';
import '../../../../staff/extras/presentation/pages/staff_emergency_page.dart';
import '../../../../staff/extras/presentation/pages/staff_inventory_page.dart';
import '../../../../staff/extras/presentation/pages/staff_recurring_checks_page.dart';
import '../../../../staff/extras/presentation/pages/staff_residences_page.dart';
import '../../../../staff/extras/presentation/pages/staff_shift_handovers_page.dart';
import '../../../../staff/extras/presentation/pages/staff_training_page.dart';
import '../../../../staff/incidents/presentation/pages/staff_incidents_list_page.dart';
import '../../../../staff/medication/presentation/pages/staff_medication_page.dart';
import '../../../../staff/staff_shell.dart';
import '../../../../staff/tasks_messages/presentation/pages/staff_tasks_messages_page.dart';
import '../../domain/entities/portal_notification.dart';
import 'shift_notification_focus.dart';

/// Opens the staff or manager screen for a tapped notification.
///
/// Same idea as the web bell: `entityType` / `eventKey` picks the module.
/// Types with no screen in this app are left on the list (still marked read).
abstract final class PortalNotificationNavigator {
  static void open(PortalNotification notification) {
    if (!Get.isRegistered<UserSession>()) return;
    final role = Get.find<UserSession>().role;
    if (role == UserRole.family) return;
    final type = _entityType(notification);
    if (type == null) return;
    final staff = role == UserRole.staff;
    switch (type) {
      case 'shift':
      case 'shift_swap':
        final focus = ShiftNotificationFocus.fromNotification(notification);
        Get.offAll(
          () => staff
              ? StaffShell(
                  initialIndex: 1,
                  scheduleFocusDate: focus.date,
                  scheduleFocusShiftId: focus.shiftId,
                )
              : HrShell(
                  initialIndex: 1,
                  scheduleFocusDate: focus.date,
                  scheduleFocusShiftId: focus.shiftId,
                ),
        );
      case 'incident':
        if (staff) {
          Get.to(() => const StaffIncidentsListPage());
        } else {
          Get.offAll(() => const HrShell(initialIndex: 3));
        }
      case 'attendance':
        if (staff) {
          Get.to(() => const StaffAttendancePage());
        } else {
          Get.offAll(() => const HrShell(initialIndex: 2));
        }
      case 'daily_log':
        if (staff) {
          Get.offAll(() => const StaffShell(initialIndex: 2));
        } else {
          Get.to(() => const DailyLogsPage());
        }
      default:
        final page = _page(type, staff);
        if (page != null) Get.to(() => page);
    }
  }

  static Widget? _page(String type, bool staff) {
    return switch (type) {
      'appointment' => staff
          ? const StaffAppointmentsPage()
          : const HrAppointmentsPage(),
      'task' =>
        staff ? const StaffTasksMessagesPage() : const TasksCompliancePage(),
      'recurring_check' => staff
          ? const StaffRecurringChecksPage()
          : const RecurringChecksPage(),
      'emergency_alert' =>
        staff ? const StaffEmergencyPage() : const EmergencyPage(),
      'document' =>
        staff ? const StaffDocumentsPage() : const HrDocumentsPage(),
      'conversation' => staff
          ? const CommunicationPage(showStaffBottomNav: true)
          : const CommunicationPage(),
      'medication' =>
        staff ? const StaffMedicationPage() : const MedicationPage(),
      'handover' =>
        staff ? const StaffShiftHandoversPage() : const HandoversPage(),
      'client' => staff ? const StaffClientsPage() : const ClientsPage(),
      'residence' =>
        staff ? const StaffResidencesPage() : const ResidencesPage(),
      'training' =>
        staff ? const StaffTrainingPage() : const HrTrainingPage(),
      'inventory' =>
        staff ? const StaffInventoryPage() : const InventoryPage(),
      _ => null,
    };
  }

  static String? _entityType(PortalNotification notification) {
    final explicit = notification.entityType?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return _normalize(explicit);
    }
    final key = notification.eventKey ??
        (notification.meta['eventKey'] is String
            ? notification.meta['eventKey'] as String
            : null);
    if (key == null || key.isEmpty) return null;
    if (key.startsWith('scheduling.') || key.startsWith('shifts.')) {
      return 'shift';
    }
    if (key.startsWith('appointments.')) return 'appointment';
    if (key.startsWith('tasks.')) return 'task';
    if (key.startsWith('recurring_checks.') || key.startsWith('recurring.')) {
      return 'recurring_check';
    }
    if (key.startsWith('emergency')) return 'emergency_alert';
    if (key.startsWith('incidents.')) return 'incident';
    if (key.startsWith('attendance.')) return 'attendance';
    if (key.startsWith('documents.')) return 'document';
    if (key.startsWith('messaging.')) return 'conversation';
    if (key.startsWith('mar.') || key.startsWith('medication')) {
      return 'medication';
    }
    if (key.startsWith('handover')) return 'handover';
    if (key.startsWith('daily_logs.') || key.startsWith('care.')) {
      return 'daily_log';
    }
    if (key.startsWith('clients.')) return 'client';
    if (key.startsWith('residences.')) return 'residence';
    if (key.startsWith('training.')) return 'training';
    if (key.startsWith('inventory.')) return 'inventory';
    return null;
  }

  static String _normalize(String raw) {
    final value = raw.toLowerCase().replaceAll('-', '_');
    return switch (value) {
      'medication_chart' || 'mar' => 'medication',
      'message' => 'conversation',
      'daily_logs' => 'daily_log',
      'shift_swap' || 'shiftswap' => 'shift_swap',
      'shift_handover' || 'handovers' => 'handover',
      'emergency' => 'emergency_alert',
      'training_course' || 'training_assignment' || 'course' => 'training',
      _ => value,
    };
  }

  const PortalNotificationNavigator._();
}
