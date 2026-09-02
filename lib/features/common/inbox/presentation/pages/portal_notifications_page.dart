import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../controllers/portal_notifications_controller.dart';

class PortalNotificationsPage extends StatelessWidget {
  const PortalNotificationsPage({super.key});

  PortalNotificationsController _resolve() {
    if (Get.isRegistered<PortalNotificationsController>()) {
      return Get.find<PortalNotificationsController>();
    }
    return Get.put(PortalNotificationsController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolve();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: controller.markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }
        if (controller.items.isEmpty) {
          return const Center(child: Text('No notifications yet.'));
        }
        return RefreshIndicator(
          color: AppColors.secondaryTeal,
          onRefresh: controller.refresh,
          child: ListView.separated(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, 8),
            ),
            itemBuilder: (context, index) {
              final item = controller.items[index];
              return ListTile(
                tileColor: item.isRead ? Colors.white : const Color(0xFFE8F5F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(item.title),
                subtitle: Text(
                  [item.body, item.timeLabel]
                      .where((part) => part.isNotEmpty)
                      .join('\n'),
                ),
                onTap: () => controller.markRead(item),
              );
            },
          ),
        );
      }),
    );
  }
}
