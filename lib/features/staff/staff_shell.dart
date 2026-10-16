import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/permission_gate.dart';
import '../../core/roles/user_session.dart';
import 'dashboard/presentation/controllers/staff_dashboard_controller.dart';
import 'dashboard/presentation/pages/staff_dashboard_page.dart';
import 'daily_logs/presentation/pages/staff_daily_logs_page.dart';
import 'presentation/pages/staff_mar_tasks_menu_page.dart';
import 'presentation/pages/staff_more_menu_page.dart';
import 'presentation/widgets/staff_bottom_nav_bar.dart';
import 'scheduling/presentation/pages/staff_schedule_page.dart';

/// Root shell for the Staff portal. Owns the bottom navigation bar and
/// switches between its 5 tabs: Home (Dashboard), Schedule, Daily Logs,
/// MAR/Tasks and More.
///
/// Tabs the signed-in user cannot read are left out of the bar. Home and More
/// stay so there is always a place to land.
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
    _refreshHomeIfReturning();
  }

  void _refreshHomeIfReturning() {
    if (!Get.isRegistered<StaffDashboardController>()) return;
    Get.find<StaffDashboardController>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();

    return Obx(() {
      // Keyed by user so a different staff login never reuses the previous
      // account's IndexedStack / tab Element tree.
      final userKey = session.userId ?? session.email;

      bool allowed(int tab) => staffTabAllowed(session, tab);
      final tabs = <Widget>[
        const StaffDashboardPage(),
        allowed(1)
            ? const StaffSchedulePage()
            : const SizedBox.shrink(),
        allowed(2)
            ? const StaffDailyLogsPage()
            : const SizedBox.shrink(),
        allowed(3)
            ? const StaffMarTasksMenuPage()
            : const SizedBox.shrink(),
        const StaffMoreMenuPage(),
      ];
      final index = allowed(_currentIndex)
          ? _currentIndex.clamp(0, tabs.length - 1)
          : firstAllowedTab(
              length: tabs.length,
              allowed: allowed,
              fallback: 4,
            );

      return Scaffold(
        key: ValueKey('staff-shell-$userKey'),
        body: IndexedStack(
          key: ValueKey('staff-tabs-$userKey'),
          index: index,
          children: tabs,
        ),
        bottomNavigationBar: StaffBottomNavBar(
          currentIndex: index,
          onTap: (value) {
            if (!allowed(value)) return;
            setState(() => _currentIndex = value);
            if (value == 0) _refreshHomeIfReturning();
          },
        ),
      );
    });
  }
}
