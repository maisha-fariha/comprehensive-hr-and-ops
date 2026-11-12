import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';
import 'create_task_sheet.dart';

Future<void> showTaskDetailSheet(
  BuildContext context, {
  required TaskItem task,
  VoidCallback? onChanged,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskDetailSheet(task: task, onChanged: onChanged),
  );
}

class _TaskDetailSheet extends StatefulWidget {
  final TaskItem task;
  final VoidCallback? onChanged;

  const _TaskDetailSheet({required this.task, this.onChanged});

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _CheckDraft {
  _CheckDraft({
    this.id,
    required this.label,
    required this.done,
    required this.required,
    this.value = '',
  });

  final String? id;
  final String label;
  bool done;
  final bool required;
  final String value;

  String get displayLabel {
    final v = value.trim();
    if (v.isEmpty) return label;
    if (label.contains(v)) return label;
    return '$label ($v)';
  }

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'label': label,
        'done': done,
        'required': required,
        if (value.trim().isNotEmpty) 'value': value.trim(),
      };
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  static const _maxUploadBytes = 25 * 1024 * 1024;

  late final TasksComplianceRepository _repository;
  late final TaskDetailLoad _load;
  final _reviewNotes = TextEditingController();
  final _note = TextEditingController();
  final _completion = TextEditingController();
  /// Review buttons currently in flight. Each one only disables itself.
  final Set<String> _reviewDecisions = {};
  bool _busy = false;
  bool _formReady = false;
  /// Owned by the sheet so ListView recycling cannot wipe confirm ticks.
  bool _signOffConfirmed = false;
  bool _reviewConfirmed = false;
  List<_CheckDraft> _checks = const [];

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<TasksComplianceRepository>();
    _load = TaskDetailLoad(_repository);
    _load.addListener(_syncForm);
    _load.fetch(widget.task.id);
  }

  @override
  void dispose() {
    _load.removeListener(_syncForm);
    _reviewNotes.dispose();
    _note.dispose();
    _completion.dispose();
    super.dispose();
  }

  void _syncForm() {
    if (_formReady || _load.loading || _load.detail == null) return;
    _formReady = true;
    final detail = _load.detail!;
    _completion.text = JsonCodec.stringOr(detail['completionNotes'], '');
    _checks = [
      for (final raw in JsonCodec.unwrapList(detail['checklist']))
        if (raw is Map)
          () {
            final map = JsonCodec.asMap(raw);
            return _CheckDraft(
              id: JsonCodec.string(map['id']),
              label: JsonCodec.stringOr(
                map['label'] ?? map['title'] ?? map['text'] ?? map['name'],
                'Item',
              ),
              done: map['completed'] == true ||
                  map['done'] == true ||
                  map['checked'] == true,
              required: map['required'] == true,
              value: JsonCodec.stringOr(
                map['value'] ??
                    map['response'] ??
                    map['answer'] ??
                    map['recordedValue'] ??
                    map['notes'],
                '',
              ),
            );
          }(),
    ];
    if (mounted) setState(() {});
  }

  Map<String, dynamic> _progressBody({String? status}) {
    final notes = _completion.text.trim();
    return {
      'status': ?status,
      'completionNotes': notes,
      'checklist': [for (final step in _checks) step.toJson()],
    };
  }

  Future<void> _saveProgress() async {
    if (_busy || !_canMutate()) return;
    setState(() => _busy = true);
    final status = _statusRaw(_load.detail);
    final result = await _repository.updateTask(
      taskId: widget.task.id,
      body: _progressBody(
        status: status == 'open' || status == 'pending' ? 'in_progress' : null,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Progress saved', widget.task.title, force: true);
        _formReady = false;
        _load.fetch(widget.task.id);
        widget.onChanged?.call();
      },
      failure: (error) {
        AppSnackbar.show('Could not save progress', error.message, force: true);
      },
    );
  }

  /// Web Complete / Sign and complete — PATCH status completed (+ signOff).
  Future<void> _complete({bool signOff = false}) async {
    if (_busy || !_canMutate()) return;
    final detail = _load.detail ?? const <String, dynamic>{};
    final needsSignOff = detail['requiresSignOff'] == true;
    setState(() => _busy = true);
    final result = await _repository.updateTask(
      taskId: widget.task.id,
      body: {
        ..._progressBody(status: 'completed'),
        if (signOff || needsSignOff) 'signOff': true,
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show(
          signOff || needsSignOff ? 'Task signed off' : 'Task completed',
          widget.task.title,
          force: true,
        );
        widget.onChanged?.call();
        Navigator.of(context).pop();
      },
      failure: (error) {
        AppSnackbar.show('Could not complete task', error.message, force: true);
      },
    );
  }

  String _signerDisplayName() {
    if (!Get.isRegistered<UserSession>()) return 'you';
    final name = Get.find<UserSession>().displayName.trim();
    return name.isEmpty ? 'you' : name;
  }

  Future<void> _addNote() async {
    final text = _note.text.trim();
    if (_busy || !_canMutate()) return;
    if (text.isEmpty) {
      AppSnackbar.show(
        'Add a note',
        'Add a note or reminder for this task.',
        force: true,
      );
      return;
    }
    setState(() => _busy = true);
    final result = await _repository.addTaskNote(
      taskId: widget.task.id,
      body: text,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        _note.clear();
        _load.fetch(widget.task.id);
        widget.onChanged?.call();
      },
      failure: (error) {
        AppSnackbar.show('Could not add note', error.message, force: true);
      },
    );
    setState(() => _busy = false);
  }

  Future<void> _upload() async {
    if (_busy || !_canMutate()) return;
    final picked = await AppFilePicker.pickFiles(
      context: context,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (picked == null || !mounted) return;
    final file = picked.files.first;
    final path = file.path;
    if (path == null) return;
    if (file.size > _maxUploadBytes) {
      AppSnackbar.show(
        'File too large',
        'PDF, JPG, PNG · Max 25MB',
        force: true,
      );
      return;
    }
    setState(() => _busy = true);
    final uploaded = await _repository.uploadTaskFile(path: path, name: file.name);
    if (!mounted) return;
    if (uploaded.isFailure) {
      setState(() => _busy = false);
      AppSnackbar.show(
        'Could not upload',
        uploaded.error?.message ?? 'Upload failed.',
        force: true,
      );
      return;
    }
    final existing = [
      for (final raw in JsonCodec.unwrapList(_load.detail?['evidence']))
        if (raw is Map) JsonCodec.asMap(raw),
    ];
    final result = await _repository.updateTask(
      taskId: widget.task.id,
      body: {
        'evidence': [
          ...existing,
          {'url': uploaded.value, 'label': file.name},
        ],
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Document uploaded', file.name, force: true);
        _formReady = false;
        _load.fetch(widget.task.id);
        widget.onChanged?.call();
      },
      failure: (error) {
        AppSnackbar.show('Could not attach document', error.message, force: true);
      },
    );
  }

  Future<void> _edit() async {
    final detail = _load.detail;
    if (detail == null || _busy || !_canMutate()) return;
    await showCreateTaskSheet(
      context,
      editingTaskId: widget.task.id,
      editing: detail,
      onCreated: () {
        _formReady = false;
        _load.fetch(widget.task.id);
        widget.onChanged?.call();
      },
    );
  }

  void _setReviewConfirmed(bool value) {
    setState(() => _reviewConfirmed = value);
  }

  Future<void> _review(String decision) async {
    if (_reviewDecisions.contains(decision)) return;
    if (decision == 'reject' && _reviewNotes.text.trim().isEmpty) {
      AppSnackbar.show('Review notes', 'Required when sending it back, so the person redoing it knows what to fix', force: true);
      return;
    }
    setState(() => _reviewDecisions.add(decision));
    final result = await GetIt.instance<TasksComplianceRepository>().reviewTask(
      taskId: widget.task.id,
      decision: decision,
      reviewNotes: _reviewNotes.text,
    );
    if (!mounted) return;
    setState(() => _reviewDecisions.remove(decision));
    result.when(
      success: (_) async {
        AppSnackbar.show(
          decision == 'approve' ? 'Task approved' : 'Sent back for correction',
          widget.task.title,
          force: true,
        );
        widget.onChanged?.call();
        if (mounted) Navigator.of(context).pop();
      },
      failure: (error) {
        AppSnackbar.show('Could not review', error.message, force: true);
      },
    );
  }

  bool _canMutate() {
    if (!Get.isRegistered<UserSession>()) return true;
    final session = Get.find<UserSession>();
    return session.can('tasks:write') || session.can('tasks:manage');
  }

  /// Web overflow Cancel/Delete — same gate as creating tasks.
  bool _canManageTasks() {
    if (!Get.isRegistered<UserSession>()) return true;
    return Get.find<UserSession>().can('tasks:manage');
  }

  /// Web shows Cancel for open + awaiting-review rows (API may say `completed`
  /// until a reviewer acts). Hide only for truly cancelled/fully done tasks.
  bool _canCancelTask(Map<String, dynamic>? detail) {
    if (!_canManageTasks() || detail == null) return false;
    final status = _statusRaw(detail);
    if (_isCancelled(status)) return false;
    if (_awaitingReview(detail, status)) return true;
    return !_isCompleted(status);
  }

  Future<void> _cancelTask() async {
    if (_busy || !_canManageTasks()) return;
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cancel this task?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'It leaves the open queue. Staff will no longer see it as due.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BarButton(
                      label: 'Keep task',
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BarButton(
                      key: const Key('task-confirm-cancel'),
                      label: 'Cancel task',
                      danger: true,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await _repository.cancelTask(widget.task.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Task cancelled', widget.task.title, force: true);
        widget.onChanged?.call();
        Navigator.of(context).pop();
      },
      failure: (error) {
        AppSnackbar.show('Could not cancel', error.message, force: true);
      },
    );
  }

  Future<void> _deleteTask() async {
    if (_busy || !_canManageTasks()) return;
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete this task?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This permanently removes the task and its checklist.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BarButton(
                      label: 'Keep task',
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BarButton(
                      key: const Key('task-confirm-delete'),
                      label: 'Delete',
                      danger: true,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await _repository.deleteTask(widget.task.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Task deleted', widget.task.title, force: true);
        widget.onChanged?.call();
        Navigator.of(context).pop();
      },
      failure: (error) {
        AppSnackbar.show('Could not delete', error.message, force: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(_buildSheet);
  }

  Widget _buildSheet() {
    final canMutate = _canMutate();
    final height = MediaQuery.sizeOf(context).height * 0.92;
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
                height: ResponsiveHelper.getResponsiveHeight(context, 4),
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  top: 14,
                  bottom: 8,
                ),
                child: _SheetHeader(
                  title: widget.task.title,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _load,
                  builder: (context, _) {
                    if (_load.loading && _load.detail == null) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        ),
                      );
                    }
                    if (_load.error != null && _load.detail == null) {
                      return Center(
                        child: Padding(
                          padding: ResponsiveHelper.getResponsivePadding(
                            context,
                            all: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _load.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _load.fetch(widget.task.id),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(fontFamily: 'Outfit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final detail = _load.detail ?? const <String, dynamic>{};
                    final statusRaw = _statusRaw(detail);
                    final completed = _isCompleted(statusRaw);
                    final cancelled = _isCancelled(statusRaw);
                    final statusLabel = _statusLabel(statusRaw, detail);
                    final files = [
                      for (final raw in JsonCodec.unwrapList(detail['evidence']))
                        if (raw is Map)
                          JsonCodec.stringOr(
                            JsonCodec.asMap(raw)['label'] ??
                                JsonCodec.asMap(raw)['name'] ??
                                JsonCodec.asMap(raw)['fileName'],
                            'File',
                          ),
                    ];
                    final doneCount = _checks.where((step) => step.done).length;
                    final checklistPercent = _checks.isEmpty
                        ? 0
                        : ((doneCount / _checks.length) * 100).round();
                    final assignee = _primaryAssignee(detail);
                    final typePriority = [
                      _typeLabel(
                        JsonCodec.stringOr(
                          detail['taskType'] ?? detail['type'],
                          '',
                        ),
                      ),
                      _priorityLabel(
                        JsonCodec.stringOr(detail['priority'], ''),
                      ),
                    ].where((part) => part.isNotEmpty).join(' · ');

                    // Keep the whole form mounted so confirm checkboxes and
                    // review fields survive scroll (web modal parity).
                    return SingleChildScrollView(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        bottom: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        _DetailsCard(
                          statusLabel: statusLabel,
                          awaitingReview: _awaitingReview(detail, statusRaw),
                          completed: completed && !_awaitingReview(detail, statusRaw),
                          assigneeName: assignee.name,
                          assigneeInitials: assignee.initials,
                          residence: _residence(detail),
                          client: _client(detail),
                          due: _due(detail),
                          typePriority:
                              typePriority.isEmpty ? null : typePriority,
                          reviewTitle: _reviewTitle(detail),
                          reviewNote: _reviewNote(detail),
                          reviewMeta: _reviewMeta(detail),
                          signOffTitle: _signOffTitle(detail),
                          signOffTime: _signOffTime(detail),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Checklist Progress',
                          trailing: Text(
                            '$checklistPercent%',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textHeading,
                            ),
                          ),
                          subtitle: _checks.isEmpty
                              ? '0 of 0 items complete'
                              : '$doneCount of ${_checks.length} items complete',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(height: 1, color: AppColors.cardBorder),
                              const SizedBox(height: 10),
                              const Text(
                                'Checklist',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textHeading,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (_checks.isEmpty)
                                const Text(
                                  'This task has no checklist.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              else
                                for (var i = 0; i < _checks.length; i++)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    value: _checks[i].done,
                                    onChanged: completed || !canMutate
                                        ? null
                                        : (value) => setState(
                                              () => _checks[i].done =
                                                  value ?? false,
                                            ),
                                    title: Text(
                                      _checks[i].displayLabel,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        decoration: _checks[i].done
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        if (JsonCodec.stringOr(
                              detail['description'] ?? detail['body'],
                              '',
                            )
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Description',
                            child: Text(
                              JsonCodec.stringOr(
                                detail['description'] ?? detail['body'],
                                '',
                              ).trim(),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5,
                                color: AppColors.textBody,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Documentation Uploads',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (canMutate)
                                _UploadZone(busy: _busy, onTap: _upload),
                              for (final name in files)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Notes / Reminders',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (canMutate && !completed) ...[
                                TextField(
                                  controller: _note,
                                  minLines: 3,
                                  maxLines: 5,
                                  decoration: _fieldDecoration(
                                    'Add a note or reminder for this task...',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    key: const Key('task-add-note'),
                                    onPressed: _busy ? null : _addNote,
                                    icon: const Icon(
                                      Icons.note_add_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Add Note'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (_load.notes.isEmpty)
                                const Text(
                                  'Nothing written yet.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              else
                                for (final note in _load.notes)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      JsonCodec.stringOr(
                                        note['body'] ??
                                            note['text'] ??
                                            note['note'],
                                        'Note',
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        color: AppColors.textBody,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        // Web: Finishing up + completion notes for open tasks.
                        if (!cancelled) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Finishing up',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Completion notes',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (canMutate && !completed)
                                  TextField(
                                    key: const Key('task-completion-notes'),
                                    controller: _completion,
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: _fieldDecoration(
                                      'What was done, and anything the next person should know...',
                                    ),
                                  )
                                else
                                  Text(
                                    _completion.text.trim().isEmpty
                                        ? 'No completion notes.'
                                        : _completion.text.trim(),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      color: AppColors.textBody,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        // Sign-Off Confirmation Card while staff sign-off is still owed.
                        if (canMutate &&
                            !completed &&
                            !cancelled &&
                            detail['requiresSignOff'] == true &&
                            !_awaitingReview(detail, statusRaw) &&
                            detail['signedOffAt'] == null) ...[
                          const SizedBox(height: 12),
                          _TaskSignOffBox(
                            signerName: _signerDisplayName(),
                            busy: _busy,
                            confirmed: _signOffConfirmed,
                            onConfirmedChanged: (v) =>
                                setState(() => _signOffConfirmed = v),
                            onConfirm: () => _complete(signOff: true),
                          ),
                        ],
                        if (_canReview(detail, statusRaw))
                          ..._reviewBox(context, detail),
                      ],
                      ),
                    );
                  },
                ),
              ),
              _ActionBar(
                busy: _busy,
                completed: _isCompleted(_statusRaw(_load.detail)),
                cancelled: _isCancelled(_statusRaw(_load.detail)),
                requiresSignOff: _load.detail?['requiresSignOff'] == true,
                onClose: () => Navigator.of(context).pop(),
                onEdit: canMutate && _load.detail != null ? _edit : null,
                onSave: canMutate && _load.detail != null ? _saveProgress : null,
                onComplete: canMutate &&
                        _load.detail != null &&
                        _load.detail?['requiresSignOff'] != true &&
                        !_awaitingReview(
                          _load.detail ?? const {},
                          _statusRaw(_load.detail),
                        )
                    ? () => _complete()
                    : null,
                // Web still offers Cancel while the row is "Awaiting review",
                // even though the API status may already be `completed`.
                onCancelTask: _canCancelTask(_load.detail) ? _cancelTask : null,
                onDelete: _canManageTasks() && _load.detail != null
                    ? _deleteTask
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusRaw(Map<String, dynamic>? detail) {
  return JsonCodec.stringOr(
    detail?['status'] ?? detail?['state'],
    '',
  ).toLowerCase();
}

bool _isCompleted(String raw) {
  return raw == 'completed' || raw == 'done' || raw == 'complete' || raw == 'closed';
}

bool _isCancelled(String raw) {
  return raw == 'cancelled' || raw == 'canceled';
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textMuted),
    contentPadding: const EdgeInsets.all(12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
  );
}

({String name, String initials}) _primaryAssignee(Map<String, dynamic> detail) {
  for (final raw in JsonCodec.unwrapList(detail['assignees'])) {
    if (raw is! Map) continue;
    final map = JsonCodec.asMap(raw);
    final staff = JsonCodec.mapAt(map, 'staff') ?? map;
    final name = IsoDateRange.personName(staff).trim();
    if (name.isEmpty || name == '—') continue;
    return (
      name: name,
      initials: IsoDateRange.initials(name, fallback: ''),
    );
  }
  return (name: 'Unassigned', initials: '');
}

String _residence(Map<String, dynamic> detail) {
  final residence = JsonCodec.mapAt(detail, 'residence');
  final room = JsonCodec.string(detail['roomArea']);
  final name = JsonCodec.stringOr(
    residence?['name'] ?? detail['residenceName'],
    '—',
  );
  if (room == null || room.trim().isEmpty) return name;
  if (name == '—') return room.trim();
  return '$name $room'.trim();
}

String _client(Map<String, dynamic> detail) {
  final client = JsonCodec.mapAt(detail, 'client');
  if (client == null) {
    return JsonCodec.stringOr(detail['clientName'], '');
  }
  final name = IsoDateRange.personName(client).trim();
  return name == '—' ? '' : name;
}

String _statusLabel(String raw, Map<String, dynamic> detail) {
  if (_awaitingReview(detail, raw)) return 'Awaiting review';
  final lower = raw.toLowerCase();
  if (lower == 'completed' ||
      lower == 'done' ||
      lower == 'complete' ||
      lower == 'closed' ||
      lower == 'approved') {
    return 'Completed';
  }
  if (lower == 'overdue' || lower == 'late') return 'Overdue';
  final due = JsonCodec.dateTime(
    detail['dueAt'] ?? detail['dueDate'] ?? detail['scheduledAt'],
  );
  if (due != null && due.toUtc().isBefore(TenantClock.now().toUtc())) {
    return 'Overdue';
  }
  switch (lower) {
    case '':
    case 'open':
    case 'pending':
    case 'due':
      return 'Pending';
    case 'in_progress':
      return 'In progress';
    default:
      if (raw.isEmpty) return 'Pending';
      return raw[0].toUpperCase() + raw.substring(1);
  }
}

String _typeLabel(String raw) {
  final text = raw.replaceAll('_', ' ').trim();
  if (text.isEmpty) return '';
  return text[0].toUpperCase() + text.substring(1);
}

String _priorityLabel(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '';
  final word = text[0].toUpperCase() + text.substring(1).toLowerCase();
  return '$word priority';
}

String _due(Map<String, dynamic> detail) {
  final due = JsonCodec.dateTime(detail['dueAt'] ?? detail['dueDate']);
  if (due == null) return 'No due date';
  return WebFormat.dateTime(due);
}

/// Web review box: finished (or already in a review status), a review is
/// required, and nobody has reviewed it yet. That is “Awaiting review”.
bool _awaitingReview(Map<String, dynamic> detail, String status) {
  final raw = status.toLowerCase();
  final reviewed = detail['reviewedAt'];
  final notReviewed = reviewed == null ||
      (reviewed is String && reviewed.trim().isEmpty);
  if (!notReviewed) return false;
  if (raw == 'pending_review' ||
      raw == 'awaiting_review' ||
      raw == 'in_review' ||
      raw == 'review') {
    return true;
  }
  final finished = raw == 'completed' || raw == 'done' || raw == 'complete';
  return finished && detail['requiresReview'] == true;
}

String _reviewTitle(Map<String, dynamic> detail) {
  if (detail['requiresReview'] != true) return 'Not required';
  final reviewed = JsonCodec.dateTime(detail['reviewedAt']);
  if (reviewed == null) return 'Waiting on a reviewer';
  final name = JsonCodec.string(detail['reviewedByName'])?.trim() ?? '';
  if (name.isNotEmpty) return 'Reviewed by $name';
  return 'Reviewed ${WebFormat.dateTime(reviewed)}';
}

String? _reviewNote(Map<String, dynamic> detail) {
  final note = JsonCodec.string(detail['reviewNotes']);
  if (note == null || note.trim().isEmpty) return null;
  return note.trim();
}

String? _reviewMeta(Map<String, dynamic> detail) {
  final parts = <String>[];
  final at = JsonCodec.dateTime(detail['reviewedAt']);
  if (at != null) parts.add(WebFormat.dateTime(at));
  final ip = JsonCodec.string(detail['reviewedByIp'])?.trim() ?? '';
  if (ip.isNotEmpty) parts.add('IP $ip');
  return parts.isEmpty ? null : parts.join(' · ');
}

String _signOffTitle(Map<String, dynamic> detail) {
  if (detail['requiresSignOff'] != true) return 'Not required';
  final name = JsonCodec.string(detail['signedOffName']);
  if (name == null || name.trim().isEmpty) {
    // Web copy when sign-off is still outstanding.
    return detail['signedOffAt'] == null ? 'Needed to complete' : 'Signed off';
  }
  return 'Signed off by ${name.trim()}';
}

String? _signOffTime(Map<String, dynamic> detail) {
  final parts = <String>[];
  final at = JsonCodec.dateTime(detail['signedOffAt']);
  if (at != null) parts.add(WebFormat.dateTime(at));
  final ip = JsonCodec.string(detail['signedOffIp'])?.trim() ?? '';
  if (ip.isNotEmpty) parts.add('IP $ip');
  return parts.isEmpty ? null : parts.join(' · ');
}

bool _canReview(Map<String, dynamic> detail, String status) {
  final allowed = Get.isRegistered<UserSession>() &&
      Get.find<UserSession>().can('tasks:review');
  if (!allowed) return false;
  return _awaitingReview(detail, status);
}

extension on _TaskDetailSheetState {
  List<Widget> _reviewBox(BuildContext context, Map<String, dynamic> detail) {
    final signedName =
        JsonCodec.string(detail['signedOffName'])?.trim() ?? '';
    final signedAt = JsonCodec.dateTime(detail['signedOffAt']);
    final signedIp =
        JsonCodec.string(detail['signedOffIp'])?.trim() ?? '';
    final canApprove =
        _reviewConfirmed && !_reviewDecisions.contains('approve');
    return [
      const SizedBox(height: 12),
      Text(
        'Manager Review & Sign-Off',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: AppColors.textHeading,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Verify completion details and record your supervisory sign-off.',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      if (signedName.isNotEmpty || signedAt != null) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'STAFF EXECUTION SIGN-OFF',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.activeBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Signed by Assignee',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
              if (signedName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Signed by: $signedName',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textBody,
                  ),
                ),
              ],
              if (signedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Date & Time: ${WebFormat.dateTime(signedAt)}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textBody,
                  ),
                ),
              ],
              if (signedIp.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Audit IP: $signedIp',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 10),
      TextField(
        controller: _reviewNotes,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText:
              'Add supervisory feedback or instructions (required when sending back for correction)...',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Included in the audit history, and sent to the assignee if requesting rework.',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.5,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        key: const Key('task-review-confirm'),
        onTap: () => _setReviewConfirmed(!_reviewConfirmed),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _reviewConfirmed,
              activeColor: AppColors.secondaryTeal,
              onChanged: (v) => _setReviewConfirmed(v ?? false),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'I confirm I have inspected this task, verified the completed '
                  'checklist items and evidence, and approve it for completion.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const Key('task-review-approve'),
            onPressed: canApprove ? () => _review('approve') : null,
            icon: const Icon(Icons.draw_outlined, size: 16),
            label: Text(
              _reviewDecisions.contains('approve')
                  ? 'Approving…'
                  : 'Sign off & Approve',
            ),
          ),
          OutlinedButton(
            key: const Key('task-review-reject'),
            onPressed: _reviewDecisions.contains('reject')
                ? null
                : () => _review('reject'),
            child: Text(
              _reviewDecisions.contains('reject')
                  ? 'Sending…'
                  : 'Send back for rework',
            ),
          ),
        ],
      ),
    ];
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 40);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.secondaryTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const AppSvgIcon(AppAssets.clipboardCheck, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Task details, checklist progress, documentation and notes.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String statusLabel;
  final bool awaitingReview;
  final bool completed;
  final String assigneeName;
  final String assigneeInitials;
  final String residence;
  final String client;
  final String due;
  final String? typePriority;
  final String reviewTitle;
  final String? reviewNote;
  final String? reviewMeta;
  final String signOffTitle;
  final String? signOffTime;

  const _DetailsCard({
    required this.statusLabel,
    required this.awaitingReview,
    required this.completed,
    required this.assigneeName,
    required this.assigneeInitials,
    required this.residence,
    required this.client,
    required this.due,
    required this.typePriority,
    required this.reviewTitle,
    required this.reviewNote,
    required this.reviewMeta,
    required this.signOffTitle,
    required this.signOffTime,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = awaitingReview
        ? const Color(0xFF0284C7)
        : completed
            ? const Color(0xFF2E8C58)
            : const Color(0xFFB36B21);
    final statusBg = awaitingReview
        ? const Color(0xFFE0F2FE)
        : completed
            ? const Color(0xFFEAF6F0)
            : const Color(0xFFFCF5ED);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 14,
            children: [
              _DetailBlock(
                label: 'Assigned Staff',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: Text(
                        assigneeInitials.isEmpty ? '?' : assigneeInitials,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        assigneeName,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _DetailBlock(
                label: 'Residence',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residence,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (client.isNotEmpty)
                      Text(
                        client,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              _DetailBlock(
                label: 'Due',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (typePriority != null)
                      Text(
                        typePriority!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              _DetailBlock(
                label: 'Review',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewTitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (reviewMeta != null)
                      Text(
                        reviewMeta!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (reviewNote != null)
                      Text(
                        reviewNote!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: Color(0xFFD64545),
                        ),
                      ),
                  ],
                ),
              ),
              _DetailBlock(
                label: 'Sign-Off',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signOffTitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (signOffTime != null)
                      Text(
                        signOffTime!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ResponsiveHelper.getResponsiveWidth(context, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(14),
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
                    fontSize: 15,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _UploadZone({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAFB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('task-upload'),
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB7C4CE), width: 1.2),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload_outlined, color: AppColors.secondaryTeal),
              SizedBox(height: 8),
              Text(
                'Upload Document or drag & drop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.secondaryTeal,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'PDF, JPG, PNG · Max 25MB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool busy;
  final bool completed;
  final bool cancelled;
  final bool requiresSignOff;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onComplete;
  final VoidCallback? onCancelTask;
  final VoidCallback? onDelete;

  const _ActionBar({
    required this.busy,
    required this.completed,
    required this.cancelled,
    required this.requiresSignOff,
    required this.onClose,
    required this.onEdit,
    required this.onSave,
    this.onComplete,
    this.onCancelTask,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _BarButton(label: 'Close', onTap: onClose),
              _BarButton(label: 'Edit', onTap: busy ? null : onEdit),
              _BarButton(
                key: const Key('task-save-progress'),
                label: 'Save progress',
                onTap: busy || completed || cancelled ? null : onSave,
              ),
              // Web: plain Complete only when sign-off is not required.
              if (!requiresSignOff && onComplete != null)
                _BarButton(
                  key: const Key('task-complete'),
                  label: 'Complete task',
                  filled: true,
                  onTap: busy || completed || cancelled ? null : onComplete,
                ),
              if (onCancelTask != null)
                _BarButton(
                  key: const Key('task-cancel'),
                  label: 'Cancel task',
                  danger: true,
                  onTap: busy ? null : onCancelTask,
                ),
              if (onDelete != null)
                _BarButton(
                  key: const Key('task-delete'),
                  label: 'Delete',
                  danger: true,
                  onTap: busy ? null : onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool filled;

  const _BarButton({
    super.key,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.textMuted
        : filled
            ? Colors.white
            : danger
                ? AppColors.criticalRed
                : AppColors.textHeading;
    return Material(
      color: filled && enabled
          ? AppColors.secondaryTeal
          : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled && enabled
                  ? AppColors.secondaryTeal
                  : danger && enabled
                      ? AppColors.criticalRed.withValues(alpha: 0.35)
                      : AppColors.searchBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sign-Off Confirmation Card: confirm checkbox + Sign and complete.
class _TaskSignOffBox extends StatelessWidget {
  final String signerName;
  final bool busy;
  final bool confirmed;
  final ValueChanged<bool> onConfirmedChanged;
  final VoidCallback onConfirm;

  const _TaskSignOffBox({
    required this.signerName,
    required this.busy,
    required this.confirmed,
    required this.onConfirmedChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = confirmed && !busy;
    return Container(
      key: const Key('task-sign-off'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF5ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D5C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Color(0xFFB36B21),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textBody,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'This task requires staff sign-off. Confirming below records that ',
                      ),
                      TextSpan(
                        text: signerName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            ' completed it, with the date, time, and IP.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            key: const Key('task-sign-off-confirm'),
            onTap: () => onConfirmedChanged(!confirmed),
            child: Row(
              children: [
                Checkbox(
                  value: confirmed,
                  activeColor: AppColors.secondaryTeal,
                  onChanged: (value) =>
                      onConfirmedChanged(value ?? false),
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
          Material(
            color: canSubmit
                ? AppColors.secondaryTeal
                : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              key: const Key('task-sign-off-submit'),
              onTap: canSubmit ? onConfirm : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.draw_outlined,
                      size: 16,
                      color: canSubmit ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      busy ? 'Signing…' : 'Sign and complete',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: canSubmit ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskDetailLoad extends ChangeNotifier {
  final TasksComplianceRepository _repository;

  TaskDetailLoad(this._repository);

  bool loading = true;
  String? error;
  Map<String, dynamic>? detail;
  List<Map<String, dynamic>> notes = const [];

  Future<void> fetch(String taskId) async {
    loading = true;
    error = null;
    notifyListeners();

    final detailResult = await _repository.getTaskDetail(taskId);
    final notesResult = await _repository.getTaskNotes(taskId);

    detailResult.when(
      success: (value) => detail = value,
      failure: (err) {
        error = err.message;
        AppSnackbar.show('Could not load task', err.message);
      },
    );
    notesResult.when(
      success: (value) => notes = value,
      failure: (_) {},
    );

    loading = false;
    notifyListeners();
  }
}
