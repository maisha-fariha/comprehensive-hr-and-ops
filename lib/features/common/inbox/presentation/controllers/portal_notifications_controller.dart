import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/portal_notification.dart';
import '../../domain/repositories/portal_inbox_repository.dart';

class PortalNotificationsController
    extends BaseController<List<PortalNotification>> {
  final PortalInboxRepository repository;

  PortalNotificationsController({PortalInboxRepository? repository})
      : repository = repository ?? GetIt.instance<PortalInboxRepository>() {
    load();
  }

  List<PortalNotification> get items => state.value.data ?? const [];

  Future<void> load() async {
    setLoading(true);
    final result = await repository.getNotifications();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> markRead(PortalNotification item) async {
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
