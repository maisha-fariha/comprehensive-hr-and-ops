import 'package:gems_core/gems_core.dart';

import '../entities/portal_notifications_page.dart';
import '../entities/portal_search_hit.dart';

abstract class PortalInboxRepository {
  Future<Result<List<PortalSearchHit>>> search(String query);

  /// Web bell: paged `GET /notifications` (default page size 30).
  Future<Result<PortalNotificationsPageData>> getNotifications({
    int page = 1,
    int limit = 30,
  });

  Future<Result<void>> markNotificationRead(String id);

  Future<Result<void>> markAllNotificationsRead();
}
