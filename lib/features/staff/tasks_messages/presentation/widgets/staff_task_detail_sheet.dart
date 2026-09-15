import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_task_detail.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';
import '../controllers/tasks_messages_controller.dart';

Future<void> showStaffTaskDetailSheet(
  BuildContext context, {
  required String taskId,
  required TasksMessagesController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StaffTaskDetailSheet(
      taskId: taskId,
      controller: controller,
    ),
  );
}

class _StaffTaskDetailSheet extends StatefulWidget {
  final String taskId;
  final TasksMessagesController controller;

  const _StaffTaskDetailSheet({
    required this.taskId,
    required this.controller,
  });

  @override
  State<_StaffTaskDetailSheet> createState() => _StaffTaskDetailSheetState();
}

class _StaffTaskDetailSheetState extends State<_StaffTaskDetailSheet> {
  late final StaffTasksMessagesRepository _repository;
  StaffTaskDetail? _detail;
  String? _error;
  bool _loading = true;
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
      _loading = true;
      _error = null;
    });
    final result = await _repository.getTaskDetail(widget.taskId);
    if (!mounted) return;
    result.when(
      success: (detail) {
        setState(() {
          _detail = detail;
          _loading = false;
        });
      },
      failure: (error) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      },
    );
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
    return ListView(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 16,
        bottom: 24,
      ),
      children: [
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
        if (detail.notes.isEmpty)
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
                onPressed: (_busy || detail.isCompleted) ? null : _complete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text(detail.isCompleted ? 'Completed' : 'Complete'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
