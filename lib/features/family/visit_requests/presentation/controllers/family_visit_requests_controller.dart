import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/family_visit_requests_overview.dart';
import '../../domain/entities/my_visit_request.dart';
import '../../domain/repositories/visit_requests_repository.dart';

/// GetX controller for the Family Visit Requests list screen.
///
/// Owns the status tab (All / Pending / Approved / Rejected / Cancelled /
/// Completed) over the signed-in family's own `family_visit` appointments.
class FamilyVisitRequestsController extends BaseController<FamilyVisitRequestsOverview> {
  final VisitRequestsRepository repository;

  FamilyVisitRequestsController({required this.repository}) {
    loadOverview();
  }

  final Rx<FamilyVisitRequestsTab> selectedTab =
      FamilyVisitRequestsTab.all.obs;

  FamilyVisitRequestsOverview? get overview => state.value.data;

  List<MyVisitRequest> get visibleRequests =>
      overview?.requestsFor(selectedTab.value) ?? const [];

  int countFor(FamilyVisitRequestsTab tab) => overview?.countFor(tab) ?? 0;

  void selectTab(FamilyVisitRequestsTab tab) => selectedTab.value = tab;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadOverview();
}
