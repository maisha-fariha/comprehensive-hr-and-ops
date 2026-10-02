import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/family_notification.dart';
import '../../domain/entities/family_notification_target.dart';
import '../../domain/repositories/family_dashboard_repository.dart';
import '../navigation/family_notification_navigator.dart';
import 'family_dashboard_controller.dart';

class FamilyNotificationsController
    extends BaseController<List<FamilyNotification>> {
  final FamilyDashboardRepository repository;
  final FamilyNotificationNavigate navigate;

  FamilyNotificationsController({
    FamilyDashboardRepository? repository,
    FamilyNotificationNavigate? navigate,
  })  : repository = repository ?? GetIt.instance<FamilyDashboardRepository>(),
        navigate = navigate ?? FamilyNotificationNavigator.open {
    load();
  }

  List<FamilyNotification> get items => state.value.data ?? const [];

  Future<void> load() async {
    setLoading(true);
    final result = await repository.getNotifications();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  /// Web bell parity: mark an unread item read, then go to its target.
  /// Items without a Family screen are only marked read.
  void open(FamilyNotification item) {
    markRead(item);
    final target = FamilyNotificationTarget.resolve(item);
    if (target != null) navigate(target);
  }

  Future<void> markRead(FamilyNotification item) async {
    if (item.isRead) return;
    setSuccess([
      for (final entry in items)
        entry.id == item.id ? entry.copyWith(isRead: true) : entry,
    ]);
    final result = await repository.markNotificationRead(item.id);
    if (result.isFailure) {
      await load();
      return;
    }
    if (Get.isRegistered<FamilyDashboardController>()) {
      Get.find<FamilyDashboardController>().refresh();
    }
  }

  Future<void> markAllRead() async {
    await repository.markAllNotificationsRead();
    await load();
  }

  @override
  Future<void> refresh() => load();
}
