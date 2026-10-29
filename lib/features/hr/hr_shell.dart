import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/permission_gate.dart';
import '../../core/roles/user_session.dart';
import 'attendance/presentation/pages/attendance_page.dart';
import 'dashboard/presentation/pages/manager_dashboard_page.dart';
import 'incidents/presentation/pages/incidents_list_page.dart';
import 'presentation/pages/hr_more_menu_page.dart';
import 'presentation/widgets/hr_bottom_nav_bar.dart';
import 'scheduling/presentation/controllers/scheduling_controller.dart';
import 'scheduling/presentation/pages/scheduling_page.dart';

/// Root shell for the HR/Manager portal. Owns the bottom navigation bar and
/// switches between its 5 tabs: Home (Dashboard), Schedule, Attendance,
/// Alerts (Incidents) and More (modules that don't have a bottom-nav slot).
class HrShell extends StatefulWidget {
  /// Tab to show when the shell is (re)opened — used by pushed screens that
  /// host their own copy of [HrBottomNavBar] (e.g. Daily Logs).
  final int initialIndex;

  /// When opened from a shift notification, select this day on Schedule.
  final DateTime? scheduleFocusDate;

  /// Optional shift id when the notification has no `shiftStartsAt`.
  final String? scheduleFocusShiftId;

  const HrShell({
    super.key,
    this.initialIndex = 0,
    this.scheduleFocusDate,
    this.scheduleFocusShiftId,
  });

  @override
  State<HrShell> createState() => _HrShellState();
}

class _HrShellState extends State<HrShell> {
  late int _currentIndex;

  static const int _scheduleTabIndex = 1;

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
    if (_currentIndex == _scheduleTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyScheduleFocusOrToday();
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == _scheduleTabIndex) {
      _applyScheduleFocusOrToday(fromBottomNav: true);
    }
  }

  void _applyScheduleFocusOrToday({bool fromBottomNav = false}) {
    if (!Get.isRegistered<SchedulingController>()) return;
    final controller = Get.find<SchedulingController>();
    final focus = widget.scheduleFocusDate;
    // Bottom-nav re-taps still reset to today; notification opens keep the day.
    if (!fromBottomNav && focus != null) {
      controller.selectCalendarDay(focus);
      return;
    }
    if (!fromBottomNav &&
        (widget.scheduleFocusShiftId != null &&
            widget.scheduleFocusShiftId!.isNotEmpty)) {
      // Manager path: without a date, fall back to today rather than blocking.
      controller.resetCalendarToToday();
      return;
    }
    controller.resetCalendarToToday();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = Get.isRegistered<UserSession>()
          ? Get.find<UserSession>()
          : null;
      bool allowed(int index) =>
          session == null || managerTabAllowed(session, index);
      final index = allowed(_currentIndex)
          ? _currentIndex
          : firstAllowedTab(length: _tabs.length, allowed: allowed, fallback: 4);
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              allowed(i) ? _tabs[i] : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: HrBottomNavBar(
          currentIndex: index,
          onTap: (value) {
            if (!allowed(value)) return;
            _onBottomNavTap(value);
          },
          alertsBadgeCount: hrAlertsBadgeCount(),
        ),
      );
    });
  }
}
