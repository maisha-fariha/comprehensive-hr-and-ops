import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_mapper.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/connectivity_monitor.dart';
import '../../../../../core/offline/offline_outbox.dart';
import '../../../../../core/offline/outbox_context.dart';
import '../../../../../core/offline/outbox_feature.dart';
import '../../../../../core/offline/presentation/pending_sync_chip.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/staff_task_detail.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';
import '../controllers/tasks_messages_controller.dart';

/// [summary] is the list row; offline, when the full task has never been
/// loaded on this device, the sheet shows it instead of an error.
Future<void> showStaffTaskDetailSheet(
  BuildContext context, {
  required String taskId,
  required TasksMessagesController controller,
  StaffTask? summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StaffTaskDetailSheet(
      taskId: taskId,
      controller: controller,
      summary: summary,
    ),
  );
}

class _StaffTaskDetailSheet extends StatefulWidget {
  final String taskId;
  final TasksMessagesController controller;
  final StaffTask? summary;

  const _StaffTaskDetailSheet({
    required this.taskId,
    required this.controller,
    this.summary,
  });

  @override
  State<_StaffTaskDetailSheet> createState() => _StaffTaskDetailSheetState();
}

class _StaffTaskDetailSheetState extends State<_StaffTaskDetailSheet> {
  late final StaffTasksMessagesRepository _repository;
  StaffTaskDetail? _detail;
  String? _error;
  bool _loading = true;

  /// True when [_detail] was built from the list row while offline.
  bool _summaryOnly = false;
  bool _busy = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffTasksMessagesRepository>();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _detail == null;
      _error = null;
    });
    final offline = Get.isRegistered<ConnectivityMonitor>() &&
        !Get.find<ConnectivityMonitor>().online;
    final result = await OutboxContext.run(
      () => _repository.getTaskDetail(widget.taskId),
      silent: offline && (widget.summary != null || _detail != null),
    );
    if (!mounted) return;
    result.when(
      success: (detail) {
        setState(() {
          _detail = detail;
          _summaryOnly = false;
          _loading = false;
        });
      },
      failure: (error) {
        final offline = AppErrorMapper.from(error).isOffline;
        final summary = widget.summary;
        setState(() {
          _loading = false;
          if (offline && _detail != null) return;
          if (offline && summary != null) {
            _detail = StaffTaskDetail(
              id: summary.id,
              title: summary.title,
              statusRaw: summary.status == TaskStatus.done ? 'completed' : '',
              dueLabel: summary.dueTimeLabel,
              location: summary.location,
            );
            _summaryOnly = true;
            return;
          }
          _error = error.message;
        });
      },
    );
  }

  List<String> _pendingNotes() {
    final outbox = OfflineOutbox.maybe;
    if (outbox == null) return const [];
    outbox.store.items.length;
    final path = ApiEndpoints.taskNotes(widget.taskId);
    return [
      for (final item in outbox.itemsFor({OutboxFeature.tasks}))
        if (item.method == 'POST' &&
            item.path == path &&
            item.jsonBody is Map &&
            '${(item.jsonBody as Map)['body'] ?? ''}'.isNotEmpty)
          '${(item.jsonBody as Map)['body']}',
    ];
  }

  Future<void> _complete() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.controller.completeTask(widget.taskId);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    await widget.controller.addTaskNote(taskId: widget.taskId, body: text);
    _noteController.clear();
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 20),
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
              Container(
                width: ResponsiveHelper.getResponsiveWidth(context, 40),
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
      );
    }
    if (_error != null || _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Task unavailable.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final completedOffline =
        widget.controller.pendingCompletedTaskIds.contains(detail.id);
    final isCompleted = detail.isCompleted || completedOffline;
    return ListView(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 16,
        bottom: 24,
      ),
      children: [
        if (_summaryOnly)
          Container(
            key: const Key('task-detail-offline-summary'),
            margin: EdgeInsets.only(
              bottom: ResponsiveHelper.getResponsiveHeight(context, 12),
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.urgentBackgroundSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Offline: showing the saved summary. The full description and '
              'notes appear once this task has loaded with a connection. You '
              'can still add notes or complete it — they will be sent later.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textBody,
                height: 1.35,
              ),
            ),
          ),
        if (completedOffline)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PendingSyncChip(label: 'Completed · pending sync'),
            ),
          ),
        Text(
          detail.title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            color: AppColors.textHeading,
          ),
        ),
        if (detail.dueLabel.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            'Due: ${detail.dueLabel}',
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (detail.location.isNotEmpty)
          Text(
            detail.location,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
            ),
          ),
        if (detail.description.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          Text(
            detail.description,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: AppColors.textBody,
              height: 1.4,
            ),
          ),
        ],
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
        Text(
          'Notes',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        if (OfflineOutbox.maybe != null) Obx(() {
          final pending = _pendingNotes();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final body in pending)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    bottom: ResponsiveHelper.getResponsiveHeight(context, 8),
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.urgentBackground),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        body,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const PendingSyncChip(),
                    ],
                  ),
                ),
            ],
          );
        }),
        if (detail.notes.isEmpty && _pendingNotes().isEmpty)
          const Text(
            'No notes yet.',
            style: TextStyle(fontFamily: 'Outfit', color: AppColors.textMuted),
          )
        else
          for (final note in detail.notes) ...[
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                bottom: ResponsiveHelper.getResponsiveHeight(context, 8),
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.body,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.textHeading,
                    ),
                  ),
                  if (note.authorName.isNotEmpty || note.timeLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [
                          if (note.authorName.isNotEmpty) note.authorName,
                          if (note.timeLabel.isNotEmpty) note.timeLabel,
                        ].join(' · '),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a note',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _addNote,
                child: const Text('Add note'),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: ElevatedButton(
                onPressed: (_busy || isCompleted) ? null : _complete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text(isCompleted ? 'Completed' : 'Complete'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
