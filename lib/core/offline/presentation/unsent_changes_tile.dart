import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../routing/app_routes.dart';
import '../offline_outbox.dart';

/// "Unsent changes (N)" entry for Profile & Settings. Takes no space when
/// the signed-in user has nothing waiting.
class UnsentChangesTile extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const UnsentChangesTile({
    super.key,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final outbox = OfflineOutbox.maybe;
    if (outbox == null) return const SizedBox.shrink();
    return Obx(() {
      outbox.store.items.length;
      final count = outbox.unsentCount;
      if (count == 0) return const SizedBox.shrink();
      final attention = outbox.attentionCount > 0;
      final accent = attention ? AppColors.criticalRed : AppColors.urgentAmber;
      return Padding(
        padding: padding,
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: const Key('unsent-changes-tile'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => unawaited(Get.toNamed(AppRoutes.pendingChanges)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    attention
                        ? Icons.error_outline_rounded
                        : Icons.cloud_off_rounded,
                    size: 20,
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Unsent changes',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.iconChevron,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
