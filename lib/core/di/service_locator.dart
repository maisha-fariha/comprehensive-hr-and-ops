import '../../features/hr/attendance/di/attendance_di.dart';
import '../../features/hr/daily_logs/di/daily_logs_di.dart';
import '../../features/hr/dashboard/di/dashboard_di.dart';
import '../../features/hr/incidents/di/incidents_di.dart';
import '../../features/hr/medication/di/medication_di.dart';
import '../../features/hr/scheduling/di/scheduling_di.dart';
import '../../features/hr/tasks_compliance/di/tasks_compliance_di.dart';
import '../../features/hr/team_reports/di/team_reports_di.dart';
import '../../features/family/appointments/di/family_appointments_di.dart';
import '../../features/family/daily_updates/di/family_daily_updates_di.dart';
import '../../features/family/dashboard/di/family_dashboard_di.dart';
import '../../features/family/documents/di/family_documents_di.dart';
import '../../features/family/messages/di/family_messages_di.dart';
import '../../features/family/profile_settings/di/family_profile_settings_di.dart';
import '../../features/family/visit_requests/di/family_visit_requests_di.dart';
import '../../features/staff/attendance/di/staff_attendance_di.dart';
import '../../features/staff/daily_logs/di/staff_daily_logs_di.dart';
import '../../features/staff/dashboard/di/staff_dashboard_di.dart';
import '../../features/staff/incidents/di/staff_incidents_di.dart';
import '../../features/staff/medication/di/staff_medication_di.dart';
import '../../features/staff/scheduling/di/staff_scheduling_di.dart';
import '../../features/staff/tasks_messages/di/staff_tasks_messages_di.dart';

/// Registers every feature module's dependencies. Call once from `main()`
/// before `runApp`. New feature modules should add their own
/// `setup...Dependencies()` call here.
Future<void> setupAppDependencies() async {
  await setupHrDashboardDependencies();
  await setupHrSchedulingDependencies();
  await setupHrAttendanceDependencies();
  await setupHrDailyLogsDependencies();
  await setupHrIncidentsDependencies();
  await setupHrMedicationDependencies();
  await setupHrTasksComplianceDependencies();
  await setupHrTeamReportsDependencies();

  await setupStaffDashboardDependencies();
  await setupStaffSchedulingDependencies();
  await setupStaffAttendanceDependencies();
  await setupStaffDailyLogsDependencies();
  await setupStaffIncidentsDependencies();
  await setupStaffMedicationDependencies();
  await setupStaffTasksMessagesDependencies();

  await setupFamilyDashboardDependencies();
  await setupFamilyDailyUpdatesDependencies();
  await setupFamilyAppointmentsDependencies();
  await setupFamilyMessagesDependencies();
  await setupFamilyVisitRequestsDependencies();
  await setupFamilyDocumentsDependencies();
  await setupFamilyProfileSettingsDependencies();
}
