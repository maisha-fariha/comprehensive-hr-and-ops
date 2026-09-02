import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/portal_search_hit.dart';
import '../../domain/repositories/portal_inbox_repository.dart';

class PortalSearchController extends BaseController<List<PortalSearchHit>> {
  final PortalInboxRepository repository;

  PortalSearchController({PortalInboxRepository? repository})
      : repository = repository ?? GetIt.instance<PortalInboxRepository>();

  final RxString query = ''.obs;

  List<PortalSearchHit> get hits => state.value.data ?? const [];

  Future<void> search(String value) async {
    query.value = value;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setSuccess(const []);
      return;
    }
    setLoading(true);
    final result = await repository.search(trimmed);
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }
}
