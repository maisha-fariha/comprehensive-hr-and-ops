import 'package:gems_core/gems_core.dart';

import '../entities/hr_appointment.dart';

/// Reads and writes behind the web `/dashboard/appointments` screen.
abstract class HrAppointmentsRepository {
  /// `GET /appointments` with the tab / filter / search query.
  Future<Result<HrAppointmentPage>> list(HrAppointmentQuery query);

  /// `GET /appointments/summary` — the KPI tiles and tab counts.
  Future<Result<HrAppointmentSummary>> summary();

  /// `POST /appointments`. A family visit is created pending; an external
  /// appointment is confirmed straight away.
  Future<Result<void>> create(HrAppointmentInput input);

  /// `POST /appointments/{id}/reschedule` — proposes a new time on a pending
  /// family visit.
  Future<Result<void>> reschedule(String id, HrAppointmentInput input);

  /// `PATCH /appointments/{id}`; blank location / purpose / notes are cleared.
  Future<Result<void>> update(String id, HrAppointmentInput input);

  Future<Result<void>> approve(String id);

  Future<Result<void>> reject(String id, {String? reason});

  Future<Result<void>> cancel(String id, {String? reason});

  /// Soft delete; the request is kept and can be restored.
  Future<Result<void>> delete(String id);

  /// `GET /residences` for the residence filter.
  Future<Result<List<HrAppointmentOption>>> residences();

  /// `GET /clients` for the form's resident picker.
  Future<Result<List<HrAppointmentClient>>> clients();

  /// Today's entries from `GET /daily-logs` (`logDate` is `YYYY-MM-DD`).
  Future<Result<List<HrAppointmentLogNote>>> dayLog({
    required String clientId,
    required String residenceId,
    required String logDate,
  });

  /// The "Export List" CSV (`reportKey: appointment_log`).
  Future<Result<List<int>>> exportCsv();
}
