import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/staff_training_controller.dart';
import '../widgets/staff_training_course_cards.dart';
import '../widgets/staff_training_courses_table.dart';
import '../widgets/staff_training_metrics_strip.dart';
import 'staff_training_course_page.dart';

/// Staff Training — web `/dashboard/training` parity.
class StaffTrainingPage extends StatefulWidget {
  const StaffTrainingPage({super.key});

  @override
  State<StaffTrainingPage> createState() => _StaffTrainingPageState();
}

class _StaffTrainingPageState extends State<StaffTrainingPage> {
  late final StaffTrainingController _controller;

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
            Obx(
              () => _Header(
                showArchived: _controller.includeArchived.value,
                onBack: () => Navigator.maybePop(context),
                onToggleArchived: _controller.toggleArchived,
              ),
            ),
            Expanded(
              child: Obx(() {
                final loading = _controller.isLoading.value;
                final summary = _controller.summary.value;
                final courses = _controller.courses.toList();

                if (loading && courses.isEmpty && summary.assignments == 0) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  );
                }

                return RefreshIndicator(
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
                        'Training',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            26,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track assignments, courses, quizzes and certificates.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
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
                      StaffTrainingMetricsStrip(summary: summary),
                      const SizedBox(height: 20),
                      StaffTrainingCourseCards(
                        courses: courses,
                        onView: (course) => _openCourse(
                          course.id,
                          title: course.title,
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

class _Header extends StatelessWidget {
  final bool showArchived;
  final VoidCallback onBack;
  final VoidCallback onToggleArchived;

  const _Header({
    required this.showArchived,
    required this.onBack,
    required this.onToggleArchived,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
        child: Column(
          children: [
            Row(
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
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton(
                  onPressed: onToggleArchived,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: showArchived
                        ? AppColors.primaryNavy
                        : Colors.transparent,
                    foregroundColor: showArchived
                        ? Colors.white
                        : AppColors.textHeading,
                  ),
                  child: Text(
                    showArchived ? 'Archived shown' : 'Show archived',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
