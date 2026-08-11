import 'package:flutter/material.dart';

import 'appointments/presentation/pages/family_appointments_list_page.dart';
import 'daily_updates/presentation/pages/family_daily_updates_page.dart';
import 'dashboard/presentation/pages/family_dashboard_page.dart';
import 'messages/presentation/pages/family_messages_list_page.dart';
import 'presentation/pages/family_more_menu_page.dart';
import 'presentation/widgets/family_bottom_nav_bar.dart';

/// Root shell for the Family portal. Owns the bottom navigation bar and
/// switches between its 5 tabs: Home (Dashboard), Updates (Daily Updates),
/// Appointments, Messages and More (a hub for Visit Requests / Documents /
/// Profile & Settings, which don't have a dedicated bottom-nav slot in the
/// Figma bar).
class FamilyShell extends StatefulWidget {
  /// Tab to show when the shell is (re)opened — used by pushed screens that
  /// host their own copy of [FamilyBottomNavBar] (e.g. Create Appointment).
  final int initialIndex;

  const FamilyShell({super.key, this.initialIndex = 0});

  @override
  State<FamilyShell> createState() => _FamilyShellState();
}

class _FamilyShellState extends State<FamilyShell> {
  late int _currentIndex;

  static const _tabs = <Widget>[
    FamilyDashboardPage(),
    FamilyDailyUpdatesPage(),
    FamilyAppointmentsListPage(),
    FamilyMessagesListPage(),
    FamilyMoreMenuPage(),
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
      bottomNavigationBar: FamilyBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
