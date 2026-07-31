import 'package:gems_core/gems_core.dart';

import '../entities/family_appointment.dart';

/// Contract for fetching the Family Appointments feature's content. The
/// presentation layer only ever depends on this interface, so swapping the
/// mocked [FamilyAppointmentsRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class FamilyAppointmentsRepository {
  Future<Result<List<FamilyAppointment>>> getAppointments();
}
