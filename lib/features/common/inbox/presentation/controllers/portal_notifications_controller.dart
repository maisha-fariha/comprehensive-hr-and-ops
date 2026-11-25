import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../hr/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../../staff/dashboard/presentation/controllers/staff_dashboard_controller.dart';
import '../../domain/entities/portal_notification.dart';
import '../../domain/repositories/portal_inbox_repository.dart';
import '../navigation/portal_notification_navigator.dart';

class PortalNotificationsController
    extends BaseController<List<PortalNotification>> {
  final PortalInboxRepository repository;

  static const _pageSize = 30;

  int _loadGeneration = 0;
  bool _markingAll = false;
  final RxInt page = 1.obs;
  final RxInt total = 0.obs;
  final RxInt unreadTotal = 0.obs;
  final RxBool hasNext = false.obs;
  final RxBool isLoadingMore = false.obs;

  PortalNotificationsController({PortalInboxRepository? repository})
      : repository = repository ?? GetIt.instance<PortalInboxRepository>();

  List<PortalNotification> get items => state.value.data ?? const [];

  bool get hasError => errorMessage.value.isNotEmpty && items.isEmpty;

  /// Prefer the server unread total when trusted; otherwise count loaded rows.
  int get unreadCount {
    final server = unreadTotal.value;
    final pageUnread = items.where((item) => !item.isRead).length;
    final all = total.value;
    // Reject history-sized "unread" that matches total while the page has reads.
    if (server > 0 &&
        all > 0 &&
        server == all &&
        pageUnread < server &&
        items.any((item) => item.isRead)) {
      return pageUnread;
    }
    if (server > 0) return server;
    return pageUnread;
  }

  /// Fresh fetch whenever the page is opened (controller may be reused).
  Future<void> open() => load();

  /// Marks the row read, then opens the module the web bell would open.
  Future<void> openItem(PortalNotification item) async {
    if (!item.isRead) await markRead(item);
    PortalNotificationNavigator.open(item);
  }

  Future<void> load({bool quiet = false}) async {
    final generation = ++_loadGeneration;
    if (!quiet || items.isEmpty) {
      setLoading(true);
    }
    try {
      final result = await repository.getNotifications(
        page: 1,
        limit: _pageSize,
      );
      if (generation != _loadGeneration) return;
      result.when(
        success: (data) {
          page.value = data.page;
          total.value = data.total;
          hasNext.value = data.hasNext;
          unreadTotal.value = data.unreadTotal;
          setSuccess(data.items);
          _syncDashboardBadge();
        },
        failure: (error) {
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

  /// Web bell keeps older notifications behind pagination / “show more”.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasNext.value || isLoading.value) return;
    isLoadingMore.value = true;
    final nextPage = page.value + 1;
    final generation = _loadGeneration;
    try {
      final result = await repository.getNotifications(
        page: nextPage,
        limit: _pageSize,
      );
      if (generation != _loadGeneration) return;
      result.when(
        success: (data) {
          page.value = data.page;
          total.value = data.total;
          hasNext.value = data.hasNext;
          unreadTotal.value = data.unreadTotal;
          final seen = {for (final item in items) item.id};
          final merged = [
            ...items,
            for (final item in data.items)
              if (!seen.contains(item.id)) item,
          ];
          setSuccess(merged);
          _syncDashboardBadge();
        },
        failure: (error) {
          Get.snackbar(
            'Could not load more',
            error.message,
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
    } finally {
      isLoadingMore.value = false;
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
    if (unreadTotal.value > 0) unreadTotal.value = unreadTotal.value - 1;
    _syncDashboardBadge();

    final result = await repository.markNotificationRead(item.id);
    result.when(
      success: (_) {},
      failure: (error) {
        _replaceItem(item); // revert
        unreadTotal.value = unreadTotal.value + 1;
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
    final previousUnread = unreadTotal.value;
    setSuccess([
      for (final item in previous) item.copyWith(isRead: true),
    ]);
    unreadTotal.value = 0;
    _syncDashboardBadge();

    final result = await repository.markAllNotificationsRead();
    _markingAll = false;
    result.when(
      success: (_) {},
      failure: (error) {
        setSuccess(previous);
        unreadTotal.value = previousUnread;
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
