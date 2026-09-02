import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/user_session.dart';
import 'dashboard/presentation/pages/staff_dashboard_page.dart';
import 'daily_logs/presentation/pages/staff_daily_logs_page.dart';
import 'presentation/pages/staff_mar_tasks_menu_page.dart';
import 'presentation/pages/staff_more_menu_page.dart';
import 'presentation/pages/staff_unavailable_page.dart';
import 'presentation/widgets/staff_bottom_nav_bar.dart';
import 'scheduling/presentation/pages/staff_schedule_page.dart';

/// Root shell for the Staff portal. Owns the bottom navigation bar and
/// switches between its 5 tabs: Home (Dashboard), Schedule, Clients (Daily
/// Logs), MAR/Tasks and More.
///
/// The Clients slot stays in the bar so nav indices remain stable, but the
/// body is replaced when `/mobile/home` permissions do not include clients
/// (housekeeper).
class StaffShell extends StatefulWidget {
  final int initialIndex;

  const StaffShell({super.key, this.initialIndex = 0});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();

    return Obx(() {
      final tabs = <Widget>[
        const StaffDashboardPage(),
        const StaffSchedulePage(),
        session.canAccessClients
            ? const StaffDailyLogsPage()
            : const StaffUnavailablePage(
                title: 'Clients',
                message:
                    'Client records and daily logs are not part of this role.',
              ),
        const StaffMarTasksMenuPage(),
        const StaffMoreMenuPage(),
      ];
      final index = _currentIndex.clamp(0, tabs.length - 1);

      return Scaffold(
        body: IndexedStack(index: index, children: tabs),
        bottomNavigationBar: StaffBottomNavBar(
          currentIndex: index,
          onTap: (value) => setState(() => _currentIndex = value),
        ),
      );
    });
  }
}
