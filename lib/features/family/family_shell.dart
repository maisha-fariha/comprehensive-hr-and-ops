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
  const FamilyShell({super.key});

  @override
  State<FamilyShell> createState() => _FamilyShellState();
}

class _FamilyShellState extends State<FamilyShell> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    FamilyDashboardPage(),
    FamilyDailyUpdatesPage(),
    FamilyAppointmentsListPage(),
    FamilyMessagesListPage(),
    FamilyMoreMenuPage(),
  ];

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
