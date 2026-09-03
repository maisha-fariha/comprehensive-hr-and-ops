import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
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
  final RxnString typeFilter = RxnString();
  final Rxn<DateTimeRange> dateRange = Rxn<DateTimeRange>();

  List<FamilyAppointment> get appointments => state.value.data ?? const [];

  List<FamilyAppointment> get _filtered {
    var items = appointments;
    final type = typeFilter.value;
    if (type != null && type.isNotEmpty) {
      items = items.where((item) {
        final value = item.type.toLowerCase();
        if (type == 'visit') {
          return value.contains('visit') || value.contains('family');
        }
        return value == type;
      }).toList();
    }
    final range = dateRange.value;
    if (range != null) {
      items = items.where((item) {
        final at = item.scheduledAt;
        if (at == null) return true;
        final local = at.toLocal();
        return !local.isBefore(range.start) &&
            !local.isAfter(range.end.add(const Duration(days: 1)));
      }).toList();
    }
    return items;
  }

  /// Sectioned rows for the currently selected tab.
  ///
  /// - **All**: Upcoming + Family Visits (active) + Past (completed).
  /// - **Upcoming**: Upcoming + Family Visits (active + completed family
  ///   visits — the Completed Emily row is the 3rd Family Visits card).
  /// - **Completed**: single "Completed" section with every completed row.
  List<FamilyAppointmentSection> get visibleSections {
    if (selectedTab.value == FamilyAppointmentsTab.completed) {
    final completed = _filtered.where(_isPast).toList();
      if (completed.isEmpty) return const [];
      return [FamilyAppointmentSection(title: 'Past', appointments: completed)];
    }

    final source = _filtered;
    final active = source.where((a) => !_isPast(a)).toList();
    final upcoming = active.where((a) => a.iconKind != FamilyAppointmentIconKind.familyVisit).toList();

    final List<FamilyAppointment> familyVisits;
    if (selectedTab.value == FamilyAppointmentsTab.upcoming) {
      familyVisits = source.where((a) => a.iconKind == FamilyAppointmentIconKind.familyVisit).toList();
    } else {
      familyVisits = active.where((a) => a.iconKind == FamilyAppointmentIconKind.familyVisit).toList();
    }

    final past = source.where(_isPast).toList();

    return [
      if (upcoming.isNotEmpty) FamilyAppointmentSection(title: 'Upcoming', appointments: upcoming),
      if (familyVisits.isNotEmpty) FamilyAppointmentSection(title: 'Family Visits', appointments: familyVisits),
      if (selectedTab.value == FamilyAppointmentsTab.all && past.isNotEmpty)
        FamilyAppointmentSection(title: 'Past', appointments: past),
    ];
  }

  bool _isPast(FamilyAppointment appointment) {
    switch (appointment.status) {
      case FamilyAppointmentStatus.completed:
      case FamilyAppointmentStatus.rejected:
      case FamilyAppointmentStatus.cancelled:
        return true;
      case FamilyAppointmentStatus.upcoming:
      case FamilyAppointmentStatus.pending:
      case FamilyAppointmentStatus.approved:
      case FamilyAppointmentStatus.rescheduleRequested:
        return false;
    }
  }

  void selectTab(FamilyAppointmentsTab tab) => selectedTab.value = tab;

  void setTypeFilter(String? type) => typeFilter.value = type;

  void setDateRange(DateTimeRange? range) => dateRange.value = range;

  String get typeFilterLabel {
    switch (typeFilter.value) {
      case 'visit':
        return 'Visits';
      case 'medical':
        return 'Medical';
      case 'therapy':
        return 'Therapy';
      case 'activity':
        return 'Activity';
      default:
        return 'All types';
    }
  }

  String get dateRangeLabel {
    final range = dateRange.value;
    if (range == null) return 'Date range';
    return '${range.start.month}/${range.start.day} – ${range.end.month}/${range.end.day}';
  }

  bool canAct(FamilyAppointment appointment) {
    switch (appointment.status) {
      case FamilyAppointmentStatus.pending:
      case FamilyAppointmentStatus.approved:
      case FamilyAppointmentStatus.rescheduleRequested:
      case FamilyAppointmentStatus.upcoming:
        return true;
      default:
        return false;
    }
  }

  Future<void> rescheduleTo(String id, DateTime scheduledAt) async {
    final result = await repository.reschedule(
      appointmentId: id,
      scheduledAt: scheduledAt,
    );
    result.when(
      success: (_) => loadAppointments(),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not reschedule',
      ),
    );
  }

  Future<void> cancelAppointment(String id) async {
    final result = await repository.cancel(id);
    result.when(
      success: (_) => loadAppointments(),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not cancel',
      ),
    );
  }

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
