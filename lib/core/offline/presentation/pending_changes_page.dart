import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../formatting/web_formats.dart';
import '../../network/connectivity_monitor.dart';
import '../offline_outbox.dart';
import '../outbox_feature.dart';
import '../outbox_item.dart';
import 'pending_sync_chip.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Changes made on this device that have not reached the server yet, for the
/// signed-in user only. Lets the user send now, retry, fix text, or discard.
class PendingChangesPage extends StatelessWidget {
  const PendingChangesPage({super.key});

  /// Top-level text fields a user may safely correct before resending.
  static const List<String> editableFields = [
    'title',
    'body',
    'content',
    'message',
    'note',
    'notes',
    'description',
    'details',
    'summary',
    'reason',
    'comment',
    'comments',
  ];

  static List<String> editableKeysOf(OutboxItem item) {
    final body = item.jsonBody;
    if (body is! Map) return const [];
    return [
      for (final key in editableFields)
        if (body[key] is String) key,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final outbox = OfflineOutbox.maybe;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Unsent changes',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textHeading,
          ),
        ),
      ),
      body: outbox == null
          ? const _EmptyState()
          : Obx(() {
              outbox.store.items.length;
              final syncing = outbox.engine.isSyncing.value;
              final online = Get.isRegistered<ConnectivityMonitor>()
                  ? Get.find<ConnectivityMonitor>().isOnline.value
                  : true;
              final items = outbox.scopedItems;
              if (items.isEmpty) return const _EmptyState();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _SyncHeader(
                    count: items.length,
                    online: online,
                    syncing: syncing,
                    onSync: () => unawaited(
                      outbox.engine.flush(ignoreBackoff: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in items) ...[
                    _OutboxCard(
                      item: item,
                      busy: syncing,
                      onRetry: () => unawaited(outbox.engine.retry(item.id)),
                      onEdit: editableKeysOf(item).isEmpty
                          ? null
                          : () => _edit(context, outbox, item),
                      onDiscard: () => _discard(context, outbox, item),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }),
    );
  }

  Future<void> _discard(
    BuildContext context,
    OfflineOutbox outbox,
    OutboxItem item,
  ) async {
    final ok = await showAppPopup<bool>(
      context: context,
      builder: (ctx) => AppSheetDialog(
        key: const Key('discard-change-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard this change?'),
        content: Text(
          '"${item.label}" will be removed from this device and never sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const Key('discard-change-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.criticalRed),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (ok == true) await outbox.engine.discard(item.id);
  }

  Future<void> _edit(
    BuildContext context,
    OfflineOutbox outbox,
    OutboxItem item,
  ) async {
    final body = Map<String, dynamic>.from(item.jsonBody as Map);
    final edited = await showAppPopup<Map<String, String>>(
      context: context,
      builder: (_) => _EditChangeDialog(
        title: 'Edit ${item.label.toLowerCase()}',
        values: {
          for (final key in editableKeysOf(item)) key: body[key] as String,
        },
      ),
    );
    if (edited == null) return;
    body.addAll(edited);
    await outbox.engine.updateBody(item.id, body);
    unawaited(outbox.engine.flush(ignoreBackoff: true));
  }
}

class _EditChangeDialog extends StatefulWidget {
  final String title;
  final Map<String, String> values;

  const _EditChangeDialog({required this.title, required this.values});

  @override
  State<_EditChangeDialog> createState() => _EditChangeDialogState();
}

class _EditChangeDialogState extends State<_EditChangeDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final entry in widget.values.entries)
      entry.key: TextEditingController(text: entry.value),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetDialog(
      key: const Key('edit-change-dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _controllers.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  key: Key('edit-change-field-${entry.key}'),
                  controller: entry.value,
                  minLines: 1,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: WebFormat.humanise(entry.key),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('edit-change-save'),
          onPressed: () => Navigator.of(context).pop({
            for (final entry in _controllers.entries)
              entry.key: entry.value.text,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SyncHeader extends StatelessWidget {
  final int count;
  final bool online;
  final bool syncing;
  final VoidCallback onSync;

  const _SyncHeader({
    required this.count,
    required this.online,
    required this.syncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? '1 change on this device'
                      : '$count changes on this device',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  online
                      ? 'They are sent automatically, oldest first.'
                      : 'They will be sent when you are back online.',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            key: const Key('pending-sync-now'),
            onPressed: online && !syncing ? onSync : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sync now'),
          ),
        ],
      ),
    );
  }
}

class _OutboxCard extends StatelessWidget {
  final OutboxItem item;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback onDiscard;

  const _OutboxCard({
    required this.item,
    required this.busy,
    required this.onRetry,
    required this.onEdit,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final sending = item.status == OutboxStatus.sending;
    final error = item.lastError;
    final attachments = item.attachments.length;
    return Container(
      key: Key('outbox-item-${item.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.status.needsAttention
              ? AppColors.criticalBackground
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PendingSyncChip(status: item.status),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              OutboxFeature.displayName(item.featureTag),
              'Recorded ${WebFormat.dateTime(item.occurredAt)}',
              if (attachments > 0)
                attachments == 1 ? '1 attachment' : '$attachments attachments',
            ].join(' · '),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                error,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: item.status.needsAttention
                      ? AppColors.criticalRed
                      : AppColors.urgentAmber,
                ),
              ),
            ),
          ],
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onEdit != null)
                TextButton(
                  key: Key('outbox-edit-${item.id}'),
                  onPressed: busy || sending ? null : onEdit,
                  child: const Text('Edit'),
                ),
              TextButton(
                key: Key('outbox-retry-${item.id}'),
                onPressed: busy || sending ? null : onRetry,
                child: const Text('Retry'),
              ),
              TextButton(
                key: Key('outbox-discard-${item.id}'),
                onPressed: busy || sending ? null : onDiscard,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.criticalRed,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('pending-changes-empty'),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_done_outlined,
              size: 44,
              color: AppColors.secondaryTeal,
            ),
            SizedBox(height: 12),
            Text(
              'Everything is sent',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Changes you make while offline appear here until they reach '
              'the server.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
