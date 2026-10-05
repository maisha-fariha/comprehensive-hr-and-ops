import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../appointments/presentation/controllers/family_appointments_controller.dart';
import '../../domain/entities/visit_request_detail.dart';
import '../../domain/repositories/visit_requests_repository.dart';
import 'family_visit_requests_controller.dart';

class VisitRequestDetailsController extends BaseController<VisitRequestDetail> {
  final VisitRequestsRepository repository;

  VisitRequestDetailsController({required this.repository});

  String? _loadedRequestId;
  final RxBool isActing = false.obs;

  /// Always refetches so a staff decision (Rejected / Cancelled) made since
  /// the last visit is shown; a different request clears the old one first.
  Future<void> loadDetail(String requestId) async {
    if (_loadedRequestId != requestId) {
      state.value = ApiResponse<VisitRequestDetail?>(success: false);
    }
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
        AppSnackbar.show('Request updated', 'A new time was sent to the care team.');
        refresh();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not reschedule',
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
        if (Get.isRegistered<FamilyVisitRequestsController>()) {
          Get.find<FamilyVisitRequestsController>().refresh();
        }
        if (Get.isRegistered<FamilyAppointmentsController>()) {
          Get.find<FamilyAppointmentsController>().refresh();
        }
        // Pop before toasting: Get.back() closes an open GetX snackbar
        // instead of the route.
        Get.back();
        AppSnackbar.show('Visit request withdrawn.', '', force: true);
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not cancel',
      ),
    );
  }

  @override
  Future<void> refresh() {
    final requestId = _loadedRequestId;
    if (requestId == null) return Future.value();
    return loadDetail(requestId);
  }
}
