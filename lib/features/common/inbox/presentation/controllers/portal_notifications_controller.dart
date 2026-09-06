import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../hr/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../../staff/dashboard/presentation/controllers/staff_dashboard_controller.dart';
import '../../domain/entities/portal_notification.dart';
import '../../domain/repositories/portal_inbox_repository.dart';

class PortalNotificationsController
    extends BaseController<List<PortalNotification>> {
  final PortalInboxRepository repository;

  int _loadGeneration = 0;
  bool _markingAll = false;

  PortalNotificationsController({PortalInboxRepository? repository})
      : repository = repository ?? GetIt.instance<PortalInboxRepository>();

  List<PortalNotification> get items => state.value.data ?? const [];

  bool get hasError => errorMessage.value.isNotEmpty && items.isEmpty;

  int get unreadCount => items.where((item) => !item.isRead).length;

  /// Fresh fetch whenever the page is opened (controller may be reused).
  Future<void> open() => load();

  Future<void> load({bool quiet = false}) async {
    final generation = ++_loadGeneration;
    if (!quiet || items.isEmpty) {
      setLoading(true);
    }
    try {
      final result = await repository.getNotifications();
      if (generation != _loadGeneration) return;
      result.when(
        success: (data) {
          setSuccess(data);
          _syncDashboardBadge();
        },
        failure: (error) {
          // Keep the previous list visible; only hard-fail when empty.
          errorMessage.value = error.message;
          if (items.isEmpty) {
            setError(error.message);
          } else {
            Get.snackbar(
              'Could not refresh',
              error.message,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
      );
    } finally {
      if (generation == _loadGeneration) {
        setLoading(false);
      }
    }
  }

  Future<void> markRead(PortalNotification item) async {
    if (item.isRead) return;
    if (item.id.isEmpty || item.id == 'notification') {
      Get.snackbar(
        'Could not mark read',
        'This notification is missing an id from the server.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Optimistic UI — do not immediately re-fetch (GET can lag behind POST).
    _replaceItem(item.copyWith(isRead: true));
    _syncDashboardBadge();

    final result = await repository.markNotificationRead(item.id);
    result.when(
      success: (_) {
        // Badge already updated; optional quiet sync later is unnecessary.
      },
      failure: (error) {
        _replaceItem(item); // revert
        _syncDashboardBadge();
        Get.snackbar(
          'Could not mark read',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  Future<void> markAllRead() async {
    if (_markingAll || items.every((item) => item.isRead)) return;
    _markingAll = true;

    final previous = List<PortalNotification>.from(items);
    setSuccess([
      for (final item in previous) item.copyWith(isRead: true),
    ]);
    _syncDashboardBadge();

    final result = await repository.markAllNotificationsRead();
    _markingAll = false;
    result.when(
      success: (_) {},
      failure: (error) {
        setSuccess(previous);
        _syncDashboardBadge();
        Get.snackbar(
          'Could not mark all read',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  void _replaceItem(PortalNotification updated) {
    final next = [
      for (final item in items)
        if (item.id == updated.id) updated else item,
    ];
    setSuccess(next);
  }

  /// Keep the Home bell badge in sync without waiting for a full dashboard reload.
  void _syncDashboardBadge() {
    final count = unreadCount;
    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      final overview = dash.overview;
      if (overview != null) {
        dash.setSuccess(
          overview.copyWith(unreadNotificationCount: count),
        );
      }
    }
    if (Get.isRegistered<StaffDashboardController>()) {
      final dash = Get.find<StaffDashboardController>();
      final overview = dash.overview;
      if (overview != null) {
        dash.setSuccess(
          overview.copyWith(unreadNotificationCount: count),
        );
      }
    }
  }

  @override
  Future<void> refresh() => load();
}
