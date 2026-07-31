import 'package:flutter/foundation.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';
import '../../domain/repositories/family_appointments_repository.dart';

/// A titled group of rows shown on the Family Appointments list, e.g.
/// "Upcoming", "Family Visits" or "Completed".
@immutable
class FamilyAppointmentSection {
  final String title;
  final List<FamilyAppointment> appointments;

  const FamilyAppointmentSection({required this.title, required this.appointments});
}

/// GetX controller for the Family Appointments list screen (all 3 tabs).
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected-tab state
/// backing the "All / Upcoming / Completed" segmented control.
class FamilyAppointmentsController extends BaseController<List<FamilyAppointment>> {
  final FamilyAppointmentsRepository repository;

  FamilyAppointmentsController({required this.repository}) {
    loadAppointments();
  }

  final Rx<FamilyAppointmentsTab> selectedTab = FamilyAppointmentsTab.all.obs;

  List<FamilyAppointment> get appointments => state.value.data ?? const [];

  /// Sectioned rows for the currently selected tab.
  ///
  /// The "All" and "Upcoming" tabs share the same non-completed
  /// appointments, split into an "Upcoming" section (everything except
  /// family visits) and a "Family Visits" section - the "Completed" tab
  /// instead shows every completed appointment (including completed family
  /// visits) under a single "Completed" section, per the Figma screenshots.
  List<FamilyAppointmentSection> get visibleSections {
    if (selectedTab.value == FamilyAppointmentsTab.completed) {
      final completed = appointments.where((a) => a.status == FamilyAppointmentStatus.completed).toList();
      if (completed.isEmpty) return const [];
      return [FamilyAppointmentSection(title: 'Completed', appointments: completed)];
    }

    final active = appointments.where((a) => a.status != FamilyAppointmentStatus.completed).toList();
    final upcoming = active.where((a) => a.iconKind != FamilyAppointmentIconKind.familyVisit).toList();
    final familyVisits = active.where((a) => a.iconKind == FamilyAppointmentIconKind.familyVisit).toList();

    return [
      if (upcoming.isNotEmpty) FamilyAppointmentSection(title: 'Upcoming', appointments: upcoming),
      if (familyVisits.isNotEmpty) FamilyAppointmentSection(title: 'Family Visits', appointments: familyVisits),
    ];
  }

  void selectTab(FamilyAppointmentsTab tab) => selectedTab.value = tab;

  Future<void> loadAppointments() async {
    setLoading(true);
    final result = await repository.getAppointments();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadAppointments();
}
