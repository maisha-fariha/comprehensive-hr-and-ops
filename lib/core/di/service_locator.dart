import '../../features/hr/attendance/di/attendance_di.dart';
import '../../features/hr/daily_logs/di/daily_logs_di.dart';
import '../../features/hr/dashboard/di/dashboard_di.dart';
import '../../features/hr/incidents/di/incidents_di.dart';
import '../../features/hr/medication/di/medication_di.dart';
import '../../features/hr/scheduling/di/scheduling_di.dart';
import '../../features/hr/tasks_compliance/di/tasks_compliance_di.dart';
import '../../features/hr/team_reports/di/team_reports_di.dart';

/// Registers every feature module's dependencies. Call once from `main()`
/// before `runApp`. New feature modules (Staff, Family, other HR screens)
/// should add their own `setup...Dependencies()` call here.
Future<void> setupAppDependencies() async {
  await setupHrDashboardDependencies();
  await setupHrSchedulingDependencies();
  await setupHrAttendanceDependencies();
  await setupHrDailyLogsDependencies();
  await setupHrIncidentsDependencies();
  await setupHrMedicationDependencies();
  await setupHrTasksComplianceDependencies();
  await setupHrTeamReportsDependencies();
}
