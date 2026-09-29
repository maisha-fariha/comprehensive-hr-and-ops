import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_training.dart';

class StaffTrainingCourseCards extends StatelessWidget {
  final List<StaffTrainingCourse> courses;
  final ValueChanged<StaffTrainingCourse> onView;

  const StaffTrainingCourseCards({
    super.key,
    required this.courses,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Training Courses',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Browse available courses and open a course for details.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        for (final course in courses.take(6)) ...[
          _CourseCard(course: course, onView: () => onView(course)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final StaffTrainingCourse course;
  final VoidCallback onView;

  const _CourseCard({required this.course, required this.onView});

  @override
  Widget build(BuildContext context) {
    final active = course.isActive && !course.isArchived;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
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
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: course.statusLabel,
                active: active,
                archived: course.isArchived,
              ),
            ],
          ),
          if (course.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              course.description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onView,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('View'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  final bool archived;

  const _StatusPill({
    required this.label,
    required this.active,
    required this.archived,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    if (archived) {
      fg = AppColors.textMuted;
      bg = AppColors.scaffoldBackground;
    } else if (active) {
      fg = AppColors.activeGreen;
      bg = AppColors.activeBackground;
    } else {
      fg = AppColors.secondaryTeal;
      bg = AppColors.quickActionCreateShiftBg;
    }

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
          color: fg,
        ),
      ),
    );
  }
}
