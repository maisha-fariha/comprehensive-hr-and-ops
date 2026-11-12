import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/user_session.dart';
import '../../core/widgets/lazy_indexed_tab.dart';
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
  late final Set<int> _opened;

  static const int _messagesTab = 3;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _opened = {_currentIndex};
    // Warm messages only when landing on Messages (badge can wait until then).
    if (_currentIndex == _messagesTab) {
      ensureFamilyMessagesController();
    }
  }

  void _onTap(int index) {
    setState(() {
      _opened.add(index);
      _currentIndex = index;
    });
    if (index == _messagesTab) {
      ensureFamilyMessagesController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visibility = Get.find<UserSession>().familyVisibility;
      return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            LazyIndexedTab(
              active: _opened.contains(0),
              builder: (_) => const FamilyDashboardPage(),
            ),
            LazyIndexedTab(
              active: _opened.contains(1),
              builder: (_) => visibility.dailyLogs
                  ? const FamilyDailyUpdatesPage()
                  : const FamilyFeatureUnavailablePage(
                      title: 'Daily Updates',
                      message:
                          'Your care provider has not shared daily updates with family members.',
                    ),
            ),
            LazyIndexedTab(
              active: _opened.contains(2),
              builder: (_) => visibility.appointments
                  ? const FamilyAppointmentsListPage()
                  : const FamilyFeatureUnavailablePage(
                      title: 'Appointments',
                      message:
                          'Appointments are not shared with family members for this home.',
                    ),
            ),
            LazyIndexedTab(
              active: _opened.contains(3),
              builder: (_) => visibility.messages
                  ? const FamilyMessagesListPage()
                  : const FamilyFeatureUnavailablePage(
                      title: 'Messages',
                      message:
                          'Messaging is not enabled for family members in this home.',
                    ),
            ),
            LazyIndexedTab(
              active: _opened.contains(4),
              builder: (_) => const FamilyMoreMenuPage(),
            ),
          ],
        ),
        bottomNavigationBar: FamilyBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
        ),
      );
    });
  }
}
