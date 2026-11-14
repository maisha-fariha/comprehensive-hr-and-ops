import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/roles/user_session.dart';
import '../../core/widgets/lazy_indexed_tab.dart';
import 'appointments/presentation/pages/family_appointments_list_page.dart';
import 'daily_updates/presentation/pages/family_daily_updates_page.dart';
import 'dashboard/presentation/pages/family_dashboard_page.dart';
import 'messages/presentation/pages/family_messages_list_page.dart';
import 'presentation/controllers/family_shell_controller.dart';
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
  late final FamilyShellController _shell;
  late final Set<int> _opened;

  static const int _messagesTab = 3;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialIndex.clamp(0, 4);
    if (Get.isRegistered<FamilyShellController>()) {
      _shell = Get.find<FamilyShellController>();
      _shell.goTo(initial);
    } else {
      _shell = Get.put(FamilyShellController(initialIndex: initial));
    }
    _opened = {initial};
    if (initial == _messagesTab) {
      ensureFamilyMessagesController();
    }
  }

  void _onTap(int index) {
    _opened.add(index);
    _shell.goTo(index);
    if (index == _messagesTab) {
      ensureFamilyMessagesController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read visibility for gated labels without rebuilding tab *builders*
      // into different widget types on every identical refresh.
      final visibility = Get.find<UserSession>().familyVisibility;
      final index = _shell.currentIndex.value;
      _opened.add(index);

      return Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            LazyIndexedTab(
              active: _opened.contains(0),
              builder: (_) => const FamilyDashboardPage(),
            ),
            LazyIndexedTab(
              active: _opened.contains(1),
              builder: (_) => _JournalGate(visibility: visibility),
            ),
            LazyIndexedTab(
              active: _opened.contains(2),
              builder: (_) => _AppointmentsGate(visibility: visibility),
            ),
            LazyIndexedTab(
              active: _opened.contains(3),
              builder: (_) => _MessagesGate(visibility: visibility),
            ),
            LazyIndexedTab(
              active: _opened.contains(4),
              builder: (_) => const FamilyMoreMenuPage(),
            ),
          ],
        ),
        bottomNavigationBar: FamilyBottomNavBar(
          currentIndex: index,
          onTap: _onTap,
        ),
      );
    });
  }
}

/// Keeps [FamilyDailyUpdatesPage] mounted; swaps only the unavailable shell
/// when visibility flips so pull-to-refresh does not redirect.
class _JournalGate extends StatelessWidget {
  final FamilyVisibility visibility;

  const _JournalGate({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final open = visibility.dailyLogs ||
        visibility.activities ||
        visibility.medications ||
        visibility.medicalConditions;
    if (!open) {
      return const FamilyFeatureUnavailablePage(
        title: 'Care Journal',
        message:
            'Your care provider has not shared the care journal with family members.',
      );
    }
    return const FamilyDailyUpdatesPage();
  }
}

class _AppointmentsGate extends StatelessWidget {
  final FamilyVisibility visibility;

  const _AppointmentsGate({required this.visibility});

  @override
  Widget build(BuildContext context) {
    if (!visibility.appointments) {
      return const FamilyFeatureUnavailablePage(
        title: 'Appointments',
        message:
            'Appointments are not shared with family members for this home.',
      );
    }
    return const FamilyAppointmentsListPage();
  }
}

class _MessagesGate extends StatelessWidget {
  final FamilyVisibility visibility;

  const _MessagesGate({required this.visibility});

  @override
  Widget build(BuildContext context) {
    if (!visibility.messages) {
      return const FamilyFeatureUnavailablePage(
        title: 'Messages',
        message:
            'Messaging is not enabled for family members in this home.',
      );
    }
    return const FamilyMessagesListPage();
  }
}
