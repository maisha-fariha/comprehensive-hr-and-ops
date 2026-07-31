import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/visit_request_detail.dart';
import '../../domain/repositories/visit_requests_repository.dart';

/// GetX controller for the read-only Request Details screen.
///
/// Shared across every visit request (registered once via DI, same as the
/// reference Staff Incidents feature's app-lifetime controllers), and
/// simply reloads its [state] whenever [loadDetail] is called with a
/// different request id - avoiding the need to thread a constructor
/// argument through `get_it`'s zero-arg factories.
class VisitRequestDetailsController extends BaseController<VisitRequestDetail> {
  final VisitRequestsRepository repository;

  VisitRequestDetailsController({required this.repository});

  String? _loadedRequestId;

  Future<void> loadDetail(String requestId) async {
    if (_loadedRequestId == requestId && state.value.data != null) return;
    _loadedRequestId = requestId;

    setLoading(true);
    final result = await repository.getRequestDetail(requestId);
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() {
    final requestId = _loadedRequestId;
    if (requestId == null) return Future.value();
    _loadedRequestId = null;
    return loadDetail(requestId);
  }
}
