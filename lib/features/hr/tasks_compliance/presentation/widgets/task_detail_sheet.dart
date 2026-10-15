import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

Future<void> showTaskDetailSheet(
  BuildContext context, {
  required TaskItem task,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskDetailSheet(task: task),
  );
}

class _TaskDetailSheet extends StatefulWidget {
  final TaskItem task;

  const _TaskDetailSheet({required this.task});

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  late final TaskDetailLoad _load;
  final _reviewNotes = TextEditingController();
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    _load = TaskDetailLoad(GetIt.instance<TasksComplianceRepository>());
    _load.fetch(widget.task.id);
  }

  @override
  void dispose() {
    _reviewNotes.dispose();
    super.dispose();
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
          decision == 'approve' ? 'Review approved' : 'Sent back',
          widget.task.title,
          force: true,
        );
        await _load.fetch(widget.task.id);
      },
      failure: (error) {
        AppSnackbar.show('Could not review', error.message, force: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return Align(
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 17),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _load,
                builder: (context, _) {
                  if (_load.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    );
                  }
                  if (_load.error != null) {
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
                  final description = JsonCodec.stringOr(
                    detail['description'] ?? detail['body'],
                    'No description.',
                  );
                  final statusRaw = JsonCodec.stringOr(
                    detail['status'] ?? detail['state'],
                    widget.task.status.name,
                  );
                  final status = _statusLabel(statusRaw);
                  final priority = _priorityLabel(
                    JsonCodec.stringOr(detail['priority'], ''),
                  );
                  final typeLabel = _typeLabel(
                    JsonCodec.stringOr(detail['taskType'] ?? detail['type'], ''),
                  );

                  return ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      bottom: 24,
                    ).copyWith(
                      bottom: 24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      _MetaRow(label: 'Status', value: status),
                      _MetaRow(
                        label: 'Type',
                        value: () {
                          final line = [
                            typeLabel,
                            priority,
                          ].where((part) => part.isNotEmpty).join(' · ');
                          return line.isEmpty ? '—' : line;
                        }(),
                      ),
                      _MetaRow(label: 'Assigned', value: _assigned(detail)),
                      _MetaRow(label: 'Residence', value: _residence(detail)),
                      _MetaRow(label: 'Due', value: _due(detail)),
                      _MetaRow(
                        label: 'Review',
                        value: detail['requiresReview'] == true ? 'Required' : 'Not required',
                      ),
                      _MetaRow(
                        label: 'Sign-off',
                        value: detail['requiresSignOff'] == true ? 'Required' : 'Not required',
                      ),
                      ..._checklist(context, detail),
                      ..._evidence(context, detail),
                      if (_canReview(detail, statusRaw)) ..._reviewBox(context),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 6),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textBody,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 16),
                      ),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 8),
                      ),
                      if (_load.notes.isEmpty)
                        Text(
                          'No notes yet.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              13,
                            ),
                          ),
                        )
                      else
                        for (final note in _load.notes) ...[
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(
                              bottom: ResponsiveHelper.getResponsiveHeight(
                                context,
                                8,
                              ),
                            ),
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              all: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.searchBorder),
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveRadius(context, 12),
                              ),
                            ),
                            child: Text(
                              JsonCodec.stringOr(
                                note['body'] ?? note['text'] ?? note['note'],
                                'Note',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  13,
                                ),
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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

String _statusLabel(String raw) {
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

bool _canReview(Map<String, dynamic> detail, String status) {
  final allowed = Get.isRegistered<UserSession>() &&
      Get.find<UserSession>().can('tasks:review');
  if (!allowed) return false;
  final raw = status.toLowerCase();
  return detail['requiresReview'] == true || raw.contains('review');
}

List<Widget> _checklist(BuildContext context, Map<String, dynamic> detail) {
  final steps = [
    for (final raw in JsonCodec.unwrapList(detail['checklist']))
      if (raw is Map) JsonCodec.asMap(raw),
  ];
  if (steps.isEmpty) {
    return [
      const SizedBox(height: 12),
      Text(
        'Checklist',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: AppColors.textHeading,
        ),
      ),
      const Text(
        '0 of 0 items complete',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 12.5, color: AppColors.textSecondary),
      ),
      const Text(
        'This task has no checklist.',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textMuted),
      ),
    ];
  }
  final done = steps.where((step) {
    return step['completed'] == true || step['done'] == true || step['checked'] == true;
  }).length;
  return [
    const SizedBox(height: 12),
    Text(
      'Checklist',
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        color: AppColors.textHeading,
      ),
    ),
    Text(
      '$done of ${steps.length} items complete',
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5, color: AppColors.textSecondary),
    ),
    for (final step in steps)
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        value: step['completed'] == true || step['done'] == true || step['checked'] == true,
        onChanged: null,
        title: Text(
          JsonCodec.stringOr(step['label'] ?? step['title'] ?? step['text'] ?? step['name'], 'Item'),
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
        ),
      ),
  ];
}

List<Widget> _evidence(BuildContext context, Map<String, dynamic> detail) {
  final files = [
    for (final raw in JsonCodec.unwrapList(detail['evidence']))
      if (raw is Map) JsonCodec.asMap(raw),
  ];
  if (files.isEmpty) {
    return [
      const SizedBox(height: 8),
      Text(
        'Documentation Uploads',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: AppColors.textHeading,
        ),
      ),
      const Text(
        'No documents uploaded.',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textMuted),
      ),
    ];
  }
  return [
    const SizedBox(height: 8),
    Text(
      'Documentation',
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        color: AppColors.textHeading,
      ),
    ),
    for (final file in files)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          JsonCodec.stringOr(file['label'] ?? file['name'] ?? file['fileName'] ?? file['url'], 'File'),
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textBody),
        ),
      ),
  ];
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
