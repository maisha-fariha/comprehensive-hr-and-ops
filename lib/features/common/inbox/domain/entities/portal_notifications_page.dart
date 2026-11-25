import 'portal_notification.dart';

/// One page of `GET /notifications` plus list meta (web bell pagination).
class PortalNotificationsPageData {
  final List<PortalNotification> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final int unreadTotal;

  const PortalNotificationsPageData({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.unreadTotal,
  });
}
