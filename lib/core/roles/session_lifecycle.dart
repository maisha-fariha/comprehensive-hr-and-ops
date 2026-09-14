import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../features/family/appointments/presentation/controllers/family_appointments_controller.dart';
import '../../features/family/daily_updates/presentation/controllers/family_daily_updates_controller.dart';
import '../../features/family/dashboard/presentation/controllers/family_dashboard_controller.dart';
import '../../features/family/documents/presentation/controllers/family_documents_controller.dart';
import '../../features/family/messages/presentation/controllers/family_messages_controller.dart';
import '../../features/family/profile_settings/presentation/controllers/family_profile_settings_controller.dart';
import '../../features/family/visit_requests/presentation/controllers/family_visit_requests_controller.dart';
import '../../features/family/visit_requests/presentation/controllers/visit_request_details_controller.dart';
import '../../features/hr/attendance/presentation/controllers/attendance_controller.dart';
import '../../features/hr/communication/presentation/controllers/communication_controller.dart';
import '../../features/hr/daily_logs/presentation/controllers/daily_logs_controller.dart';
import '../../features/hr/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../features/hr/incidents/presentation/controllers/incidents_controller.dart';
import '../../features/hr/medication/presentation/controllers/medication_controller.dart';
import '../../features/hr/profile_settings/presentation/controllers/hr_profile_settings_controller.dart';
import '../../features/hr/scheduling/presentation/controllers/scheduling_controller.dart';
import '../../features/hr/tasks_compliance/presentation/controllers/tasks_compliance_controller.dart';
import '../../features/hr/team_reports/presentation/controllers/team_reports_controller.dart';
import '../../features/staff/attendance/presentation/controllers/staff_attendance_controller.dart';
import '../../features/staff/daily_logs/presentation/controllers/daily_note_controller.dart';
import '../../features/staff/daily_logs/presentation/controllers/staff_daily_logs_controller.dart';
import '../../features/staff/dashboard/presentation/controllers/staff_dashboard_controller.dart';
import '../../features/staff/incidents/presentation/controllers/incident_details_controller.dart';
import '../../features/staff/incidents/presentation/controllers/staff_incidents_controller.dart';
import '../../features/staff/medication/presentation/controllers/staff_medication_controller.dart';
import '../../features/staff/profile_settings/presentation/controllers/staff_profile_settings_controller.dart';
import '../../features/staff/scheduling/presentation/controllers/staff_schedule_controller.dart';
import '../../features/staff/tasks_messages/presentation/controllers/tasks_messages_controller.dart';
import '../network/response_cache.dart';

/// Clears portal UI + HTTP cache that would otherwise leak across accounts.
///
/// Two layers previously leaked data between nurse / caregiver / housekeeper:
/// 1. `Get.put(..., permanent: true)` kept controllers after logout
/// 2. `DIHelper.registerController` used GetIt **lazy singletons**, so even
///    after `Get.delete`, `GetIt.instance<T>()` returned the same object with
///    the previous person's loaded state
abstract final class SessionLifecycle {
  static Future<void> reset() async {
    _resetFeatureControllers();
    await _clearHttpCache();
  }

  static Future<void> _clearHttpCache() async {
    try {
      if (GetIt.instance.isRegistered<ResponseCache>()) {
        await GetIt.instance<ResponseCache>().clear();
      }
    } catch (_) {}
  }

  static void _resetFeatureControllers() {
    // Staff
    _reset<StaffDashboardController>();
    _reset<StaffScheduleController>();
    _reset<StaffDailyLogsController>();
    _reset<DailyNoteController>();
    _reset<StaffMedicationController>();
    _reset<TasksMessagesController>();
    _reset<StaffAttendanceController>();
    _reset<StaffIncidentsController>();
    _reset<IncidentDetailsController>();
    _reset<StaffProfileSettingsController>();

    // HR / Manager
    _reset<DashboardController>();
    _reset<SchedulingController>();
    _reset<AttendanceController>();
    _reset<DailyLogsController>();
    _reset<MedicationController>();
    _reset<IncidentsController>();
    _reset<TasksComplianceController>();
    _reset<TeamReportsController>();
    _reset<CommunicationController>();
    _reset<HrProfileSettingsController>();

    // Family
    _reset<FamilyDashboardController>();
    _reset<FamilyDailyUpdatesController>();
    _reset<FamilyDocumentsController>();
    _reset<FamilyAppointmentsController>();
    _reset<FamilyMessagesController>();
    _reset<FamilyVisitRequestsController>();
    _reset<VisitRequestDetailsController>();
    _reset<FamilyProfileSettingsController>();
  }

  static void _reset<T extends Object>() {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>(force: true);
      }
    } catch (_) {}

    // Drop GetIt lazy-singleton instances created before controllers were
    // switched to factories. Harmless no-op for factory registrations.
    try {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<T>()) {
        getIt.resetLazySingleton<T>();
      }
    } catch (_) {}
  }
}
