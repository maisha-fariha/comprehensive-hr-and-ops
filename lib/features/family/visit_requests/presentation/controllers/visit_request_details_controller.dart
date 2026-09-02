import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/visit_request_detail.dart';
import '../../domain/repositories/visit_requests_repository.dart';
import 'family_visit_requests_controller.dart';

class VisitRequestDetailsController extends BaseController<VisitRequestDetail> {
  final VisitRequestsRepository repository;

  VisitRequestDetailsController({required this.repository});

  String? _loadedRequestId;
  final RxBool isActing = false.obs;

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

  Future<void> rescheduleTo(DateTime scheduledAt) async {
    final requestId = _loadedRequestId;
    if (requestId == null || isActing.value) return;
    isActing.value = true;
    final result = await repository.reschedule(
      requestId: requestId,
      scheduledAt: scheduledAt,
    );
    isActing.value = false;
    result.when(
      success: (_) {
        Get.snackbar('Request updated', 'A new time was sent to the care team.');
        refresh();
      },
      failure: (error) => Get.snackbar(
        'Could not reschedule',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  Future<void> cancelRequest() async {
    final requestId = _loadedRequestId;
    if (requestId == null || isActing.value) return;
    isActing.value = true;
    final result = await repository.cancel(requestId);
    isActing.value = false;
    result.when(
      success: (_) {
        Get.snackbar('Request cancelled', 'The care team has been notified.');
        if (Get.isRegistered<FamilyVisitRequestsController>()) {
          Get.find<FamilyVisitRequestsController>().refresh();
        }
        Get.back();
      },
      failure: (error) => Get.snackbar(
        'Could not cancel',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  @override
  Future<void> refresh() {
    final requestId = _loadedRequestId;
    if (requestId == null) return Future.value();
    _loadedRequestId = null;
    return loadDetail(requestId);
  }
}
