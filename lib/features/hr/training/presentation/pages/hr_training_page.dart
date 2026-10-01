import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/entities/training_form.dart';
import '../controllers/hr_training_controller.dart';
import '../widgets/training_common.dart';
import '../widgets/training_course_widgets.dart';
import 'hr_training_course_page.dart';
import 'hr_training_form_page.dart';

/// Manager "Training" — mirrors web `/dashboard/training`.
class HrTrainingPage extends StatefulWidget {
  final TrainingFilePicker pickFile;

  const HrTrainingPage({super.key, this.pickFile = pickTrainingMaterial});

  @override
  State<HrTrainingPage> createState() => _HrTrainingPageState();
}

class _HrTrainingPageState extends State<HrTrainingPage> {
  late final HrTrainingController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<HrTrainingController>());
  }

  @override
  void dispose() {
    Get.delete<HrTrainingController>();
    super.dispose();
  }

  Future<void> _open(String courseId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HrTrainingCoursePage(courseId: courseId, pickFile: widget.pickFile),
      ),
    );
    if (mounted) await _c.refreshAll();
  }

  Future<void> _create() async {
    await openTrainingForm(
      context,
      edit: false,
      initial: TrainingFormValues(),
      code: 'New course',
      repository: _c.repository,
      session: _c.session,
      onSave: _c.createCourse,
      pickFile: widget.pickFile,
    );
  }

  Future<void> _delete(TrainingCourse course) => showTrainingConfirm(
        context,
        title: 'Delete this course?',
        description: '"${course.title}" leaves both lists. Its assignments and '
            'certificates are kept rather than destroyed, so it can be restored.',
        confirmLabel: 'Delete',
        onConfirm: () => _c.deleteCourse(course),
      );

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          const TrainingHeader(title: 'Training'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshAll,
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    _actions(),
                    const SizedBox(height: 15),
                    _kpis(),
                    const SizedBox(height: 15),
                    TrainingCourseCards(
                      courses: _c.courseViews,
                      onView: (course) => _open(course.id),
                    ),
                    const SizedBox(height: 15),
                    ..._list(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    final archived = _c.includeArchived.value;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        HandoverButton(
          key: const ValueKey('training-show-archived'),
          label: archived ? 'Archived shown' : 'Show archived',
          filled: archived,
          onPressed: _c.toggleArchived,
        ),
        if (_c.canManage)
          HandoverButton(
            key: const ValueKey('training-new-course'),
            label: 'New course',
            icon: Icons.add_rounded,
            filled: true,
            onPressed: _create,
          ),
      ],
    );
  }

  Widget _kpis() {
    final s = _c.summary.value;
    return TrainingTileGrid(
      tiles: [
        TrainingStatTile(
          key: const ValueKey('training-kpi-assignments'),
          icon: Icons.assignment_outlined,
          tone: TrainingTone.info,
          value: s.assignments,
          label: 'Assignments',
          hint: 'Given out in total',
        ),
        TrainingStatTile(
          key: const ValueKey('training-kpi-completed'),
          icon: Icons.check_circle_outline_rounded,
          tone: TrainingTone.success,
          value: s.completed,
          label: 'Completed',
          hint: 'Signed off',
        ),
        TrainingStatTile(
          key: const ValueKey('training-kpi-overdue'),
          icon: Icons.warning_amber_rounded,
          tone: TrainingTone.danger,
          value: s.overdue,
          label: 'Overdue',
          hint: 'Past their due date',
        ),
        TrainingStatTile(
          key: const ValueKey('training-kpi-mandatory'),
          icon: Icons.gpp_maybe_outlined,
          tone: TrainingTone.warning,
          value: s.mandatoryOutstanding,
          label: 'Mandatory outstanding',
          hint: 'Required, not yet done',
        ),
      ],
    );
  }

  List<Widget> _list(BuildContext context) {
    if (_c.loading.value && _c.courses.isEmpty) {
      return [
        for (var i = 0; i < 3; i++)
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ];
    }
    if (_c.courses.isEmpty) {
      final error = _c.loadError.value;
      return [
        TrainingEmptyState(
          icon: Icons.school_outlined,
          title: error != null ? 'Training could not be loaded' : 'No courses',
          message: error ?? 'Courses you create can be assigned to staff and quizzed.',
        ),
      ];
    }
    return [
      for (final course in _c.courses) ...[
        TrainingCourseRow(
          key: ValueKey('training-row-${course.id}'),
          course: course,
          canManage: _c.canManage,
          busy: _c.busyId.value == course.id,
          onOpen: () => _open(course.id),
          onArchive: (archive) => _c.setArchived(course, archive),
          onDelete: () => _delete(course),
        ),
        const SizedBox(height: 12),
      ],
      AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: _c.total.value,
        totalPages: _c.totalPages.value,
        limitOptions: HrTrainingController.pageSizes,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    ];
  }
}
