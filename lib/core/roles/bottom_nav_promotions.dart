import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../../features/hr/presentation/manager_destinations.dart';
import '../../features/staff/extras/presentation/pages/staff_clients_page.dart';
import '../../features/staff/extras/presentation/pages/staff_emergency_page.dart';
import '../../features/staff/extras/presentation/pages/staff_residences_page.dart';
import '../../features/staff/extras/presentation/pages/staff_shift_handovers_page.dart';
import '../../features/staff/incidents/presentation/pages/staff_incidents_list_page.dart';
import 'permission_gate.dart';
import 'user_session.dart';

/// A bottom-nav slot promoted from the More menu when primary tabs are hidden.
class BottomNavPromotion {
  final String label;
  final String asset;
  final VoidCallback open;

  const BottomNavPromotion({
    required this.label,
    required this.asset,
    required this.open,
  });
}

/// When role grants hide primary tabs, fill the bar from More so the UI does
/// not collapse to Home + More with large empty gutters.
abstract final class BottomNavPromotions {
  static const int hrTargetSlots = 5;
  static const int staffTargetSlots = 5;

  /// HR More entries that may move into the bar (priority order).
  static List<BottomNavPromotion> hrCandidates(UserSession session) {
    final dests = managerDestinations().where((d) => d.inMoreMenu).toList();
    BottomNavPromotion? match(String title, String asset, {String? short}) {
      for (final d in dests) {
        if (d.title == title) {
          return BottomNavPromotion(
            label: short ?? (title.length > 11 ? title.split(' ').first : title),
            asset: asset,
            open: d.open,
          );
        }
      }
      return null;
    }

    return [
      ?match('Daily Logs', AppAssets.clipboardCheck),
      ?match('Task Management', AppAssets.navChecklist, short: 'Tasks'),
      ?match('Clients', AppAssets.users),
      ?match('Residences', AppAssets.homeSmall),
      ?match('Shift Handovers', AppAssets.notePencil, short: 'Handovers'),
      ?match('Communication', AppAssets.messageCircle, short: 'Messages'),
      ?match('Emergency', AppAssets.alertTriangle),
    ];
  }

  /// Staff More entries that may move into the bar (priority order).
  static List<BottomNavPromotion> staffCandidates(UserSession session) {
    final out = <BottomNavPromotion>[];

    void add({
      required String label,
      required String asset,
      required bool allowed,
      required List<String> anyOf,
      required Widget Function() builder,
    }) {
      if (!allowed) return;
      out.add(
        BottomNavPromotion(
          label: label,
          asset: asset,
          open: () => openPermittedPage(
            title: label,
            anyOf: anyOf,
            builder: builder,
          ),
        ),
      );
    }

    add(
      label: 'Clients',
      asset: AppAssets.users,
      allowed: session.canAccessClients,
      anyOf: const ['clients:read'],
      builder: () => const StaffClientsPage(),
    );
    add(
      label: 'Incidents',
      asset: AppAssets.navBell,
      allowed: session.can('incidents:read'),
      anyOf: const ['incidents:read'],
      builder: () => const StaffIncidentsListPage(),
    );
    add(
      label: 'Handovers',
      asset: AppAssets.notePencil,
      allowed: session.canAccessHandovers,
      anyOf: const ['shift-handovers:read', 'handovers:read'],
      builder: () => const StaffShiftHandoversPage(),
    );
    add(
      label: 'Residence',
      asset: AppAssets.homeSmall,
      allowed: session.can('residences:read'),
      anyOf: const ['residences:read'],
      builder: () => const StaffResidencesPage(),
    );
    add(
      label: 'Emergency',
      asset: AppAssets.alertTriangle,
      allowed: session.canReadEmergency,
      anyOf: const ['emergency:read', 'emergency:raise'],
      builder: () => const StaffEmergencyPage(),
    );
    return out;
  }
}
