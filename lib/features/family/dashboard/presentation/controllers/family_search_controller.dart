import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/family_search_hit.dart';
import '../../domain/repositories/family_dashboard_repository.dart';

class FamilySearchController extends BaseController<List<FamilySearchHit>> {
  final FamilyDashboardRepository repository;

  FamilySearchController({FamilyDashboardRepository? repository})
      : repository = repository ?? GetIt.instance<FamilyDashboardRepository>();

  final RxString query = ''.obs;

  List<FamilySearchHit> get hits => state.value.data ?? const [];

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
