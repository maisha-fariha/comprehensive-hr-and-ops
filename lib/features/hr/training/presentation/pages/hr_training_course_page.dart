import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/training_course_view.dart';
import '../../domain/entities/training_form.dart';
import '../../domain/repositories/hr_training_repository.dart';
import '../controllers/hr_training_course_controller.dart';
import '../training_labels.dart';
import '../widgets/training_action_tabs.dart';
import '../widgets/training_common.dart';
import '../widgets/training_course_tabs.dart';
import 'hr_training_form_page.dart';

/// Manager course detail — mirrors web `/dashboard/training/[trainingId]`.
class HrTrainingCoursePage extends StatefulWidget {
  final String courseId;
  final String initialTab;
  final TrainingFilePicker pickFile;

  const HrTrainingCoursePage({
    super.key,
    required this.courseId,
    this.initialTab = 'overview',
    this.pickFile = pickTrainingMaterial,
  });

  @override
  State<HrTrainingCoursePage> createState() => _HrTrainingCoursePageState();
}

class _HrTrainingCoursePageState extends State<HrTrainingCoursePage> {
  late final HrTrainingCourseController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(
      HrTrainingCourseController(
        repository: GetIt.instance<HrTrainingRepository>(),
        session: Get.find<UserSession>(),
        courseId: widget.courseId,
        initialTab: widget.initialTab,
      ),
      tag: widget.courseId,
    );
  }

  @override
  void dispose() {
    Get.delete<HrTrainingCourseController>(tag: widget.courseId);
    super.dispose();
  }

  Future<void> _edit(TrainingCourseView view) async {
    await openTrainingForm(
      context,
      edit: true,
      initial: TrainingFormValues.fromView(view),
      code: view.code,
      repository: _c.repository,
      session: _c.session,
      onSave: _c.saveEdit,
      pickFile: widget.pickFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          const TrainingHeader(title: 'Back to Training'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshAll,
              child: Obx(() {
                final view = _c.view;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    if (_c.loadError.value != null) ...[
                      HandoverPanel(
                        child: Text(
                          _c.loadError.value!,
                          style: handoverText(context, 13.5, color: AppColors.criticalRed),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    if (_c.loading.value && view == null)
                      HandoverPanel(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Loading…',
                          style: handoverText(context, 13.5, color: AppColors.textMuted),
                        ),
                      ),
                    if (view != null) ...[
                      _heading(context, view),
                      const SizedBox(height: 15),
                      _kpis(view.stats),
                      const SizedBox(height: 15),
                      _tabs(context),
                      const SizedBox(height: 15),
                      _tabBody(view),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, TrainingCourseView view) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          view.title,
          style: handoverText(context, 22, weight: FontWeight.w600, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TrainingPill(label: view.code, tone: TrainingTone.neutral),
            TrainingPill(
              label: view.status,
              tone: view.status == 'Active' ? TrainingTone.success : TrainingTone.info,
            ),
            TrainingPill(label: view.category, tone: TrainingTone.cyan),
            if (view.required)
              const TrainingPill(label: 'Certificate required', tone: TrainingTone.warning),
            if (view.mandatory) const TrainingPill(label: 'Mandatory', tone: TrainingTone.danger),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Created on: ',
            children: [
              TextSpan(
                text: TrainingLabels.date(view.course.createdAt),
                style: handoverText(context, 12.5, weight: FontWeight.w600),
              ),
            ],
          ),
          style: handoverText(context, 12.5, color: AppColors.textMuted),
        ),
        if (_c.canManage) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              HandoverButton(
                key: const ValueKey('training-assign-training'),
                label: 'Assign Training',
                icon: Icons.person_add_alt_1_outlined,
                onPressed: () => _c.tab.value = 'assignments',
              ),
              HandoverButton(
                key: const ValueKey('training-edit-training'),
                label: 'Edit Training',
                icon: Icons.edit_outlined,
                filled: true,
                onPressed: () => _edit(view),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _kpis(TrainingCourseStats stats) {
    return TrainingTileGrid(
      tiles: [
        TrainingStatTile(
          key: const ValueKey('training-course-kpi-assigned'),
          icon: Icons.assignment_outlined,
          tone: TrainingTone.info,
          value: stats.assigned,
          label: 'Assigned',
        ),
        TrainingStatTile(
          key: const ValueKey('training-course-kpi-completed'),
          icon: Icons.check_circle_outline_rounded,
          tone: TrainingTone.success,
          value: stats.completed,
          label: 'Completed',
        ),
        TrainingStatTile(
          key: const ValueKey('training-course-kpi-in-progress'),
          icon: Icons.schedule_rounded,
          tone: TrainingTone.warning,
          value: stats.inProgress,
          label: 'In Progress',
        ),
        TrainingStatTile(
          key: const ValueKey('training-course-kpi-overdue'),
          icon: Icons.warning_amber_rounded,
          tone: TrainingTone.danger,
          value: stats.overdue,
          label: 'Overdue',
        ),
        TrainingStatTile(
          key: const ValueKey('training-course-kpi-certificates'),
          icon: Icons.workspace_premium_outlined,
          tone: TrainingTone.purple,
          value: stats.certificatesIssued,
          label: 'Certificates Issued',
        ),
      ],
    );
  }

  Widget _tabs(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (id, label) in TrainingLabels.tabs)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Material(
                color: _c.tab.value == id ? AppColors.secondaryTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: ValueKey('training-tab-$id'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _c.tab.value = id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(
                      label,
                      style: handoverText(
                        context,
                        12.5,
                        weight: FontWeight.w600,
                        color: _c.tab.value == id ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabBody(TrainingCourseView view) {
    return switch (_c.tab.value) {
      'content' => TrainingContentTab(
          view: view,
          canWrite: _c.canManage,
          onEdit: () => _edit(view),
        ),
      'quiz' => TrainingQuizTab(controller: _c),
      'assignments' => TrainingAssignmentsTab(controller: _c),
      'sittings' => TrainingSittingsTab(controller: _c),
      'completions' => TrainingCompletionsTab(view: view),
      'certificates' => TrainingCertificatesTab(controller: _c),
      'history' => TrainingHistoryTab(view: view, loading: _c.auditLoading.value),
      _ => TrainingOverviewTab(view: view),
    };
  }
}
