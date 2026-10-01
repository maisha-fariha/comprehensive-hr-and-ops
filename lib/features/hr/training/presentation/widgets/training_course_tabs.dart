import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/training_course_view.dart';
import '../training_labels.dart';
import 'training_common.dart';
import 'training_course_widgets.dart';

class TrainingOverviewTab extends StatelessWidget {
  final TrainingCourseView view;

  const TrainingOverviewTab({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final course = view.course;
    Widget item(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: handoverText(context, 12, weight: FontWeight.w600, color: const Color(0xFF94A3B8))
                    .copyWith(letterSpacing: 0.4),
              ),
              const SizedBox(height: 2),
              Text(value, style: handoverText(context, 13.5)),
            ],
          ),
        );
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this course', style: handoverText(context, 15, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            view.description.isEmpty ? 'No description.' : view.description,
            style: handoverText(context, 13.5, color: AppColors.textMuted),
          ),
          item('Category', view.category),
          item('Type', view.type),
          item('Pass mark', course.passingScore != null ? '${course.passingScore}%' : 'No quiz'),
          item('Attempts allowed', course.attemptsAllowed?.toString() ?? 'Unlimited'),
          item(
            'Certificate validity',
            (course.validityMonths ?? 0) > 0 ? '${course.validityMonths} months' : 'No expiry',
          ),
          item(
            'Completion',
            view.required
                ? 'Needs a certificate somebody has approved'
                : 'Marked complete directly, or by passing the quiz',
          ),
        ],
      ),
    );
  }
}

class TrainingContentTab extends StatelessWidget {
  final TrainingCourseView view;
  final bool canWrite;
  final VoidCallback onEdit;

  const TrainingContentTab({
    super.key,
    required this.view,
    required this.canWrite,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Course Content', style: handoverText(context, 15, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'The material staff work through. A course carries one \u2014 a file kept here, '
            'or a link to where it already lives.',
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          if (canWrite) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: HandoverButton(
                key: const ValueKey('training-content-material'),
                label: view.content.isEmpty ? 'Add material' : 'Change material',
                icon: Icons.add_rounded,
                onPressed: onEdit,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (view.content.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No content added to this course yet.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
            )
          else
            for (final item in view.content)
              Container(
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
                      child: Icon(
                        item.type == 'Video' ? Icons.videocam_outlined : Icons.description_outlined,
                        size: 17,
                        color: AppColors.secondaryTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            overflow: TextOverflow.ellipsis,
                            style: handoverText(context, 13, weight: FontWeight.w600),
                          ),
                          GestureDetector(
                            onTap: () => copyTrainingLink(item.url),
                            child: Text(
                              item.url,
                              overflow: TextOverflow.ellipsis,
                              style: handoverText(context, 11.5, color: AppColors.secondaryTeal),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TrainingPill(label: item.type, tone: TrainingTone.info),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

TrainingTone trainingProgressTone(String status) => switch (status) {
      'Completed' => TrainingTone.success,
      'In Progress' => TrainingTone.info,
      'Overdue' => TrainingTone.danger,
      'Failed — retake' => TrainingTone.warning,
      _ => TrainingTone.neutral,
    };

class TrainingCompletionsTab extends StatefulWidget {
  final TrainingCourseView view;

  const TrainingCompletionsTab({super.key, required this.view});

  @override
  State<TrainingCompletionsTab> createState() => _TrainingCompletionsTabState();
}

class _TrainingCompletionsTabState extends State<TrainingCompletionsTab> {
  static const _pageSizes = [10, 25, 50];
  String _staff = 'all';
  String _residence = 'all';
  String _status = 'all';
  String _certificate = 'all';
  int _page = 1;
  int _limit = 10;

  List<TrainingStaffProgress> get _filtered => widget.view.staffProgress.where((p) {
        return (_staff == 'all' || p.staffName == _staff) &&
            (_residence == 'all' || p.residence == _residence) &&
            (_status == 'all' || p.status == _status) &&
            (_certificate == 'all' ||
                (_certificate == 'issued' ? p.certificateIssued : !p.certificateIssued));
      }).toList();

  List<(String, String)> _options(String all, Iterable<String> values) =>
      [('all', all), for (final v in values.toSet()) (v, v)];

  void _clear() => setState(() {
        _staff = _residence = _status = _certificate = 'all';
        _page = 1;
      });

  Future<void> _filters() async {
    final rows = widget.view.staffProgress;
    List<(String, String, List<(String, String)>, ValueChanged<String>)> filtersNow() => [
      ('Staff', _staff, _options('All Staffs', rows.map((r) => r.staffName)), (v) => _staff = v),
      (
        'Residence',
        _residence,
        _options('All Residences', rows.map((r) => r.residence)),
        (v) => _residence = v,
      ),
      ('Status', _status, _options('All Status', rows.map((r) => r.status)), (v) => _status = v),
      ('Certificate', _certificate, TrainingLabels.certificateFilter, (v) => _certificate = v),
    ];
    await showTrainingSheet<void>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => TrainingSheetFrame(
          title: 'Filters',
          actions: [
            HandoverButton(
              label: 'Clear all',
              onPressed: () {
                _clear();
                setSheet(() {});
              },
            ),
            HandoverButton(
              key: const ValueKey('training-filters-done'),
              label: 'Done',
              filled: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
          children: [
            Text(
              'FILTER BY',
              style: handoverText(sheetContext, 11, weight: FontWeight.w600, color: AppColors.textMuted)
                  .copyWith(letterSpacing: 0.5),
            ),
            for (final (label, current, options, apply) in filtersNow()) ...[
              const SizedBox(height: 10),
              HandoverSelect(
                key: ValueKey('training-filter-$label'),
                label: '',
                value: options.firstWhere((o) => o.$1 == current, orElse: () => options.first).$2,
                placeholder: '',
                onTap: () async {
                  final picked = await pickHandoverOption(
                    sheetContext,
                    title: label,
                    options: options,
                    selected: current,
                  );
                  if (picked == null) return;
                  setState(() {
                    apply(picked);
                    _page = 1;
                  });
                  setSheet(() {});
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.view.stats;
    final rows = _filtered;
    final totalPages = rows.isEmpty ? 1 : ((rows.length + _limit - 1) ~/ _limit);
    final page = _page.clamp(1, totalPages);
    final visible = rows.skip((page - 1) * _limit).take(_limit).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HandoverPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    '${stats.completed} of ${stats.assigned} staff have completed this training',
                    style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
                  ),
                  Text(
                    '${stats.percentComplete}% complete',
                    style: handoverText(context, 13, weight: FontWeight.w700, color: AppColors.secondaryTeal),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stats.percentComplete / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.filterButtonBackground,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        HandoverPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HandoverButton(
                    key: const ValueKey('training-completions-filters'),
                    label: 'Filters',
                    icon: Icons.filter_alt_outlined,
                    compact: true,
                    onPressed: _filters,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clear,
                    child: Text(
                      'Clear filters',
                      style: handoverText(context, 13, weight: FontWeight.w500, color: AppColors.infoBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'No staff progress records found.',
                    textAlign: TextAlign.center,
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  ),
                )
              else
                for (final p in visible) ...[
                  _ProgressCard(progress: p),
                  const SizedBox(height: 10),
                ],
              if (rows.isNotEmpty)
                AttendancePagination(
                  page: page,
                  limit: _limit,
                  total: rows.length,
                  totalPages: totalPages,
                  limitOptions: _pageSizes,
                  onPage: (p) => setState(() => _page = p),
                  onLimit: (l) => setState(() {
                    _limit = l;
                    _page = 1;
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final TrainingStaffProgress progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Container(
      key: ValueKey('training-progress-${p.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.initials,
                  style: handoverText(context, 12, weight: FontWeight.w600, color: const Color(0xFF8E88B1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.staffName, style: handoverText(context, 13.5, weight: FontWeight.w600)),
                    Text(p.role, style: handoverText(context, 12, color: AppColors.infoBlue)),
                  ],
                ),
              ),
              TrainingPill(label: p.status, tone: trainingProgressTone(p.status)),
            ],
          ),
          TrainingField.text(label: 'Residence', value: p.residence),
          TrainingField.text(label: 'Quiz Score', value: p.quizScore != null ? '${p.quizScore}%' : '—'),
          TrainingField(
            label: 'Certificate',
            child: p.certificateIssued
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_outlined, size: 13, color: AppColors.activeGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Issued',
                        style: handoverText(context, 12.5, weight: FontWeight.w600, color: AppColors.activeGreen),
                      ),
                    ],
                  )
                : Text('—', style: handoverText(context, 12.5, color: AppColors.textMuted)),
          ),
          TrainingField.text(label: 'Completed', value: TrainingLabels.date(p.completedAt)),
        ],
      ),
    );
  }
}

TrainingTone trainingHistoryTone(String action) => switch (action) {
      'Published' || 'Completed' => TrainingTone.success,
      'Updated' => TrainingTone.info,
      'Reminder' => TrainingTone.warning,
      'Overdue' => TrainingTone.danger,
      _ => TrainingTone.neutral,
    };

class TrainingHistoryTab extends StatelessWidget {
  final TrainingCourseView view;
  final bool loading;

  const TrainingHistoryTab({super.key, required this.view, required this.loading});

  @override
  Widget build(BuildContext context) {
    final history = view.history;
    Widget note(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: handoverText(context, 13, color: AppColors.textMuted),
          ),
        );
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Activity History', style: handoverText(context, 15, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'Straight from the audit trail \u2014 every write to this course, with who made it.',
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          if (loading)
            note('Loading…')
          else if (history.isEmpty)
            note('Nothing has changed on this course since the audit trail began.')
          else
            for (final (i, item) in history.indexed)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < history.length - 1)
                          Expanded(child: Container(width: 1, color: AppColors.cardBorder)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(item.title, style: handoverText(context, 13, weight: FontWeight.w600)),
                                TrainingPill(label: item.action, tone: trainingHistoryTone(item.action)),
                              ],
                            ),
                            if (item.description.isNotEmpty)
                              Text(item.description,
                                  style: handoverText(context, 12, color: AppColors.textMuted)),
                            Text(
                              '${item.actor != null ? '${item.actor} \u00b7 ' : ''}'
                              '${item.timestamp == null ? '' : TrainingLabels.dateTime(item.timestamp)}',
                              style: handoverText(context, 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
