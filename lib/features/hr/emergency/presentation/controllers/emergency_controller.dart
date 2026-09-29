import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/emergency_alert.dart';
import '../../domain/repositories/emergency_repository.dart';

/// Web `/dashboard/emergency` ("Emergency Alarms"): status filter, KPI
/// tiles, the paged alarm list and every respond action.
class EmergencyController extends GetxController {
  final EmergencyRepository repository;
  final UserSession session;

  EmergencyController({required this.repository, required this.session});

  static const List<int> pageSizes = [10, 25, 50];
  static const int _statsLimit = 100;

  final RxList<EmergencyAlert> alerts = <EmergencyAlert>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();

  /// `null` is "All"; the web opens on Active.
  final RxnString status = RxnString('active');
  final RxInt page = 1.obs;
  final RxInt limit = pageSizes.first.obs;

  final Rx<EmergencyStats> stats = const EmergencyStats().obs;
  final RxList<EmergencyOption> responders = <EmergencyOption>[].obs;
  final RxnString busyId = RxnString();

  int _serial = 0;

  bool get canRespond => session.can('emergency:respond');
  bool get canRaise => session.canRaiseEmergency;

  int get totalPages =>
      total.value == 0 ? 1 : ((total.value + limit.value - 1) ~/ limit.value);

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() => Future.wait([load(), loadStats()]);

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.list(
      status: status.value,
      page: page.value,
      limit: limit.value,
    );
    if (serial != _serial) return;
    result.when(
      success: (data) {
        alerts.assignAll(data.items);
        total.value = data.total;
        loadError.value = null;
      },
      failure: (error) {
        alerts.clear();
        total.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadStats() async {
    final result = await repository.list(page: 1, limit: _statsLimit);
    result.when(
      success: (data) {
        stats.value = EmergencyStats.from(data.items);
        final people = <String, EmergencyOption>{};
        for (final alert in data.items) {
          for (final person in [
            alert.raiser,
            alert.acknowledger,
            alert.assignee,
          ]) {
            if (person == null) continue;
            people.putIfAbsent(
              person.id,
              () => EmergencyOption(
                id: person.id,
                label: person.name ?? 'Unknown',
              ),
            );
          }
        }
        responders.assignAll(people.values);
      },
      failure: (_) {},
    );
  }

  void setStatus(String? value) {
    status.value = value;
    page.value = 1;
    load();
  }

  void setPage(int value) {
    page.value = value;
    load();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    load();
  }

  /// Returns the error message, or null on success. The detail sheet shows
  /// errors inline like the web modal; the board toasts them.
  Future<String?> _run(
    String id,
    Future<Result<void>> Function() action,
    String success, {
    bool toastErrors = true,
  }) async {
    busyId.value = id;
    final result = await action();
    busyId.value = null;
    return result.when(
      success: (_) {
        AppSnackbar.show(success, '');
        refreshAll();
        return null;
      },
      failure: (error) {
        if (toastErrors) AppSnackbar.show('Something went wrong', error.message);
        return error.message;
      },
    );
  }

  Future<String?> acknowledge(EmergencyAlert alert) => _run(
        alert.id,
        () => repository.acknowledge(alert.id),
        'Alarm acknowledged — the raiser can see you are coming',
      );

  Future<String?> resolve(EmergencyAlert alert) => _run(
        alert.id,
        () => repository.resolve(alert.id),
        'Alarm resolved',
      );

  Future<String?> delete(EmergencyAlert alert) => _run(
        alert.id,
        () => repository.delete(alert.id),
        'Alert deleted',
      );

  Future<String?> assign(String alertId, String userId) => _run(
        alertId,
        () => repository.assign(alertId, userId),
        'Assigned — they have been told directly',
        toastErrors: false,
      );

  Future<String?> addNote(String alertId, String note) => _run(
        alertId,
        () => repository.addNote(alertId, note),
        'Added to the response',
        toastErrors: false,
      );

  Future<String?> markInProgress(String alertId) => _run(
        alertId,
        () => repository.setStatus(alertId, 'in_progress'),
        'Marked as being handled',
        toastErrors: false,
      );
}
