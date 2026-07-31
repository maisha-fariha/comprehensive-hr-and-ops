import 'package:flutter/material.dart';

import 'dashboard/presentation/pages/staff_dashboard_page.dart';
import 'daily_logs/presentation/pages/staff_daily_logs_page.dart';
import 'presentation/pages/staff_mar_tasks_menu_page.dart';
import 'presentation/pages/staff_more_menu_page.dart';
import 'presentation/widgets/staff_bottom_nav_bar.dart';
import 'scheduling/presentation/pages/staff_schedule_page.dart';

/// Root shell for the Staff portal. Owns the bottom navigation bar and
/// switches between its 5 tabs: Home (Dashboard), Schedule, Clients (Daily
/// Logs), MAR/Tasks (a hub for Medication + Tasks & Messages, which share a
/// single bottom-nav slot in the Figma bar) and More (a hub for
/// Attendance/Incidents, which also have no dedicated bottom-nav slot).
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    StaffDashboardPage(),
    StaffSchedulePage(),
    StaffDailyLogsPage(),
    StaffMarTasksMenuPage(),
    StaffMoreMenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
