import 'package:gems_core/gems_core.dart';

import '../entities/incident_detail.dart';
import '../entities/staff_incident.dart';

/// Contract for fetching the Staff Incidents feature's content. The
/// presentation layer only ever depends on this interface, so swapping the
/// mocked [StaffIncidentsRepositoryImpl] for a real API-backed
/// implementation later requires no changes above the data layer.
abstract class StaffIncidentsRepository {
  Future<Result<List<StaffIncident>>> getIncidents();

  Future<Result<IncidentDetail>> getIncidentDetail(String incidentId);
}
