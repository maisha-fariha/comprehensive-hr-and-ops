import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/family_notification.dart';
import '../../domain/repositories/family_dashboard_repository.dart';

class FamilyNotificationsController
    extends BaseController<List<FamilyNotification>> {
  final FamilyDashboardRepository repository;

  FamilyNotificationsController({FamilyDashboardRepository? repository})
      : repository = repository ?? GetIt.instance<FamilyDashboardRepository>() {
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

  Future<void> markRead(FamilyNotification item) async {
    if (item.isRead) return;
    await repository.markNotificationRead(item.id);
    await load();
  }

  Future<void> markAllRead() async {
    await repository.markAllNotificationsRead();
    await load();
  }

  @override
  Future<void> refresh() => load();
}
