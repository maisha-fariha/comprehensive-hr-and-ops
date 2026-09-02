import 'package:gems_core/gems_core.dart';

import '../entities/family_appointment.dart';

abstract class FamilyAppointmentsRepository {
  Future<Result<List<FamilyAppointment>>> getAppointments();

  Future<Result<void>> createAppointment({
    required String type,
    required DateTime scheduledAt,
    required String location,
    String? notes,
  });

  Future<Result<void>> reschedule({
    required String appointmentId,
    required DateTime scheduledAt,
  });

  Future<Result<void>> cancel(String appointmentId);
}
