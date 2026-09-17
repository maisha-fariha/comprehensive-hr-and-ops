import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/family_visit_requests_overview.dart';
import '../../domain/entities/my_visit_request.dart';
import '../../domain/entities/visit_request.dart';
import '../../domain/repositories/visit_requests_repository.dart';

/// GetX controller for the Family Visit Requests list screen.
///
/// Owns the Pending / History filter for the signed-in family's own
/// `family_visit` appointments (no cross-family "All" list).
class FamilyVisitRequestsController extends BaseController<FamilyVisitRequestsOverview> {
  final VisitRequestsRepository repository;

  FamilyVisitRequestsController({required this.repository}) {
    loadOverview();
  }

  final Rx<FamilyVisitRequestsTab> selectedTab =
      FamilyVisitRequestsTab.pending.obs;

  FamilyVisitRequestsOverview? get overview => state.value.data;

  List<VisitRequest> get allRequests => overview?.allRequests ?? const [];
  List<MyVisitRequest> get myRequests => overview?.myRequests ?? const [];
  List<VisitRequest> get historyRequests => overview?.historyRequests ?? const [];

  int get pendingCount => overview?.pendingCount ?? 0;
  int get approvedCount => overview?.approvedCount ?? 0;
  int get rejectedCount => overview?.rejectedCount ?? 0;

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
