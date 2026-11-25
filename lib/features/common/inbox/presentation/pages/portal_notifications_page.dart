import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/portal_notification.dart';
import '../controllers/portal_notifications_controller.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';
import '../../../../../core/time/tenant_clock.dart';

class PortalNotificationsPage extends StatefulWidget {
  const PortalNotificationsPage({super.key});

  @override
  State<PortalNotificationsPage> createState() =>
      _PortalNotificationsPageState();
}

class _PortalNotificationsPageState extends State<PortalNotificationsPage> {
  late final PortalNotificationsController _controller;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = _resolve();
    // Always reload on open so badges / unread state stay current.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.open();
    });
  }

  PortalNotificationsController _resolve() {
    if (Get.isRegistered<PortalNotificationsController>()) {
      return Get.find<PortalNotificationsController>();
    }
    return Get.put(PortalNotificationsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: AppColors.textHeading,
          ),
        ),
        actions: [
          Obx(() {
            final hasUnread = _controller.items.any((item) => !item.isRead);
            return TextButton(
              onPressed: hasUnread ? _controller.markAllRead : null,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  color: hasUnread
                      ? AppColors.secondaryTeal
                      : AppColors.textFaint,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final loading = _controller.isLoading.value;
        final items = _controller.items;
        final error = _controller.errorMessage.value;

        if (loading && items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (_controller.hasError) {
          return Center(
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error.isEmpty
                        ? 'Could not load notifications.'
                        : error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 12),
                  ),
                  TextButton(
                    onPressed: _controller.refresh,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        final unread = _controller.unreadCount;
        final allCount = _controller.total.value > 0
            ? _controller.total.value
            : items.length;
        final visible = _unreadOnly
            ? items.where((item) => !item.isRead).toList()
            : items;

        return Column(
          children: [
            _filters(context, all: allCount, unread: unread),
            Expanded(
              child: AppRefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: _controller.refresh,
                child: visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              160,
                            ),
                          ),
                          _empty(context),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          ..._sections(context, visible),
                          if (!_unreadOnly && _controller.hasNext.value) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: _controller.isLoadingMore.value
                                    ? null
                                    : _controller.loadMore,
                                child: Text(
                                  _controller.isLoadingMore.value
                                      ? 'Loading…'
                                      : 'Show older notifications',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondaryTeal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _filters(BuildContext context, {required int all, required int unread}) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        top: 8,
      ),
      child: Row(
        children: [
          _filterChip(context, 'All', all, selected: !_unreadOnly, onTap: () {
            setState(() => _unreadOnly = false);
          }),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          _filterChip(
            context,
            'Unread',
            unread,
            selected: _unreadOnly,
            onTap: () => setState(() => _unreadOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    int count, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? AppColors.secondaryTeal : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: color,
                decoration: selected ? TextDecoration.underline : null,
                decorationColor: color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.quickActionCreateShiftBg
                    : AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final title = _unreadOnly ? "You're all caught up!" : 'No notifications';
    final message = _unreadOnly
        ? 'There are no unread alerts to review.'
        : 'No notification records found in your inbox.';
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(BuildContext context, List<PortalNotification> items) {
    final critical = items.where((item) => _band(item) == _Band.critical).toList();
    final high = items.where((item) => _band(item) == _Band.high).toList();
    final normal = items.where((item) => _band(item) == _Band.normal).toList();
    final gap = ResponsiveHelper.getResponsiveHeight(context, 8);

    List<Widget> block(String title, Color color, List<PortalNotification> rows) {
      if (rows.isEmpty) return const [];
      return [
        Padding(
          padding: EdgeInsets.only(top: gap, bottom: 4),
          child: Text(
            '$title (${rows.length})',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ),
        for (final item in rows) ...[
          _tile(context, item),
          SizedBox(height: gap),
        ],
      ];
    }

    // Web bell: Life-Safety (critical) · Priority Alerts (high) · General.
    return [
      ...block(
        'LIFE-SAFETY & EMERGENCY',
        AppColors.criticalRed,
        critical,
      ),
      ...block('PRIORITY ALERTS', AppColors.urgentAmber, high),
      ...block('GENERAL ACTIVITY', AppColors.textSecondary, normal),
    ];
  }

  Widget _tile(BuildContext context, PortalNotification item) {
    final label = (item.eventLabel ?? '').trim();
    final when = item.createdAt == null ? item.timeLabel : _ago(item.createdAt!);
    final band = _band(item);
    final critical = band == _Band.critical;
    final priority = band == _Band.high;
    final alert = critical || priority;
    final bg = critical
        ? (item.isRead ? const Color(0xFFFEECEC) : const Color(0xFFFDE8E8))
        : priority
            ? (item.isRead ? const Color(0xFFFFF8ED) : const Color(0xFFFFF1DC))
            : (item.isRead ? Colors.white : const Color(0xFFF4F7FB));
    final border = critical
        ? const Border(left: BorderSide(color: AppColors.criticalRed, width: 3))
        : priority
            ? const Border(
                left: BorderSide(color: AppColors.urgentAmber, width: 3),
              )
            : null;
    final accent =
        critical ? AppColors.criticalRed : AppColors.urgentAmber;
    final dotColor = critical
        ? AppColors.criticalRed
        : priority
            ? AppColors.urgentAmber
            : AppColors.primaryNavy;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _controller.openItem(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alert) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Icon(
                    critical
                        ? Icons.emergency_rounded
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: accent,
                  ),
                ),
              ] else ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EEF5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _initials(item),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label.isEmpty ? item.title : label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: alert ? accent : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (when.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            when,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (label.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight:
                              item.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ],
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(PortalNotification item) {
  final label = (item.eventLabel ?? item.title).trim();
  if (label.isEmpty) return 'N';
  final parts = label.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
  }
  return ('${parts.first[0]}${parts[1][0]}').toUpperCase();
}

enum _Band { critical, high, normal }

/// Same buckets as the web bell (`severity`, then `eventKey`).
_Band _band(PortalNotification item) {
  final explicit = item.meta['severity'];
  final severity = explicit is String ? explicit.toLowerCase() : '';
  if (severity == 'critical') return _Band.critical;
  if (severity == 'high') return _Band.high;
  if (severity == 'low' || severity == 'normal' || severity == 'medium') {
    return _Band.normal;
  }
  final key = (item.eventKey ?? '').toLowerCase();
  if (key.startsWith('emergency.') ||
      key == 'incidents.escalated' ||
      key.contains('sos') ||
      key.contains('critical')) {
    return _Band.critical;
  }
  if (key.contains('missed') ||
      key.contains('unfilled') ||
      key.contains('failed') ||
      key.contains('overdue') ||
      key.startsWith('incidents.raised') ||
      key.startsWith('medication.')) {
    return _Band.high;
  }
  return _Band.normal;
}

String _ago(DateTime date) {
  final seconds = DateTime.now().difference(TenantClock.wallOf(date)).inSeconds;
  if (seconds < 60) return 'just now';
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '${minutes}m ago';
  final hours = (minutes / 60).round();
  if (hours < 24) return '${hours}h ago';
  return '${(hours / 24).round()}d ago';
}
