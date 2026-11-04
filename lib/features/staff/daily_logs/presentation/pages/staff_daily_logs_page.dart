import 'package:flutter/material.dart';

import '../../../../hr/daily_logs/presentation/pages/daily_logs_page.dart';

/// Staff Daily Logs tab — same web board (Today / Review / Activities) as
/// managers. Role differences come from `/mobile/me` permissions only.
class StaffDailyLogsPage extends StatelessWidget {
  const StaffDailyLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DailyLogsPage(
      // StaffShell already owns the bottom bar for this tab.
      showBottomNav: false,
      staffPortal: true,
    );
  }
}
