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
  /// Tab to show when the shell is (re)opened — used by pushed screens that
  /// host their own copy of [HrBottomNavBar] (e.g. Daily Logs).
  final int initialIndex;

  const HrShell({super.key, this.initialIndex = 0});

  @override
  State<HrShell> createState() => _HrShellState();
}

class _HrShellState extends State<HrShell> {
  late int _currentIndex;

  static const _tabs = <Widget>[
    ManagerDashboardPage(),
    SchedulingPage(),
    AttendancePage(),
    IncidentsListPage(),
    HrMoreMenuPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

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
