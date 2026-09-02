import 'package:gems_core/gems_core.dart';

import '../entities/portal_notification.dart';
import '../entities/portal_search_hit.dart';

abstract class PortalInboxRepository {
  Future<Result<List<PortalSearchHit>>> search(String query);

  Future<Result<List<PortalNotification>>> getNotifications();

  Future<Result<void>> markNotificationRead(String id);

  Future<Result<void>> markAllNotificationsRead();
}
