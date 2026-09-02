import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/user_session.dart';
import 'appointments/presentation/pages/family_appointments_list_page.dart';
import 'daily_updates/presentation/pages/family_daily_updates_page.dart';
import 'dashboard/presentation/pages/family_dashboard_page.dart';
import 'messages/presentation/pages/family_messages_list_page.dart';
import 'presentation/pages/family_feature_unavailable_page.dart';
import 'presentation/pages/family_more_menu_page.dart';
import 'presentation/widgets/family_bottom_nav_bar.dart';

class FamilyShell extends StatefulWidget {
  final int initialIndex;

  const FamilyShell({super.key, this.initialIndex = 0});

  @override
  State<FamilyShell> createState() => _FamilyShellState();
}

class _FamilyShellState extends State<FamilyShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visibility = Get.find<UserSession>().familyVisibility;
      final tabs = <Widget>[
        const FamilyDashboardPage(),
        visibility.dailyLogs
            ? const FamilyDailyUpdatesPage()
            : const FamilyFeatureUnavailablePage(
                title: 'Daily Updates',
                message:
                    'Your care provider has not shared daily updates with family members.',
              ),
        visibility.appointments
            ? const FamilyAppointmentsListPage()
            : const FamilyFeatureUnavailablePage(
                title: 'Appointments',
                message:
                    'Appointments are not shared with family members for this home.',
              ),
        visibility.messages
            ? const FamilyMessagesListPage()
            : const FamilyFeatureUnavailablePage(
                title: 'Messages',
                message:
                    'Messaging is not enabled for family members in this home.',
              ),
        const FamilyMoreMenuPage(),
      ];

      return Scaffold(
        body: IndexedStack(index: _currentIndex, children: tabs),
        bottomNavigationBar: FamilyBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      );
    });
  }
}
