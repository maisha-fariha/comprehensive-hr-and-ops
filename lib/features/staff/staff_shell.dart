import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/permission_gate.dart';
import '../../core/roles/user_session.dart';
import '../../core/widgets/lazy_indexed_tab.dart';
import 'attendance/presentation/pages/staff_attendance_page.dart';
import 'dashboard/presentation/controllers/staff_dashboard_controller.dart';
import 'dashboard/presentation/pages/staff_dashboard_page.dart';
import 'daily_logs/presentation/pages/staff_daily_logs_page.dart';
import 'presentation/pages/staff_mar_tasks_menu_page.dart';
import 'presentation/pages/staff_more_menu_page.dart';
import 'presentation/widgets/staff_bottom_nav_bar.dart';
import 'scheduling/presentation/pages/staff_schedule_page.dart';

/// Root shell for the Staff portal. Owns the bottom navigation bar and
/// switches between its tabs: Home, Schedule, Attendance, Daily Logs,
/// MAR/Tasks and More.
///
/// Tabs the signed-in user cannot read are left out of the bar. Home and More
/// stay so there is always a place to land.
///
/// Unvisited tabs are not built (no controller / API load) until first open.
class StaffShell extends StatefulWidget {
  final int initialIndex;

  /// BUG_Report001 — optional day to select on the Schedule tab (notification).
  final DateTime? scheduleFocusDate;

  /// Optional shift id when the notification has no `shiftStartsAt`.
  final String? scheduleFocusShiftId;

  const StaffShell({
    super.key,
    this.initialIndex = 0,
    this.scheduleFocusDate,
    this.scheduleFocusShiftId,
  });

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  late int _currentIndex;
  late final Set<int> _opened;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 5);
    _opened = {_currentIndex};
    // Pull web `/me` modules + grants so Attendance etc. hide before tap.
    // Home data still loads once via StaffDashboardController.onInit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<UserSession>()) return;
      unawaited(Get.find<UserSession>().refreshProfile());
    });
  }

  void _refreshHomeIfReturning() {
    // Pull grants from /mobile/me so role changes apply without re-login.
    final session = Get.find<UserSession>();
    unawaited(
      session.refreshProfile().then((_) {
        if (!Get.isRegistered<StaffDashboardController>()) return;
        final controller = Get.find<StaffDashboardController>();
        if (controller.overview != null) {
          controller.refresh();
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();

    return Obx(() {
      // Keyed by user so a different staff login never reuses the previous
      // account's IndexedStack / tab Element tree.
      final userKey = session.userId ?? session.email;
      // Ensure Obx rebuilds when grants change (revoked Attendance, etc.).
      session.permissionEpoch;

      bool allowed(int tab) => staffTabAllowed(session, tab);
      final index = allowed(_currentIndex)
          ? _currentIndex.clamp(0, 5)
          : firstAllowedTab(
              length: 6,
              allowed: allowed,
              fallback: 5,
            );
      if (index != _currentIndex || !_opened.contains(index)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _currentIndex = index;
            _opened.add(index);
          });
        });
      }

      return Scaffold(
        key: ValueKey('staff-shell-$userKey'),
        body: IndexedStack(
          key: ValueKey('staff-tabs-$userKey'),
          index: index,
          children: [
            LazyIndexedTab(
              active: allowed(0) && _opened.contains(0),
              builder: (_) => const StaffDashboardPage(),
            ),
            LazyIndexedTab(
              active: allowed(1) && _opened.contains(1),
              builder: (_) => StaffSchedulePage(
                focusDate: widget.scheduleFocusDate,
                focusShiftId: widget.scheduleFocusShiftId,
              ),
            ),
            LazyIndexedTab(
              active: allowed(2) && _opened.contains(2),
              builder: (_) =>
                  const StaffAttendancePage(showStaffBottomNav: false),
            ),
            LazyIndexedTab(
              active: allowed(3) && _opened.contains(3),
              builder: (_) => const StaffDailyLogsPage(),
            ),
            LazyIndexedTab(
              active: allowed(4) && _opened.contains(4),
              builder: (_) => const StaffMarTasksMenuPage(),
            ),
            LazyIndexedTab(
              active: allowed(5) && _opened.contains(5),
              builder: (_) => const StaffMoreMenuPage(),
            ),
          ],
        ),
        bottomNavigationBar: StaffBottomNavBar(
          currentIndex: index,
          onTap: (value) {
            if (!allowed(value)) return;
            setState(() {
              _opened.add(value);
              _currentIndex = value;
            });
            if (value == 0) _refreshHomeIfReturning();
          },
        ),
      );
    });
  }
}
