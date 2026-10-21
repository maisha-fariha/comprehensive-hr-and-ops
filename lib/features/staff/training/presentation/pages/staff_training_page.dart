import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/training/presentation/widgets/my_training_panel.dart';
import '../../../../hr/training/presentation/widgets/training_course_widgets.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/staff_training_controller.dart';
import '../widgets/staff_training_course_cards.dart';
import '../widgets/staff_training_courses_table.dart';
import '../widgets/staff_training_metrics_strip.dart';
import '../../../extras/presentation/pages/staff_training_quiz_page.dart';
import 'staff_training_course_page.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// Staff Training — web `/dashboard/training` parity.
class StaffTrainingPage extends StatefulWidget {
  const StaffTrainingPage({super.key});

  @override
  State<StaffTrainingPage> createState() => _StaffTrainingPageState();
}

class _StaffTrainingPageState extends State<StaffTrainingPage> {
  late final StaffTrainingController _controller;
  bool? _libraryPick;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<StaffTrainingController>();
    } catch (_) {
      _controller = Get.put(
        GetIt.instance<StaffTrainingController>(),
        permanent: true,
      );
    }
  }

  void _openCourse(String courseId, {String? title}) {
    Get.to(
      () => StaffTrainingCoursePage(
        courseId: courseId,
        courseTitle: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('staff-training-page'),
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Get.offAll(() => StaffShell(initialIndex: i)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: Obx(() {
                final loading = _controller.isLoading.value;
                final summary = _controller.summary.value;
                final courses = _controller.courses.toList();
                final session = Get.isRegistered<UserSession>()
                    ? Get.find<UserSession>()
                    : null;
                final library = _libraryPick ?? (session?.can('training:manage') ?? false);

                if (loading && courses.isEmpty && summary.assignments == 0) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  );
                }

                return AppRefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.reload,
                  child: ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      TrainingModeSwitch(
                        library: library,
                        onChanged: (value) => setState(() => _libraryPick = value),
                      ),
                      if (_controller.errorMessage.value.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _controller.errorMessage.value,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.criticalRed,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (library) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: _controller.toggleArchived,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _controller.includeArchived.value
                                  ? AppColors.primaryNavy
                                  : AppColors.surfaceWhite,
                              foregroundColor: _controller.includeArchived.value
                                  ? Colors.white
                                  : AppColors.textHeading,
                            ),
                            child: Text(
                              _controller.includeArchived.value
                                  ? 'Archived shown'
                                  : 'Show archived',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        StaffTrainingMetricsStrip(summary: summary),
                        const SizedBox(height: 20),
                        StaffTrainingCourseCards(
                          courses: courses,
                          onView: (course) => _openCourse(
                            course.id,
                            title: course.title,
                          ),
                          onTakeQuiz: (course) => Get.to(
                            () => StaffTrainingQuizPage(
                              courseId: course.id,
                              courseTitle: course.title,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StaffTrainingCoursesTable(
                          courses: courses,
                          totalCount: _controller.total.value,
                          page: _controller.page.value,
                          totalPages: _controller.totalPages.value,
                          onPageChanged: _controller.goToPage,
                          onOpen: (course) => _openCourse(
                            course.id,
                            title: course.title,
                          ),
                        ),
                      ] else
                        MyTrainingPanel(
                          courses: [
                            for (final item in _controller.mine)
                              MyTrainingCourse(
                                id: item.id,
                                courseId: item.courseId,
                                title: item.courseTitle ?? '',
                                description: item.courseDescription,
                                category: item.courseCategory,
                                status: item.status,
                                mandatory: item.mandatory,
                                dueAt: item.dueAt,
                                completedAt: item.completedAt,
                                passingScore: item.passingScore,
                                validityMonths: item.validityMonths,
                                certificateRequired: item.certificateRequired,
                              ),
                          ],
                          certificates: [
                            for (final item in _controller.certificates)
                              MyTrainingCredential(
                                courseName: item.courseName,
                                number: item.certificateNumber.trim().isEmpty
                                    ? '—'
                                    : item.certificateNumber.trim(),
                                issued: item.issuedLabel,
                                expires: item.expiresLabel,
                                statusLabel: item.statusLabel,
                                statusColor: _certificateColor(item.statusLabel),
                                fileUrl: item.fileUrl,
                              ),
                          ],
                          onOpen: (course) => _openCourse(
                            course.courseId,
                            title: course.title,
                          ),
                          onQuiz: (course) => Get.to(
                            () => StaffTrainingQuizPage(
                              courseId: course.courseId,
                              courseTitle: course.title,
                            ),
                          ),
                          onDownload: (url, name) =>
                              openTrainingMaterial(url, fileName: name),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

Color _certificateColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('expired')) return AppColors.criticalRed;
  if (lower.contains('expir')) return const Color(0xFFB45309);
  return AppColors.successGreen;
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textHeading,
            ),
            const Expanded(
              child: Text(
                'Training',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
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

