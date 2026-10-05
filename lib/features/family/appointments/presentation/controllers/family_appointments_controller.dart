import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';
import '../../domain/repositories/family_appointments_repository.dart';

/// GetX controller for the Family Visits & Appointments list.
///
/// Mirrors the web `/family/appointments` page: one `GET /family/appointments`
/// list split client-side into "Upcoming Visits" / "Past Visits".
class FamilyAppointmentsController extends BaseController<List<FamilyAppointment>> {
  final FamilyAppointmentsRepository repository;
  final DateTime Function() _now;

  FamilyAppointmentsController({
    required this.repository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    loadAppointments();
  }

  final Rx<FamilyAppointmentsTab> selectedTab = FamilyAppointmentsTab.upcoming.obs;

  List<FamilyAppointment> get appointments => state.value.data ?? const [];

  List<FamilyAppointment> get upcomingAppointments {
    final now = _now();
    return appointments.where((a) => !a.isPastAt(now)).toList();
  }

  List<FamilyAppointment> get pastAppointments {
    final now = _now();
    return appointments.where((a) => a.isPastAt(now)).toList();
  }

  List<FamilyAppointment> get visibleAppointments =>
      selectedTab.value == FamilyAppointmentsTab.upcoming
          ? upcomingAppointments
          : pastAppointments;

  void selectTab(FamilyAppointmentsTab tab) => selectedTab.value = tab;

  /// Web shows "Withdraw" only for pending / approved (confirmed) visits.
  bool canAct(FamilyAppointment appointment) =>
      appointment.status == FamilyAppointmentStatus.pending ||
      appointment.status == FamilyAppointmentStatus.approved;

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
      success: (_) {
        AppSnackbar.show('Visit request withdrawn.', '', force: true);
        loadAppointments();
      },
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
