import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/incident_detail.dart';
import '../../domain/repositories/staff_incidents_repository.dart';

/// GetX controller for the read-only Incident Details screen.
///
/// Unlike [StaffIncidentsController] this is shared across every incident
/// (registered once via DI, same as the reference HR feature's
/// app-lifetime controllers), and simply reloads its [state] whenever
/// [loadDetail] is called with a different incident id - avoiding the need
/// to thread a constructor argument through `get_it`'s zero-arg factories.
class IncidentDetailsController extends BaseController<IncidentDetail> {
  final StaffIncidentsRepository repository;

  IncidentDetailsController({required this.repository});

  String? _loadedIncidentId;

  Future<void> loadDetail(String incidentId) async {
    if (_loadedIncidentId == incidentId && state.value.data != null) return;
    _loadedIncidentId = incidentId;

    setLoading(true);
    final result = await repository.getIncidentDetail(incidentId);
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() {
    final incidentId = _loadedIncidentId;
    if (incidentId == null) return Future.value();
    _loadedIncidentId = null;
    return loadDetail(incidentId);
  }
}
