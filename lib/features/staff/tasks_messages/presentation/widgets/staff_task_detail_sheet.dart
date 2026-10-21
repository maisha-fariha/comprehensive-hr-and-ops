import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/authorized_file.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/storage/media_store_download.dart';
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
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// [summary] is the list row; offline, when the full task has never been
/// loaded on this device, the sheet shows it instead of an error.
Future<void> showStaffTaskDetailSheet(
  BuildContext context, {
  required String taskId,
  required TasksMessagesController controller,
  StaffTask? summary,
}) {
  return showAppBottomSheet<void>(
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
  bool _checksReady = false;
  List<StaffTaskCheckItem> _checks = const [];
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
          if (!_checksReady) {
            _checks = List<StaffTaskCheckItem>.of(detail.checklist);
            _checksReady = true;
          }
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

  bool get _canMutateTasks {
    if (!Get.isRegistered<UserSession>()) return true;
    final session = Get.find<UserSession>();
    return session.can('tasks:write') || session.can('tasks:manage');
  }

  List<Map<String, dynamic>> get _checklistBody =>
      [for (final item in _checks) item.toJson()];

  int get _checkDone => _checks.where((item) => item.done).length;

  int get _checkPercent => _checks.isEmpty
      ? 0
      : ((_checkDone / _checks.length) * 100).round();

  Future<void> _saveProgress() async {
    if (_busy || !_canMutateTasks) return;
    setState(() => _busy = true);
    final result = await _repository.saveTaskProgress(
      taskId: widget.taskId,
      checklist: _checklistBody,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Checklist saved', '', force: true);
      },
      failure: (error) {
        AppSnackbar.show('Could not save progress', error.message, force: true);
      },
    );
  }

  Future<void> _complete({bool signOff = false}) async {
    if (_busy || !_canMutateTasks) return;
    setState(() => _busy = true);
    final saved = await widget.controller.completeTask(
      widget.taskId,
      signOff: signOff,
      checklist: _checks.isEmpty ? null : _checklistBody,
      requiresReview: _detail?.requiresReview ?? false,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) Navigator.of(context).pop();
  }

  Future<void> _openDocument(StaffTaskDocument file) async {
    final url = file.url?.trim() ?? '';
    if (_busy || url.isEmpty) {
      AppSnackbar.show('Unavailable', 'This file has no download link.', force: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final resolved = AuthorizedFile.resolveUrl(url);
      final response = await Dio().get<List<int>>(
        resolved,
        options: Options(
          responseType: ResponseType.bytes,
          headers: AuthorizedFile.headers(),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final data = response.data;
      if (!mounted) return;
      if (response.statusCode != 200 || data == null || data.isEmpty) {
        AppSnackbar.show(
          'Could not download file',
          'This file is no longer available.',
          force: true,
        );
        return;
      }
      final name = _downloadName(file.label, resolved);
      final lower = name.toLowerCase();
      final mime = lower.endsWith('.pdf')
          ? 'application/pdf'
          : lower.endsWith('.png')
              ? 'image/png'
              : lower.endsWith('.jpg') || lower.endsWith('.jpeg')
                  ? 'image/jpeg'
                  : 'application/octet-stream';
      final saved = await MediaStoreDownload.saveFileAndOpen(
        fileName: name,
        bytes: Uint8List.fromList(data),
        mimeType: mime,
        chooserTitle: 'Open attachment',
      );
      if (!mounted) return;
      if (!saved.success) {
        AppSnackbar.show(
          'Could not open file',
          saved.error ?? 'Could not save the file.',
          force: true,
        );
        return;
      }
      AppSnackbar.show(
        'Document downloaded successfully.',
        name,
        force: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Could not download file',
        'This file is no longer available.',
        force: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _downloadName(String label, String resolvedUrl) {
    final segments = Uri.tryParse(resolvedUrl)?.pathSegments.where((part) => part.isNotEmpty).toList() ??
        const <String>[];
    final urlName = segments.isEmpty ? 'attachment' : segments.last;
    final ext = urlName.contains('.') ? urlName.split('.').last : '';
    var base = label.trim();
    if (base.isEmpty) base = urlName;
    final hasExt = base.contains('.') && base.split('.').last.length <= 5;
    if (!hasExt && ext.isNotEmpty) base = '$base.$ext';
    return base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _busy || !_canMutateTasks) return;
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
    final pad = ResponsiveHelper.getResponsivePadding(
      context,
      horizontal: 20,
      top: 16,
      bottom: 24,
    );
    return Column(
      children: [
        Expanded(
          child: ListView(
      padding: pad,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail.title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(label: detail.statusLabel),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Task details, checklist progress, documentation and notes.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.5,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        _DetailCard(
          title: 'Task Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailPair(
                leftLabel: 'Assigned staff',
                left: _AssigneeLine(
                  name: detail.assigneeName.isEmpty
                      ? 'Unassigned'
                      : detail.assigneeName,
                ),
                rightLabel: 'Residence',
                right: Text(
                  detail.location.isEmpty ? '—' : detail.location,
                  style: _valueStyle,
                ),
              ),
              const SizedBox(height: 12),
              _DetailPair(
                leftLabel: 'Due',
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.dueLabel.isEmpty ? 'No due date' : detail.dueLabel,
                      style: _valueStyle,
                    ),
                    if (detail.kindLine.isNotEmpty)
                      Text(
                        detail.kindLine,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                rightLabel: 'Review',
                right: Text(
                  detail.requiresReview ? 'Required' : 'Not required',
                  style: _valueStyle,
                ),
              ),
              const SizedBox(height: 12),
              _DetailField(
                label: 'Sign-off',
                child: Text(
                  detail.requiresSignOff ? 'Required' : 'Not required',
                  style: _valueStyle,
                ),
              ),
            ],
          ),
        ),
        if (detail.description.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
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
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _DetailCard(
          title: 'Checklist Progress',
          trailing: '$_checkPercent%',
          child: Text(
            '$_checkDone of ${_checks.length} items complete',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _DetailCard(
          title: 'Checklist',
          child: _checks.isEmpty
              ? const Text(
                  'This task has no checklist.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _checks.length; i++)
                      _CheckRow(
                        item: _checks[i],
                        enabled: _canMutateTasks && !isCompleted,
                        onTap: () => setState(
                          () => _checks[i] =
                              _checks[i].copyWith(done: !_checks[i].done),
                        ),
                      ),
                  ],
                ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _DetailCard(
          title: 'Documentation Uploads',
          child: detail.documents.isEmpty
              ? const Text(
                  'No documents uploaded.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final file in detail.documents)
                      _DocumentRow(
                        label: file.label,
                        onTap: file.url == null ||
                                file.url!.trim().isEmpty ||
                                _busy
                            ? null
                            : () => _openDocument(file),
                      ),
                  ],
                ),
        ),
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
      ],
          ),
        ),
        if (_canMutateTasks)
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_checks.isNotEmpty && !isCompleted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SheetButton(
                    label: 'Save progress',
                    onPressed: _busy ? null : _saveProgress,
                  ),
                ),
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5,
                  color: AppColors.textHeading,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a note',
                  hintStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.5,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceWhite,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: _noteBorder(AppColors.cardBorder),
                  enabledBorder: _noteBorder(AppColors.cardBorder),
                  focusedBorder: _noteBorder(AppColors.secondaryTeal),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: 'Add note',
                      onPressed: _busy ? null : _addNote,
                    ),
                  ),
                  if (!detail.requiresSignOff || isCompleted) ...[
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 10),
                    ),
                    Expanded(
                      child: _SheetButton(
                        label: isCompleted
                            ? 'Completed'
                            : detail.requiresReview
                                ? 'Submit for review'
                                : 'Complete',
                        filled: true,
                        onPressed: (_busy || isCompleted) ? null : _complete,
                      ),
                    ),
                  ],
                ],
              ),
              if (detail.requiresSignOff && !isCompleted) ...[
                const SizedBox(height: 12),
                _SignOffBox(
                  busy: _busy,
                  onConfirm: () => _complete(signOff: true),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder _noteBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );
}

const _valueStyle = TextStyle(
  fontFamily: 'Outfit',
  fontWeight: FontWeight.w600,
  fontSize: 13.5,
  color: AppColors.textHeading,
);

class _CheckRow extends StatelessWidget {
  final StaffTaskCheckItem item;
  final bool enabled;
  final VoidCallback onTap;

  const _CheckRow({
    required this.item,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              _ThemeCheck(checked: item.done, enabled: enabled),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: item.done
                        ? AppColors.textMuted
                        : AppColors.textHeading,
                    decoration:
                        item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (item.required) ...[
                const SizedBox(width: 8),
                const Text(
                  'Must be done',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.criticalRed,
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

class _ThemeCheck extends StatelessWidget {
  final bool checked;
  final bool enabled;

  const _ThemeCheck({required this.checked, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.secondaryTeal : AppColors.textMuted;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? color : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _DocumentRow({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: AppColors.secondaryTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  const _SheetButton({
    super.key,
    required this.label,
    this.filled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = !enabled
        ? AppColors.cardBorder
        : filled
            ? AppColors.secondaryTeal
            : AppColors.surfaceWhite;
    final foreground = !enabled
        ? AppColors.textMuted
        : filled
            ? Colors.white
            : AppColors.secondaryTeal;
    return GestureDetector(
      onTap: onPressed ?? () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppColors.secondaryTeal : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.urgentBackgroundSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.urgentAmber,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.secondaryTeal,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailPair extends StatelessWidget {
  final String leftLabel;
  final Widget left;
  final String rightLabel;
  final Widget right;

  const _DetailPair({
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _DetailField(label: leftLabel, child: left)),
        const SizedBox(width: 12),
        Expanded(child: _DetailField(label: rightLabel, child: right)),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _AssigneeLine extends StatelessWidget {
  final String name;

  const _AssigneeLine({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name == 'Unassigned'
        ? '—'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.quickActionCreateShiftBg,
          child: Text(
            initials,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: AppColors.secondaryTeal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: _valueStyle),
        ),
      ],
    );
  }
}

/// The web sign-off box: the person completing the task confirms it.
class _SignOffBox extends StatefulWidget {
  final bool busy;
  final VoidCallback onConfirm;

  const _SignOffBox({required this.busy, required this.onConfirm});

  @override
  State<_SignOffBox> createState() => _SignOffBoxState();
}

class _SignOffBoxState extends State<_SignOffBox> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    const text = TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textBody);
    return Container(
      key: const Key('task-sign-off'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.urgentBackgroundSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.urgentBackground),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_outlined, size: 16, color: AppColors.urgentAmber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This task requires sign-off. Confirming below records that you '
                  'completed it, with the date and time.',
                  style: text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            key: const Key('task-sign-off-confirm'),
            onTap: () => setState(() => _confirmed = !_confirmed),
            child: Row(
              children: [
                Checkbox(
                  value: _confirmed,
                  activeColor: AppColors.secondaryTeal,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'I confirm this task was completed as described.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _SheetButton(
            key: const Key('task-sign-off-submit'),
            label: widget.busy ? 'Signing…' : 'Sign and complete',
            filled: true,
            onPressed: !_confirmed || widget.busy ? null : widget.onConfirm,
          ),
        ],
      ),
    );
  }
}
