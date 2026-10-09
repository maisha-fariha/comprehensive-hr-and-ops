import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_activity.dart';
import '../controllers/daily_activity_controller.dart';
import '../daily_activity_labels.dart';
import 'daily_activity_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Web "Activity Details" modal; [onEdit] closes it and opens the form.
Future<void> showDailyActivityDetailSheet(
  BuildContext context, {
  required DailyActivityController controller,
  required DailyActivity activity,
  required ValueChanged<DailyActivity> onEdit,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DailyActivityDetailSheet(
      controller: controller,
      activity: activity,
      onEdit: onEdit,
    ),
  );
}

class DailyActivityDetailSheet extends StatelessWidget {
  final DailyActivityController controller;
  final DailyActivity activity;
  final ValueChanged<DailyActivity> onEdit;

  const DailyActivityDetailSheet({
    super.key,
    required this.controller,
    required this.activity,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final a = activity;
    const gap = SizedBox(height: 16);
    final client = a.clientName ?? 'Resident no longer on file';
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _Header(activity: a),
            Expanded(
              child: ListView(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  vertical: 14,
                ),
                children: [
                  HandoverPanel(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.secondaryTeal, AppColors.primaryNavy],
                            ),
                          ),
                          child: Text(
                            DailyActivityLabels.initials(client),
                            style: handoverText(
                              context,
                              16,
                              weight: FontWeight.w700,
                              color: AppColors.surfaceWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client,
                                style: handoverText(context, 15, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.home_outlined,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        a.clientResidence ?? '—',
                                        style: handoverText(
                                          context,
                                          12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      text: 'Care Level: ',
                                      children: [
                                        TextSpan(
                                          text: a.clientLevel == null
                                              ? '—'
                                              : DailyActivityLabels.humanise(a.clientLevel),
                                          style: handoverText(
                                            context,
                                            12,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: handoverText(context, 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap,
                  _Section(
                    title: 'Activity Information',
                    children: [
                      _FieldLabel('Activity Type'),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DailyActivityPill(
                          label: DailyActivityLabels.humanise(a.activityType),
                          tone: DailyActivityLabels.typeTone(a.activityType),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        'Recorded By',
                        [a.recordedByName, a.enteredBy].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      _FieldLabel('Description'),
                      const SizedBox(height: 4),
                      Text(a.description ?? '—', style: handoverText(context, 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _Field('Date', DailyActivityLabels.date(a))),
                          Expanded(
                            child: _Field(
                              'Time',
                              a.occurredAt == null
                                  ? 'Time not recorded'
                                  : DailyActivityLabels.time(a),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (a.notes != null) ...[
                    gap,
                    _Section(
                      title: 'Additional Notes',
                      children: [
                        Text(
                          a.notes!,
                          style: handoverText(context, 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                  if (a.attachments.isNotEmpty) ...[
                    gap,
                    _Section(
                      title: 'Attachments',
                      children: [
                        for (final (i, file) in a.attachments.indexed)
                          _AttachmentRow(
                            key: ValueKey('daily-activity-attachment-$i'),
                            file: file,
                            onOpen: () => controller.openAttachment(file),
                          ),
                      ],
                    ),
                  ],
                  if (a.timeline.isNotEmpty) ...[
                    gap,
                    _Section(
                      title: 'Activity Timeline',
                      children: [
                        for (final (i, entry) in a.timeline.indexed)
                          _TimelineRow(entry: entry, last: i == a.timeline.length - 1),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _footer(context, a),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, DailyActivity a) {
    final canWrite = controller.canWrite;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Obx(() {
        final busy = controller.busy.value;
        return Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            HandoverButton(
              key: const ValueKey('daily-activity-detail-close'),
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (canWrite && a.isPendingReview)
              HandoverButton(
                key: const ValueKey('daily-activity-mark-reviewed'),
                label: 'Mark reviewed',
                icon: Icons.done_all_rounded,
                onPressed: busy
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        if (await controller.markReviewed(a)) navigator.pop();
                      },
              ),
            if (canWrite)
              HandoverButton(
                key: const ValueKey('daily-activity-detail-edit'),
                label: 'Edit Activity',
                icon: Icons.edit_outlined,
                filled: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onEdit(a);
                },
              ),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final DailyActivity activity;

  const _Header({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Activity Details',
                      style: handoverText(context, 16, weight: FontWeight.w600),
                    ),
                    DailyActivityPill(
                      label: DailyActivityLabels.humanise(activity.status),
                      tone: DailyActivityLabels.statusTone(activity.status),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.code} · Recorded ${DailyActivityLabels.dateTime(activity)}',
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: handoverText(context, 13.5, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted)
            .copyWith(letterSpacing: 0.6),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final DailyActivityAttachment file;
  final VoidCallback onOpen;

  const _AttachmentRow({super.key, required this.file, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.description_outlined, size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: handoverText(context, 12.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
            ),
          ),
          TextButton.icon(
            onPressed: onOpen,
            style: TextButton.styleFrom(foregroundColor: AppColors.secondaryTeal),
            icon: const Icon(Icons.visibility_outlined, size: 14),
            label: Text(
              'Open',
              style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.secondaryTeal),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final DailyActivityTimelineEntry entry;
  final bool last;

  const _TimelineRow({required this.entry, required this.last});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceWhite, width: 2),
                  boxShadow: const [BoxShadow(color: AppColors.secondaryTeal, spreadRadius: 1)],
                ),
              ),
              if (!last) Expanded(child: Container(width: 1, color: AppColors.cardBorder)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DailyActivityLabels.stamp(entry.at),
                    style: handoverText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.description,
                    style: handoverText(context, 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
