import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';

Future<void> showTaskDetailSheet(
  BuildContext context, {
  required TaskItem task,
}) {
  return showModalBottomSheet<void>(
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

  @override
  void initState() {
    super.initState();
    _load = TaskDetailLoad(GetIt.instance<TasksComplianceRepository>());
    _load.fetch(widget.task.id);
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
                  final status = JsonCodec.stringOr(
                    detail['status'] ?? detail['state'],
                    widget.task.status.name,
                  );
                  final priority = JsonCodec.stringOr(
                    detail['priority'],
                    '—',
                  );

                  return ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      bottom: 24,
                    ),
                    children: [
                      _MetaRow(label: 'Status', value: status),
                      _MetaRow(label: 'Priority', value: priority),
                      _MetaRow(label: 'When', value: widget.task.timeLabel),
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
