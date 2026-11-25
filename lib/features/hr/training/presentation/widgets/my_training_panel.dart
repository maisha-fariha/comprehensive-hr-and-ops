import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// One assigned course on web My Training.
class MyTrainingCourse {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String? category;
  final String status;
  final bool mandatory;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final int? passingScore;
  final int? validityMonths;
  final bool certificateRequired;

  const MyTrainingCourse({
    required this.id,
    required this.courseId,
    required this.title,
    this.description = '',
    this.category,
    this.status = '',
    this.mandatory = false,
    this.dueAt,
    this.completedAt,
    this.passingScore,
    this.validityMonths,
    this.certificateRequired = false,
  });

  bool get isCompleted => status == 'completed';
}

class MyTrainingCredential {
  final String courseName;
  final String number;
  final String issued;
  final String expires;
  final String statusLabel;
  final Color statusColor;
  final String fileUrl;

  const MyTrainingCredential({
    required this.courseName,
    this.number = '—',
    this.issued = '—',
    this.expires = '—',
    this.statusLabel = 'Valid',
    this.statusColor = AppColors.successGreen,
    this.fileUrl = '',
  });
}

class MyTrainingCounts {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  const MyTrainingCounts({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });
}

/// Web counts a course completed only when `status === "completed"`.
/// A due date counts as overdue when its UTC calendar day is before today.
int? trainingDueDayOffset(DateTime? due) {
  if (due == null) return null;
  final utc = due.toUtc();
  final dueDay = DateTime.utc(utc.year, utc.month, utc.day);
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  return dueDay.difference(today).inDays;
}

bool trainingAssignmentOverdue(MyTrainingCourse course) {
  if (course.isCompleted) return false;
  final offset = trainingDueDayOffset(course.dueAt);
  return offset != null && offset < 0;
}

MyTrainingCounts myTrainingCounts(List<MyTrainingCourse> courses) {
  var completed = 0;
  var overdue = 0;
  var pending = 0;
  for (final course in courses) {
    if (course.isCompleted) {
      completed++;
    } else if (trainingAssignmentOverdue(course)) {
      overdue++;
    } else {
      pending++;
    }
  }
  return MyTrainingCounts(
    total: courses.length,
    completed: completed,
    pending: pending,
    overdue: overdue,
  );
}

String trainingDayLabel(DateTime? value) {
  if (value == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final utc = value.toUtc();
  return '${utc.day} ${months[utc.month - 1]} ${utc.year}';
}

/// My Training and Course Library, the two views on web `/dashboard/training`.
class TrainingModeSwitch extends StatelessWidget {
  final bool library;
  final ValueChanged<bool> onChanged;

  const TrainingModeSwitch({
    super.key,
    required this.library,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _mode(
            key: const ValueKey('training-mode-mine'),
            label: 'My Training',
            icon: Icons.school_outlined,
            selected: !library,
            onTap: () => onChanged(false),
          ),
          _mode(
            key: const ValueKey('training-mode-library'),
            label: 'Course Library',
            icon: Icons.menu_book_outlined,
            selected: library,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _mode({
    required Key key,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.secondaryTeal : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyTrainingPanel extends StatefulWidget {
  final List<MyTrainingCourse> courses;
  final List<MyTrainingCredential> certificates;
  final ValueChanged<MyTrainingCourse> onOpen;
  final ValueChanged<MyTrainingCourse> onQuiz;
  final void Function(String url, String name)? onDownload;

  const MyTrainingPanel({
    super.key,
    required this.courses,
    required this.certificates,
    required this.onOpen,
    required this.onQuiz,
    this.onDownload,
  });

  @override
  State<MyTrainingPanel> createState() => _MyTrainingPanelState();
}

class _MyTrainingPanelState extends State<MyTrainingPanel> {
  String _filter = 'all';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = myTrainingCounts(widget.courses);
    final query = _search.text.trim().toLowerCase();
    final visible = [
      for (final course in widget.courses)
        if (_matches(course, query)) course,
    ];
    final filtering = query.isNotEmpty || _filter != 'all';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stats(counts, widget.certificates.length),
        const SizedBox(height: 14),
        _filters(counts),
        const SizedBox(height: 10),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontFamily: 'Manrope', fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          _empty(filtering)
        else
          for (final course in visible) ...[
            _CourseCard(
              course: course,
              onOpen: () => widget.onOpen(course),
              onQuiz: () => widget.onQuiz(course),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 8),
        _Certificates(
          certificates: widget.certificates,
          onDownload: widget.onDownload,
        ),
      ],
    );
  }

  bool _matches(MyTrainingCourse course, String query) {
    final overdue = trainingAssignmentOverdue(course);
    if (_filter == 'completed' && !course.isCompleted) return false;
    if (_filter == 'pending' && (course.isCompleted || overdue)) return false;
    if (_filter == 'overdue' && (course.isCompleted || !overdue)) return false;
    if (query.isEmpty) return true;
    final title = course.title.toLowerCase();
    final category = (course.category ?? '').toLowerCase();
    return title.contains(query) || category.contains(query);
  }

  Widget _stats(MyTrainingCounts counts, int certificates) {
    final tiles = [
      _Stat(
        label: 'Assigned',
        value: '${counts.total}',
        hint: 'Total courses',
        color: AppColors.textHeading,
      ),
      _Stat(
        label: 'Completed',
        value: '${counts.completed}',
        hint: 'Passed & certified',
        color: AppColors.successGreen,
      ),
      _Stat(
        label: 'In Progress',
        value: '${counts.pending}',
        hint: 'Underway',
        color: const Color(0xFFD97706),
      ),
      _Stat(
        label: 'Overdue',
        value: '${counts.overdue}',
        hint: 'Past deadline',
        color: AppColors.criticalRed,
      ),
      _Stat(
        label: 'Certificates',
        value: '$certificates',
        hint: 'Active credentials',
        color: const Color(0xFF0891B2),
      ),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 10),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 10),
            Expanded(child: tiles[3]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: tiles[4]),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _filters(MyTrainingCounts counts) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip('all', 'All Courses (${counts.total})', AppColors.secondaryTeal),
        _chip('pending', 'To Do (${counts.pending})', AppColors.secondaryTeal),
        _chip('overdue', 'Overdue (${counts.overdue})', AppColors.criticalRed),
        _chip('completed', 'Completed (${counts.completed})', AppColors.secondaryTeal),
      ],
    );
  }

  Widget _chip(String id, String label, Color active) {
    final selected = _filter == id;
    return Material(
      color: selected ? active : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('training-filter-$id'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _filter = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? active : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(bool filtering) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, color: AppColors.secondaryTeal, size: 28),
          const SizedBox(height: 8),
          Text(
            filtering ? 'No matching courses found' : 'No training assigned',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            filtering
                ? 'Try clearing filters or search terms to see your courses.'
                : 'You are currently up to date on all mandatory training modules.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              letterSpacing: 0.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
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

class _CourseCard extends StatelessWidget {
  final MyTrainingCourse course;
  final VoidCallback onOpen;
  final VoidCallback onQuiz;

  const _CourseCard({
    required this.course,
    required this.onOpen,
    required this.onQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final completed = course.isCompleted;
    final overdue = trainingAssignmentOverdue(course);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? AppColors.successGreen.withValues(alpha: 0.35)
              : overdue
                  ? AppColors.criticalRed.withValues(alpha: 0.35)
                  : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if ((course.category ?? '').isNotEmpty)
                      _pill(course.category!, const Color(0xFF0891B2)),
                    if (course.mandatory) _pill('Mandatory', AppColors.criticalRed),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _duePill(course)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.title.isEmpty ? 'Course Details' : course.title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textHeading,
            ),
          ),
          if (course.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              course.description.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                course.passingScore == null
                    ? 'Self-study / practical'
                    : 'Pass mark: ${course.passingScore}%',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              if (course.validityMonths != null)
                Text(
                  'Valid: ${course.validityMonths}m',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (completed)
                OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text('Review Material'),
                )
              else ...[
                FilledButton.icon(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondaryTeal,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text('Study Course'),
                ),
                if (course.passingScore != null)
                  OutlinedButton(
                    onPressed: onQuiz,
                    child: const Text('Take Quiz'),
                  ),
                if (course.certificateRequired)
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('Upload Card'),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  Widget _duePill(MyTrainingCourse course) {
    final String label;
    final Color color;
    if (course.isCompleted) {
      final when = course.completedAt == null ? '' : ' ${trainingDayLabel(course.completedAt)}';
      label = 'Completed$when';
      color = AppColors.successGreen;
    } else {
      final offset = trainingDueDayOffset(course.dueAt);
      if (offset == null) {
        label = 'No deadline';
        color = AppColors.textMuted;
      } else if (offset < 0) {
        label = 'Overdue by ${offset.abs()}d';
        color = AppColors.criticalRed;
      } else if (offset == 0) {
        label = 'Due today';
        color = const Color(0xFFD97706);
      } else if (offset <= 7) {
        label = 'Due in ${offset}d';
        color = const Color(0xFFD97706);
      } else {
        label = 'Due ${trainingDayLabel(course.dueAt)}';
        color = AppColors.secondaryTeal;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}

class _Certificates extends StatelessWidget {
  final List<MyTrainingCredential> certificates;
  final void Function(String url, String name)? onDownload;

  const _Certificates({required this.certificates, this.onDownload});

  @override
  Widget build(BuildContext context) {
    final count = certificates.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'My Certificates',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'certificate' : 'certificates'} on record',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (certificates.isEmpty)
            const Text(
              'No certificates earned yet. Complete required courses with a passing score to earn verified certificates.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            )
          else
            for (final certificate in certificates) ...[
              _CredentialCard(certificate: certificate, onDownload: onDownload),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  final MyTrainingCredential certificate;
  final void Function(String url, String name)? onDownload;

  const _CredentialCard({required this.certificate, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 6),
          Text(
            'Certificate no.  ${certificate.number}',
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 12.5, color: AppColors.textMuted),
          ),
          Text(
            'Issued  ${certificate.issued}',
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 12.5, color: AppColors.textMuted),
          ),
          Text(
            'Expires  ${certificate.expires}',
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                certificate.statusLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: certificate.statusColor,
                ),
              ),
              const Spacer(),
              if (certificate.fileUrl.trim().isNotEmpty && onDownload != null)
                TextButton(
                  onPressed: () => onDownload!(
                    certificate.fileUrl,
                    '${certificate.courseName}.pdf',
                  ),
                  child: const Text('Download'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
