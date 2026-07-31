import 'package:flutter/material.dart';

import 'attendance/presentation/pages/attendance_page.dart';
import 'dashboard/presentation/pages/manager_dashboard_page.dart';
import 'incidents/presentation/pages/incidents_list_page.dart';
import 'presentation/pages/hr_more_menu_page.dart';
import 'presentation/widgets/hr_bottom_nav_bar.dart';
import 'scheduling/presentation/pages/scheduling_page.dart';

/// Root shell for the HR/Manager portal. Owns the bottom navigation bar and
/// switches between its 5 tabs: Home (Dashboard), Schedule, Attendance,
/// Alerts (Incidents) and More (a hub for Daily Logs/Medication/Tasks &
/// Compliance/Team & Reports, which don't have a dedicated bottom-nav slot
/// in the Figma bar).
class HrShell extends StatefulWidget {
  const HrShell({super.key});

  @override
  State<HrShell> createState() => _HrShellState();
}

class _HrShellState extends State<HrShell> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    ManagerDashboardPage(),
    SchedulingPage(),
    AttendancePage(),
    IncidentsListPage(),
    HrMoreMenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: HrBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
