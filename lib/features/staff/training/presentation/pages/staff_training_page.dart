import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../hr/training/presentation/widgets/training_course_widgets.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../domain/entities/staff_training.dart';
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
                        onTakeQuiz: (course) => Get.to(
                          () => StaffTrainingQuizPage(
                            courseId: course.id,
                            courseTitle: course.title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _MyCertificatesSection(
                        certificates: _controller.certificates.toList(),
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

class _MyCertificatesSection extends StatelessWidget {
  final List<StaffTrainingCertificate> certificates;

  const _MyCertificatesSection({required this.certificates});

  @override
  Widget build(BuildContext context) {
    final count = certificates.length;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My Certificates',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'certificate' : 'certificates'} on record.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (certificates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No certificates on record.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final certificate in certificates) ...[
              _CertificateCard(certificate: certificate),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final StaffTrainingCertificate certificate;

  const _CertificateCard({required this.certificate});

  @override
  Widget build(BuildContext context) {
    final status = certificate.statusLabel;
    final expiring = status.toLowerCase().contains('expir');
    final expired = status.toLowerCase().contains('expired');
    final statusColor = expired
        ? AppColors.criticalRed
        : expiring
            ? const Color(0xFFB45309)
            : AppColors.successGreen;
    final number = certificate.certificateNumber.trim().isEmpty
        ? '—'
        : certificate.certificateNumber.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            certificate.courseName,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          _line('Certificate no.', number),
          _line('Issued', certificate.issuedLabel),
          _line('Expires', certificate.expiresLabel),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              if (certificate.fileUrl.trim().isNotEmpty)
                TextButton(
                  onPressed: () => openTrainingMaterial(
                    certificate.fileUrl,
                    fileName: '${certificate.courseName}.pdf',
                  ),
                  child: const Text('Download'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.5,
          color: AppColors.textSecondary,
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
