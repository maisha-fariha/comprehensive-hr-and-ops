import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/entities/training_course_view.dart';
import 'training_common.dart';

Future<void> copyTrainingLink(String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  AppSnackbar.show('Link copied', url);
}

TrainingTone trainingCardBadgeTone(String badge) => switch (badge) {
      'Completed' => TrainingTone.success,
      'Overdue' => TrainingTone.danger,
      _ => TrainingTone.warning,
    };

/// The web "Training Courses" strip of course cards.
class TrainingCourseCards extends StatelessWidget {
  final List<TrainingCourseView> courses;
  final ValueChanged<TrainingCourseView> onView;

  const TrainingCourseCards({super.key, required this.courses, required this.onView});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.quickActionCreateShiftBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.school_outlined, size: 16, color: AppColors.secondaryTeal),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Training Courses',
                  style: handoverText(context, 16, weight: FontWeight.w600, color: AppColors.primaryNavy),
                ),
              ),
              const SizedBox(width: 10),
              TrainingPill(label: '${courses.length} courses', tone: TrainingTone.info),
            ],
          ),
          if (courses.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, 196),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => _CourseCard(
                  course: courses[i],
                  onView: () => onView(courses[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final TrainingCourseView course;
  final VoidCallback onView;

  const _CourseCard({required this.course, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveHelper.getResponsiveWidth(context, 240),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.quickActionCreateShiftBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_outlined, size: 16, color: AppColors.secondaryTeal),
              ),
              TrainingPill(label: course.cardBadge, tone: trainingCardBadgeTone(course.cardBadge)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: handoverText(context, 13.5, weight: FontWeight.w700, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 4),
          Text(
            course.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: HandoverButton(
              key: ValueKey('training-card-view-${course.id}'),
              label: 'View',
              onPressed: onView,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the web course table, laid out as a card.
class TrainingCourseRow extends StatelessWidget {
  final TrainingCourse course;
  final bool canManage;
  final bool busy;
  final VoidCallback onOpen;
  final ValueChanged<bool> onArchive;
  final VoidCallback onDelete;

  const TrainingCourseRow({
    super.key,
    required this.course,
    required this.canManage,
    required this.busy,
    required this.onOpen,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final url = course.materialUrl;
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onOpen,
                      child: Text(
                        course.title,
                        style: handoverText(context, 14, weight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                    ),
                    Text(
                      course.category ?? 'Uncategorised',
                      style: handoverText(context, 12, color: AppColors.infoBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TrainingPill(
                label: course.isArchived ? 'Archived' : 'Active',
                tone: course.isArchived ? TrainingTone.neutral : TrainingTone.success,
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TrainingField(
            label: 'Material',
            child: url == null
                ? Text('None', style: handoverText(context, 13, color: AppColors.infoBlue))
                : GestureDetector(
                    onTap: () => copyTrainingLink(url),
                    child: Text(
                      course.materialType ?? 'Material',
                      style: handoverText(context, 13, color: AppColors.secondaryTeal),
                    ),
                  ),
          ),
          TrainingField.text(
            label: 'Quiz',
            value: course.passingScore == null
                ? 'No quiz'
                : 'Pass at ${course.passingScore}%'
                    '${(course.attemptsAllowed ?? 0) > 0 ? ' \u00b7 ${course.attemptsAllowed} attempts' : ''}',
            color: course.passingScore == null ? AppColors.infoBlue : AppColors.textHeading,
          ),
          TrainingField.text(
            label: 'Certificate',
            value: (course.validityMonths ?? 0) > 0
                ? 'Valid ${course.validityMonths} months'
                : 'No expiry',
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              HandoverButton(
                key: ValueKey('training-open-${course.id}'),
                label: 'Open',
                compact: true,
                onPressed: onOpen,
              ),
              if (canManage)
                course.isArchived
                    ? HandoverButton(
                        key: ValueKey('training-restore-${course.id}'),
                        label: 'Restore',
                        filled: true,
                        compact: true,
                        onPressed: busy ? null : () => onArchive(false),
                      )
                    : HandoverButton(
                        key: ValueKey('training-archive-${course.id}'),
                        label: 'Archive',
                        compact: true,
                        foreground: AppColors.criticalRed,
                        onPressed: busy ? null : () => onArchive(true),
                      ),
              if (canManage)
                Semantics(
                  label: 'Delete course',
                  button: true,
                  excludeSemantics: true,
                  child: HandoverButton(
                    key: ValueKey('training-delete-${course.id}'),
                    label: '',
                    icon: Icons.delete_outline_rounded,
                    compact: true,
                    foreground: AppColors.criticalRed,
                    onPressed: busy ? null : onDelete,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
