import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../domain/entities/shift_handover.dart';
import '../controllers/handovers_controller.dart';
import '../handover_labels.dart';
import 'handover_common.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

Future<void> showHandoverDetailSheet(
  BuildContext context, {
  required HandoversController controller,
  required String handoverId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HandoverDetailSheet(controller: controller, handoverId: handoverId),
  );
}

/// The web handover modal: status, shifts, summary, residents, incidents,
/// jobs, notes, "Add a note" and "I've read and taken this".
class HandoverDetailSheet extends StatefulWidget {
  final HandoversController controller;
  final String handoverId;

  const HandoverDetailSheet({
    super.key,
    required this.controller,
    required this.handoverId,
  });

  @override
  State<HandoverDetailSheet> createState() => _HandoverDetailSheetState();
}

class _HandoverDetailSheetState extends State<HandoverDetailSheet> {
  final _note = TextEditingController();
  final _takeNote = TextEditingController();
  ShiftHandover? _handover;
  String? _error;
  bool _saving = false;

  HandoversController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    _takeNote.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _c.repository.byId(widget.handoverId);
    if (!mounted) return;
    result.when(
      success: (h) => setState(() {
        _handover = h;
        _error = null;
      }),
      failure: (e) => setState(() => _error = e.message),
    );
  }

  Future<void> _act(Future<bool> Function() action) async {
    setState(() => _saving = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _note.clear();
      _takeNote.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _handover;
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
            _Header(
              title: h?.residenceName ?? 'Handover',
              subtitle: h == null
                  ? ''
                  : '${h.authorName ?? 'Unknown'}'
                      '${h.createdAt == null ? '' : ' · ${WebFormat.dateTime(h.createdAt)}'}',
            ),
            Expanded(
              child: h == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator(color: AppColors.secondaryTeal)
                          : Text(_error!, style: handoverText(context, 13.5)),
                    )
                  : ListView(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        vertical: 14,
                      ),
                      children: _body(context, h),
                    ),
            ),
            if (h != null) _footer(context, h),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, ShiftHandover h) {
    const gap = SizedBox(height: 16);
    final taken = _c.alreadyTaken(h);
    return [
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AttendancePill(
            label: HandoverLabels.status(h.status),
            tone: HandoverLabels.statusTone(h.status),
          ),
          if (h.fromShiftStartsAt != null)
            Text(
              'From ${WebFormat.short(h.fromShiftStartsAt)}',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          if (h.toShiftStartsAt != null)
            Text(
              '→ ${WebFormat.short(h.toShiftStartsAt)}',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
        ],
      ),
      gap,
      HandoverPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Summary'),
            const SizedBox(height: 4),
            Text(h.summary, style: handoverText(context, 13.5)),
          ],
        ),
      ),
      if (h.clientUpdates.isNotEmpty) ...[
        gap,
        _SectionTitle('Residents (${h.clientUpdates.length})'),
        const SizedBox(height: 8),
        for (final update in h.clientUpdates) ...[
          _ResidentCard(update: update),
          const SizedBox(height: 8),
        ],
      ],
      if (h.incidents.isNotEmpty) ...[
        gap,
        HandoverPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Incidents on this shift', color: AppColors.criticalRed),
              const SizedBox(height: 6),
              for (final incident in h.incidents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${incident.reference == null ? '' : '${incident.reference} · '}'
                    '${incident.title ?? incident.categoryName ?? 'Incident'}'
                    '${incident.severity == null ? '' : ' · ${incident.severity}'}',
                    style: handoverText(context, 13),
                  ),
                ),
            ],
          ),
        ),
      ],
      if (h.tasks.isNotEmpty) ...[
        gap,
        _SectionTitle('Outstanding jobs'),
        const SizedBox(height: 6),
        for (final task in h.tasks) _JobRow(task: task),
      ],
      if (h.comments.isNotEmpty) ...[
        gap,
        _SectionTitle('Notes'),
        const SizedBox(height: 6),
        for (final comment in h.comments)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.authorName ?? 'Someone'}'
                  '${comment.createdAt == null ? '' : ' · ${WebFormat.dateTime(comment.createdAt)}'}',
                  style: handoverText(context, 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: handoverText(context, 13)),
              ],
            ),
          ),
      ],
      if (_c.canWrite) ...[
        gap,
        HandoverTextArea(
          key: const ValueKey('handover-note-field'),
          label: 'Add a note',
          placeholder: 'A question, or a decision worth recording…',
          controller: _note,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: HandoverButton(
            key: const ValueKey('handover-add-note'),
            label: 'Add note',
            compact: true,
            onPressed: _saving || _note.text.trim().isEmpty
                ? null
                : () => _act(() => _c.addNote(h, _note.text.trim())),
          ),
        ),
      ],
      if (h.status != 'draft' && !taken) ...[
        gap,
        HandoverTextArea(
          key: const ValueKey('handover-take-note'),
          label: 'Anything to add on taking it?',
          placeholder: 'Optional — a question, a correction…',
          controller: _takeNote,
        ),
      ],
      const SizedBox(height: 8),
    ];
  }

  Widget _footer(BuildContext context, ShiftHandover h) {
    final canTake = h.status != 'draft' && !_c.alreadyTaken(h);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          HandoverButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (canTake) ...[
            const SizedBox(width: 8),
            HandoverButton(
              key: const ValueKey('handover-detail-take'),
              label: "I've read and taken this",
              filled: true,
              onPressed: _saving
                  ? null
                  : () => _act(() {
                        final note = _takeNote.text.trim();
                        return _c.take(h, note: note.isEmpty ? null : note);
                      }),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
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
                Text(title, style: handoverText(context, 17, weight: FontWeight.w700)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: handoverText(context, 12.5, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle(this.text, {this.color = AppColors.textHeading});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: handoverText(context, 12.5, weight: FontWeight.w700, color: color));
}

class _ResidentCard extends StatelessWidget {
  final HandoverClientUpdate update;

  const _ResidentCard({required this.update});

  @override
  Widget build(BuildContext context) {
    final care = update.care;
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  update.clientName ?? 'Resident',
                  style: handoverText(
                    context,
                    13.5,
                    weight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              AttendancePill(
                label: HandoverLabels.clientStatus(update.status),
                tone: HandoverLabels.clientTone(update.status),
              ),
            ],
          ),
          _KeyValues(title: 'Health', values: update.health),
          _KeyValues(title: 'Medication', values: update.medication),
          if (care != null) ...[
            const SizedBox(height: 8),
            _Caption('Care'),
            if (care.completed.isNotEmpty)
              Text(
                'Done: ${care.completed.map(HandoverLabels.careTask).join(', ')}',
                style: handoverText(context, 13),
              ),
            if (care.otherCompleted != null)
              Text('Also: ${care.otherCompleted}', style: handoverText(context, 13)),
            if (care.pending != null)
              Text(
                'Still to do: ${care.pending}',
                style: handoverText(context, 13, color: AppColors.urgentAmber),
              ),
            if (care.followUpRequired != null)
              Text(
                'Follow up: ${care.followUpRequired}',
                style: handoverText(context, 13, color: AppColors.urgentAmber),
              ),
          ],
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;

  const _Caption(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text.toUpperCase(),
          style: handoverText(
            context,
            11,
            weight: FontWeight.w600,
            color: AppColors.textMuted,
          ).copyWith(letterSpacing: 0.6),
        ),
      );
}

class _KeyValues extends StatelessWidget {
  final String title;
  final Map<String, String> values;

  const _KeyValues({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Caption(title),
          for (final entry in values.entries)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${HandoverLabels.fieldKey(entry.key)}: ',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  TextSpan(text: entry.value),
                ],
              ),
              style: handoverText(context, 13),
            ),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final HandoverTask task;

  const _JobRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final who = task.assigneeFirstNames.join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          if (task.priority != null) ...[
            AttendancePill(
              label: HandoverLabels.taskPriority(task.priority!),
              tone: HandoverLabels.taskPriorityTone(task.priority!),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              task.title,
              style: handoverText(
                context,
                13,
                color: task.done ? AppColors.textMuted : AppColors.textHeading,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            who.isEmpty ? 'nobody yet' : who,
            style: handoverText(context, 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
