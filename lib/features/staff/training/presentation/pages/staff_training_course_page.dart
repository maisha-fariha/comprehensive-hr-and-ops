import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../hr/training/presentation/widgets/training_course_widgets.dart';
import '../../../extras/presentation/pages/staff_training_quiz_page.dart';
import '../../domain/entities/staff_training.dart';
import '../controllers/staff_training_course_controller.dart';
import '../widgets/staff_training_metrics_strip.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// Course detail — web `/dashboard/training/[id]` parity.
class StaffTrainingCoursePage extends StatefulWidget {
  final String courseId;
  final String? courseTitle;

  const StaffTrainingCoursePage({
    super.key,
    required this.courseId,
    this.courseTitle,
  });

  @override
  State<StaffTrainingCoursePage> createState() =>
      _StaffTrainingCoursePageState();
}

class _StaffTrainingCoursePageState extends State<StaffTrainingCoursePage> {
  late final StaffTrainingCourseController _controller;
  static const _tabs = [
    'Overview',
    'Content',
    'Quiz',
    'Assignments',
    'Completions',
    'Certificates',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      GetIt.instance<StaffTrainingCourseController>(),
      tag: widget.courseId,
    );
    _controller.load(widget.courseId);
  }

  @override
  void dispose() {
    if (Get.isRegistered<StaffTrainingCourseController>(
      tag: widget.courseId,
    )) {
      Get.delete<StaffTrainingCourseController>(tag: widget.courseId);
    }
    super.dispose();
  }

  Future<void> _openMaterial(String url, {String? fileName}) =>
      openTrainingMaterial(url, fileName: fileName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('staff-training-course-${widget.courseId}'),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          final loading = _controller.isLoading.value;
          final course = _controller.course.value;
          final error = _controller.errorMessage.value;

          if (loading && course == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }

          if (course == null) {
            return Column(
              children: [
                _TopBar(
                  onBack: () => Navigator.maybePop(context),
                  title: widget.courseTitle ?? 'Course',
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        error.isNotEmpty ? error : 'Course not found.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final tab = _controller.selectedTab.value;

          return Column(
            children: [
              _TopBar(
                onBack: () => Navigator.maybePop(context),
                title: 'Back to Training',
              ),
              Expanded(
                child: AppRefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.reload,
                  child: ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            24,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            course.shortCode,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12,
                              ),
                              color: AppColors.textMuted,
                            ),
                          ),
                          _Pill(
                            label: course.statusLabel,
                            color: course.isActive && !course.isArchived
                                ? AppColors.activeGreen
                                : AppColors.textMuted,
                            bg: course.isActive && !course.isArchived
                                ? AppColors.activeBackground
                                : AppColors.scaffoldBackground,
                          ),
                          if (course.category != null &&
                              course.category!.trim().isNotEmpty)
                            _Pill(
                              label: course.category!.trim(),
                              color: AppColors.secondaryTeal,
                              bg: AppColors.quickActionCreateShiftBg,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Created on ${course.createdLabel}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12,
                          ),
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StaffTrainingCourseMetricsStrip(
                        metrics: _controller.metrics.value,
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < _tabs.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              _TabChip(
                                label: _tabs[i],
                                selected: tab == i,
                                onTap: () => _controller.selectTab(i),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TabBody(
                        tab: tab,
                        course: course,
                        certificates: _controller.certificates.toList(),
                        completions: _controller.completions,
                        onOpenQuiz: () => Get.to(
                          () => StaffTrainingQuizPage(
                            courseId: course.id,
                            courseTitle: course.title,
                          ),
                        ),
                        onCopyMaterial: (url, name) =>
                            _openMaterial(url, fileName: name),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String title;

  const _TopBar({required this.onBack, required this.title});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textHeading,
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryNavy : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryNavy : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: selected ? Colors.white : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  final int tab;
  final StaffTrainingCourse course;
  final List<StaffTrainingCertificate> certificates;
  final List<StaffTrainingAssignment> completions;
  final VoidCallback onOpenQuiz;
  final void Function(String url, String name)? onCopyMaterial;

  const _TabBody({
    required this.tab,
    required this.course,
    required this.certificates,
    required this.completions,
    required this.onOpenQuiz,
    required this.onCopyMaterial,
  });

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 1:
        return _ContentTab(
          course: course,
          onCopyMaterial: onCopyMaterial,
          onOpenQuiz: onOpenQuiz,
        );
      case 2:
        return _QuizTab(course: course, onOpenQuiz: onOpenQuiz);
      case 3:
        return _AssignmentsTab(
          title: 'Assignments',
          assignments: course.assignments,
          emptyLabel: 'No assignments for this course.',
        );
      case 4:
        return _AssignmentsTab(
          title: 'Completions',
          assignments: completions,
          emptyLabel: 'No completions yet.',
        );
      case 5:
        return _CertificatesTab(certificates: certificates);
      case 0:
      default:
        return _OverviewTab(course: course, onOpenQuiz: onOpenQuiz);
    }
  }
}

class _OverviewTab extends StatelessWidget {
  final StaffTrainingCourse course;
  final VoidCallback onOpenQuiz;

  const _OverviewTab({required this.course, required this.onOpenQuiz});

  @override
  Widget build(BuildContext context) {
    final description = course.description.trim();
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description.isEmpty ? 'No description provided.' : description,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _TakeQuizCard(onOpenQuiz: onOpenQuiz),
          const SizedBox(height: 16),
          _InfoGrid(
            rows: [
              ('Category', course.category?.trim().isNotEmpty == true
                  ? course.category!.trim()
                  : '—'),
              ('Material type', course.materialLabel),
              (
                'Pass mark',
                course.passingScore == null
                    ? '—'
                    : '${course.passingScore}%',
              ),
              (
                'Attempts allowed',
                course.attemptsAllowed == null
                    ? '—'
                    : '${course.attemptsAllowed}',
              ),
              (
                'Certificate validity',
                course.validityMonths == null
                    ? (course.certificateRequired ? 'Required' : '—')
                    : '${course.validityMonths} month${course.validityMonths == 1 ? '' : 's'}',
              ),
              (
                'Completion rule',
                course.certificateRequired
                    ? 'Certificate required after pass'
                    : 'Complete assignment / quiz',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentTab extends StatelessWidget {
  final StaffTrainingCourse course;
  final void Function(String url, String name)? onCopyMaterial;
  final VoidCallback onOpenQuiz;

  const _ContentTab({
    required this.course,
    required this.onCopyMaterial,
    required this.onOpenQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final files = course.materials;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Content',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The material staff work through. A course carries one — a file kept here, or a link to where it already lives.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (files.isEmpty)
            const Text(
              'No training material linked to this course.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            )
          else
            for (final file in files) ...[
              _MaterialRow(
                title: file.name,
                url: file.fileUrl,
                typeLabel: file.badge,
                onOpen: onCopyMaterial == null
                    ? null
                    : () => onCopyMaterial!(file.fileUrl, file.name),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          _TakeQuizCard(onOpenQuiz: onOpenQuiz),
        ],
      ),
    );
  }
}

class _TakeQuizCard extends StatelessWidget {
  final VoidCallback onOpenQuiz;

  const _TakeQuizCard({required this.onOpenQuiz});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ready to take the examination?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Test your understanding of this material to complete the course and earn your certificate.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('training-take-quiz'),
              onPressed: onOpenQuiz,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Take Quiz Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final String title;
  final String url;
  final String typeLabel;
  final VoidCallback? onOpen;

  const _MaterialRow({
    required this.title,
    required this.url,
    required this.typeLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.quickActionCreateShiftBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 18,
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textHeading,
                  ),
                ),
                GestureDetector(
                  onTap: onOpen,
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.quickActionCreateShiftBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              typeLabel,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Open',
            onPressed: onOpen,
            icon: const Icon(Icons.download_rounded, color: AppColors.secondaryTeal),
          ),
        ],
      ),
    );
  }
}

class _QuizTab extends StatelessWidget {
  final StaffTrainingCourse course;
  final VoidCallback onOpenQuiz;

  const _QuizTab({required this.course, required this.onOpenQuiz});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          _InfoGrid(
            rows: [
              (
                'Pass mark',
                course.passingScore == null
                    ? '—'
                    : '${course.passingScore}%',
              ),
              (
                'Attempts allowed',
                course.attemptsAllowed == null
                    ? '—'
                    : '${course.attemptsAllowed}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenQuiz,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
            ),
            icon: const Icon(Icons.quiz_outlined, size: 18),
            label: const Text('Open quiz'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  final String title;
  final List<StaffTrainingAssignment> assignments;
  final String emptyLabel;

  const _AssignmentsTab({
    required this.title,
    required this.assignments,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          if (assignments.isEmpty)
            Text(
              emptyLabel,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            )
          else
            for (final a in assignments) ...[
              _AssignmentCard(assignment: a),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _CertificatesTab extends StatelessWidget {
  final List<StaffTrainingCertificate> certificates;

  const _CertificatesTab({required this.certificates});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Certificates',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          if (certificates.isEmpty)
            const Text(
              'No certificates issued for this course yet.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            )
          else
            for (final c in certificates) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.staffName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (c.status.isNotEmpty) c.status,
                        'Issued ${c.issuedLabel}',
                        'Expires ${c.expiresLabel}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final StaffTrainingAssignment assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.staffName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (assignment.mandatory)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'Mandatory',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.urgentAmber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              assignment.statusLabel,
              if (assignment.dueLabel.isNotEmpty) 'Due ${assignment.dueLabel}',
              if (assignment.completedLabel.isNotEmpty)
                'Completed ${assignment.completedLabel}',
            ].join(' · '),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String)> rows;

  const _InfoGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _InfoRow(label: rows[i].$1, value: rows[i].$2),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textHeading,
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: color,
        ),
      ),
    );
  }
}
