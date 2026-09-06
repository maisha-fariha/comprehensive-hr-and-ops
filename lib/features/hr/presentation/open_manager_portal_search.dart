import 'package:get/get.dart';

import '../../common/inbox/domain/entities/portal_search_hit.dart';
import '../../common/inbox/presentation/pages/portal_search_page.dart';
import '../daily_logs/presentation/pages/daily_logs_page.dart';
import '../hr_shell.dart';
import '../medication/presentation/pages/medication_page.dart';
import '../tasks_compliance/presentation/pages/tasks_compliance_page.dart';
import '../team_reports/presentation/pages/team_reports_page.dart';

/// Opens the shared Manager [PortalSearchPage] used by the dashboard search bar.
///
/// Reuse this from any Manager header search icon — do not rebuild the search UI.
void openManagerPortalSearch() {
  Get.to(
    () => PortalSearchPage(
      hint: 'Search staff, shifts, or incidents',
      emptyPrompt: 'Search the residence directory and records.',
      onHit: (hit) {
        Get.back();
        switch (hit.type) {
          case PortalSearchHitType.shift:
            Get.offAll(() => const HrShell(initialIndex: 1));
          case PortalSearchHitType.attendance:
          case PortalSearchHitType.staff:
            Get.offAll(() => const HrShell(initialIndex: 2));
          case PortalSearchHitType.incident:
            Get.offAll(() => const HrShell(initialIndex: 3));
          case PortalSearchHitType.task:
            Get.to(() => const TasksCompliancePage());
          case PortalSearchHitType.medication:
            Get.to(() => const MedicationPage());
          case PortalSearchHitType.client:
            Get.to(() => const DailyLogsPage());
          case PortalSearchHitType.message:
          case PortalSearchHitType.document:
            Get.to(() => const TeamReportsPage());
          case PortalSearchHitType.unknown:
            break;
        }
      },
    ),
  );
}
