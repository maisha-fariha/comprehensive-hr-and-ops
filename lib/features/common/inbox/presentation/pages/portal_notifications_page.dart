import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../controllers/portal_notifications_controller.dart';

class PortalNotificationsPage extends StatefulWidget {
  const PortalNotificationsPage({super.key});

  @override
  State<PortalNotificationsPage> createState() =>
      _PortalNotificationsPageState();
}

class _PortalNotificationsPageState extends State<PortalNotificationsPage> {
  late final PortalNotificationsController _controller;

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

        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No notifications yet.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.secondaryTeal,
          onRefresh: _controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, 8),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Material(
                color: item.isRead ? Colors.white : const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  subtitle: Text(
                    [item.body, item.timeLabel]
                        .where((part) => part.isNotEmpty)
                        .join('\n'),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: item.isRead
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: item.isRead
                      ? null
                      : () => _controller.markRead(item),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
