import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
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
  });

  final String? id;
  final String label;
  bool done;
  final bool required;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'label': label,
        'done': done,
        'required': required,
      };
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  static const _maxUploadBytes = 25 * 1024 * 1024;

  late final TasksComplianceRepository _repository;
  late final TaskDetailLoad _load;
  final _reviewNotes = TextEditingController();
  final _note = TextEditingController();
  final _completion = TextEditingController();
  bool _reviewing = false;
  bool _busy = false;
  bool _formReady = false;
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
          _CheckDraft(
            id: JsonCodec.string(JsonCodec.asMap(raw)['id']),
            label: JsonCodec.stringOr(
              JsonCodec.asMap(raw)['label'] ??
                  JsonCodec.asMap(raw)['title'] ??
                  JsonCodec.asMap(raw)['text'] ??
                  JsonCodec.asMap(raw)['name'],
              'Item',
            ),
            done: JsonCodec.asMap(raw)['completed'] == true ||
                JsonCodec.asMap(raw)['done'] == true ||
                JsonCodec.asMap(raw)['checked'] == true,
            required: JsonCodec.asMap(raw)['required'] == true,
          ),
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

  Future<void> _complete() async {
    if (_busy || !_canMutate()) return;
    final detail = _load.detail ?? const <String, dynamic>{};
    setState(() => _busy = true);
    final result = await _repository.updateTask(
      taskId: widget.task.id,
      body: {
        ..._progressBody(status: 'completed'),
        if (detail['requiresSignOff'] == true) 'signOff': true,
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Task completed', widget.task.title, force: true);
        widget.onChanged?.call();
        Navigator.of(context).pop();
      },
      failure: (error) {
        AppSnackbar.show('Could not complete task', error.message, force: true);
      },
    );
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

  Future<void> _review(String decision) async {
    if (decision == 'reject' && _reviewNotes.text.trim().isEmpty) {
      AppSnackbar.show('Review notes', 'Required when sending it back, so the person redoing it knows what to fix', force: true);
      return;
    }
    setState(() => _reviewing = true);
    final result = await GetIt.instance<TasksComplianceRepository>().reviewTask(
      taskId: widget.task.id,
      decision: decision,
      reviewNotes: _reviewNotes.text,
    );
    if (!mounted) return;
    setState(() => _reviewing = false);
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
                    final description = JsonCodec.string(
                      detail['description'] ?? detail['body'],
                    );
                    final statusRaw = _statusRaw(detail);
                    final completed = _isCompleted(statusRaw);
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

                    return ListView(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        bottom: 16,
                      ),
                      children: [
                        _SectionCard(
                          title: 'Task details',
                          child: Column(
                            children: [
                              _MetaRow(
                                label: 'Status',
                                value: _statusLabel(statusRaw, detail),
                              ),
                              _MetaRow(
                                label: 'Type',
                                value: () {
                                  final line = [
                                    _typeLabel(JsonCodec.stringOr(
                                      detail['taskType'] ?? detail['type'],
                                      '',
                                    )),
                                    _priorityLabel(JsonCodec.stringOr(detail['priority'], '')),
                                  ].where((part) => part.isNotEmpty).join(' · ');
                                  return line.isEmpty ? '—' : line;
                                }(),
                              ),
                              _MetaRow(label: 'Assigned', value: _assigned(detail)),
                              _MetaRow(label: 'Residence', value: _residence(detail)),
                              _MetaRow(label: 'Due', value: _due(detail)),
                              _MetaRow(
                                label: 'Review',
                                value: _reviewValue(detail),
                              ),
                              _MetaRow(
                                label: 'Sign-off',
                                value: detail['requiresSignOff'] == true
                                    ? 'Required'
                                    : 'Not required',
                              ),
                              if (description != null && description.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    description.trim(),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      color: AppColors.textBody,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Checklist',
                          subtitle: _checks.isEmpty
                              ? '0 of 0 items complete'
                              : '$doneCount of ${_checks.length} items complete',
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
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        value: _checks[i].done,
                                        onChanged: completed || !canMutate
                                            ? null
                                            : (value) => setState(
                                                  () => _checks[i].done = value ?? false,
                                                ),
                                        title: Text(
                                          _checks[i].label,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Documentation Uploads',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (canMutate) _UploadZone(busy: _busy, onTap: _upload),
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
                              if (canMutate) ...[
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
                                    icon: const Icon(Icons.note_add_outlined, size: 16),
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
                                        note['body'] ?? note['text'] ?? note['note'],
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
                              if (canMutate)
                                TextField(
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
                        if (_canReview(detail, statusRaw)) ..._reviewBox(context),
                      ],
                    );
                  },
                ),
              ),
              _ActionBar(
                busy: _busy,
                completed: _isCompleted(_statusRaw(_load.detail)),
                onClose: () => Navigator.of(context).pop(),
                onEdit: canMutate && _load.detail != null ? _edit : null,
                onSave: canMutate && _load.detail != null ? _saveProgress : null,
                onComplete:
                    canMutate && _load.detail != null ? _complete : null,
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

String _assigned(Map<String, dynamic> detail) {
  final names = <String>[];
  for (final raw in JsonCodec.unwrapList(detail['assignees'])) {
    if (raw is! Map) continue;
    final map = JsonCodec.asMap(raw);
    final staff = JsonCodec.mapAt(map, 'staff') ?? map;
    final name = JsonCodec.string(staff['name'] ?? staff['fullName']);
    if (name != null && name.trim().isNotEmpty) {
      names.add(name.trim());
      continue;
    }
    final both = [
      JsonCodec.string(staff['firstName']),
      JsonCodec.string(staff['lastName']),
    ].whereType<String>().join(' ').trim();
    if (both.isNotEmpty) names.add(both);
  }
  return names.isEmpty ? 'Unassigned' : names.join(', ');
}

String _residence(Map<String, dynamic> detail) {
  final residence = JsonCodec.mapAt(detail, 'residence');
  return JsonCodec.stringOr(
    residence?['name'] ?? detail['residenceName'],
    '—',
  );
}

String _statusLabel(String raw, Map<String, dynamic> detail) {
  if (_awaitingReview(detail, raw)) return 'Awaiting review';
  switch (raw.toLowerCase()) {
    case '':
    case 'open':
    case 'pending':
    case 'due':
      return 'Pending';
    case 'in_progress':
      return 'In progress';
    case 'completed':
    case 'done':
    case 'complete':
    case 'closed':
      return 'Completed';
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
  final local = due.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Web review box: status is completed or done, a review is required, and
/// nobody has reviewed it yet. That is the “Awaiting review” state.
bool _awaitingReview(Map<String, dynamic> detail, String status) {
  final raw = status.toLowerCase();
  final finished = raw == 'completed' || raw == 'done';
  if (!finished || detail['requiresReview'] != true) return false;
  final reviewed = detail['reviewedAt'];
  if (reviewed == null) return true;
  return reviewed is String && reviewed.trim().isEmpty;
}

String _reviewValue(Map<String, dynamic> detail) {
  if (detail['requiresReview'] != true) return 'Not required';
  final reviewed = detail['reviewedAt'];
  if (reviewed == null || (reviewed is String && reviewed.trim().isEmpty)) {
    return 'Waiting on a reviewer';
  }
  return 'Reviewed';
}

bool _canReview(Map<String, dynamic> detail, String status) {
  final allowed = Get.isRegistered<UserSession>() &&
      Get.find<UserSession>().can('tasks:review');
  if (!allowed) return false;
  return _awaitingReview(detail, status);
}

extension on _TaskDetailSheetState {
  List<Widget> _reviewBox(BuildContext context) {
    return [
      const SizedBox(height: 12),
      Text(
        'Review',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: AppColors.textHeading,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _reviewNotes,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Review notes',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Required when sending it back, so the person redoing it knows what to fix',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 11.5, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          FilledButton(
            onPressed: _reviewing ? null : () => _review('approve'),
            child: const Text('Approve'),
          ),
          OutlinedButton(
            onPressed: _reviewing ? null : () => _review('reject'),
            child: const Text('Send back'),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, required this.child, this.subtitle});

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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textHeading,
            ),
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
            border: Border.all(color: const Color(0xFFD5DEE6)),
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
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onComplete;

  const _ActionBar({
    required this.busy,
    required this.completed,
    required this.onClose,
    required this.onEdit,
    required this.onSave,
    required this.onComplete,
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
                onTap: busy || completed ? null : onSave,
              ),
              _BarButton(
                key: const Key('task-complete'),
                label: 'Complete task',
                filled: true,
                onTap: busy || completed ? null : onComplete,
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
  final bool filled;

  const _BarButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.primaryNavy : AppColors.surfaceWhite;
    final textColor = filled ? Colors.white : AppColors.textHeading;
    return Material(
      color: onTap == null && filled ? AppColors.primaryNavy.withValues(alpha: 0.4) : color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: filled ? null : Border.all(color: AppColors.searchBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 80),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textHeading,
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
