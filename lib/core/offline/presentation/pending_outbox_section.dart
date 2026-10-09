import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../formatting/web_formats.dart';
import '../../routing/app_routes.dart';
import '../offline_outbox.dart';
import '../outbox_item.dart';
import 'pending_sync_chip.dart';

/// Lists this user's unsent changes for the given features at the top of a
/// feature list. Renders nothing when there are none, so screens look
/// exactly as before while online.
///
/// [onSynced] runs after the outbox delivers items, so the screen can reload
/// and show the server records in place of these rows.
class PendingOutboxSection extends StatefulWidget {
  final Set<String> features;
  final VoidCallback? onSynced;
  final EdgeInsetsGeometry padding;

  const PendingOutboxSection({
    super.key,
    required this.features,
    this.onSynced,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 4),
  });

  @override
  State<PendingOutboxSection> createState() => _PendingOutboxSectionState();
}

class _PendingOutboxSectionState extends State<PendingOutboxSection> {
  Worker? _syncWorker;

  @override
  void initState() {
    super.initState();
    final outbox = OfflineOutbox.maybe;
    if (outbox != null && widget.onSynced != null) {
      _syncWorker = ever<int>(outbox.engine.syncedGeneration, (_) {
        if (mounted) widget.onSynced?.call();
      });
    }
  }

  @override
  void dispose() {
    _syncWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outbox = OfflineOutbox.maybe;
    if (outbox == null) return const SizedBox.shrink();
    return Obx(() {
      outbox.store.items.length;
      final items = outbox.itemsFor(widget.features);
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: widget.padding,
        child: Material(
          color: AppColors.urgentBackgroundSoft,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: const Key('pending-outbox-section'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => unawaited(Get.toNamed(AppRoutes.pendingChanges)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 18,
                        color: AppColors.urgentAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items.length == 1
                              ? '1 change saved on this device'
                              : '${items.length} changes saved on this device',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in items.take(3)) _PendingRow(item: item),
                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${items.length - 3} more',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
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

class _PendingRow extends StatelessWidget {
  final OutboxItem item;

  const _PendingRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.label} · ${WebFormat.short(item.occurredAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textBody,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PendingSyncChip(status: item.status),
        ],
      ),
    );
  }
}
