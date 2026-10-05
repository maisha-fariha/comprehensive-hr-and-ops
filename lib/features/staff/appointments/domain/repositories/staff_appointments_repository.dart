import 'package:gems_core/gems_core.dart';

import '../entities/staff_appointment.dart';

abstract class StaffAppointmentsRepository {
  Future<Result<StaffAppointmentsSummary>> getSummary();

  Future<Result<StaffAppointmentsPageResult>> listAppointments({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? search,
  });

  Future<Result<StaffAppointment>> createAppointment(
    StaffCreateAppointmentInput input,
  );

  Future<Result<void>> approve(String id);

  Future<Result<void>> reject(String id, {String? reason});

  Future<Result<void>> restore(String id);

  Future<Result<void>> cancel(String id, {String? reason});

  Future<Result<void>> delete(String id);

  Future<Result<StaffAppointment>> updateAppointment(
    String id,
    StaffUpdateAppointmentInput input,
  );

  Future<Result<List<StaffAppointmentClientOption>>> listClients();
}
