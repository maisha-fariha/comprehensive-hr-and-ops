import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/permission_gate.dart';
import '../../core/roles/user_session.dart';
import '../../core/widgets/lazy_indexed_tab.dart';
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
  late final Set<int> _opened;

  static const int _scheduleTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _opened = {_currentIndex};
    if (_currentIndex == _scheduleTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyScheduleFocusOrToday();
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _opened.add(index);
      _currentIndex = index;
    });
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

  WidgetBuilder _builderFor(int index) {
    return switch (index) {
      0 => (_) => const ManagerDashboardPage(),
      1 => (_) => const SchedulingPage(),
      2 => (_) => const AttendancePage(),
      3 => (_) => const IncidentsListPage(),
      _ => (_) => const HrMoreMenuPage(),
    };
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
          : firstAllowedTab(length: 5, allowed: allowed, fallback: 4);
      if (!_opened.contains(index)) {
        // Landing tab may change when permissions resolve.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _opened.add(index));
        });
      }
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            for (var i = 0; i < 5; i++)
              LazyIndexedTab(
                active: allowed(i) && _opened.contains(i),
                builder: _builderFor(i),
              ),
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
