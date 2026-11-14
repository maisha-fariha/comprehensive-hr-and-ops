import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_dashboard_overview.dart';
import '../../domain/repositories/family_dashboard_repository.dart';

/// Family Overview controller — web `/family`.
class FamilyDashboardController extends BaseController<FamilyDashboardOverview> {
  final FamilyDashboardRepository repository;

  FamilyDashboardController({required this.repository}) {
    loadOverview();
  }

  final RxnString selectedClientId = RxnString();

  FamilyDashboardOverview? get overview => state.value.data;

  Future<void> loadOverview({String? clientId}) async {
    setLoading(true);
    final result = await repository.getOverview(
      clientId: clientId ?? selectedClientId.value,
    );
    result.when(
      success: (data) {
        selectedClientId.value = data.selectedClientId;
        if (Get.isRegistered<UserSession>() &&
            data.selectedClientId.isNotEmpty) {
          Get.find<UserSession>().selectClient(data.selectedClientId);
        }
        setSuccess(data);
      },
      failure: (error) {
        if (error.code == 'RATE_LIMITED' ||
            error.message.toLowerCase().contains('token refresh')) {
          return;
        }
        setError(error.message);
      },
    );
    setLoading(false);
  }

  Future<void> selectClient(String clientId) async {
    if (clientId.isEmpty || clientId == selectedClientId.value) return;
    selectedClientId.value = clientId;
    await loadOverview(clientId: clientId);
  }

  @override
  Future<void> refresh() => loadOverview(clientId: selectedClientId.value);
}
