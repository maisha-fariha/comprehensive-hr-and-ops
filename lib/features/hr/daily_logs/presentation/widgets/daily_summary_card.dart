import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../ai/presentation/widgets/ai_feature_sheets.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/daily_logs_repository.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

const _sourceKindLabels = {
  'dailyLog': 'care notes',
  'tasks': 'tasks',
  'medication': 'doses',
  'handoverNotes': 'handover notes',
  'incidents': 'incidents',
  'checks': 'checks',
  'activities': 'activities',
  'goals': 'goal logs',
  'appointments': 'appointments',
};

/// Web Resident Activity "Daily summary" card.
class DailySummaryCard extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String logDate;
  final bool canReview;

  const DailySummaryCard({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.logDate,
    required this.canReview,
  });

  @override
  State<DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<DailySummaryCard> {
  bool? _enabled;
  bool _loading = false;
  bool _busy = false;
  DailySummary? _summary;

  String get _firstName {
    final parts = widget.clientName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'Resident' : parts.first;
  }

  DailyLogsRepository get _repo => GetIt.instance<DailyLogsRepository>();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didUpdateWidget(covariant DailySummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId ||
        oldWidget.logDate != widget.logDate) {
      _summary = null;
      _boot();
    }
  }

  Future<void> _boot() async {
    final enabled = await aiDraftingEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
    if (enabled) await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repo.daySummary(
      clientId: widget.clientId,
      day: widget.logDate,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (summary) => setState(() => _summary = summary),
      failure: (_) => setState(() => _summary = null),
    );
  }

  Future<void> _generate() async {
    if (_busy || !widget.canReview) return;
    setState(() => _busy = true);
    final result = await _repo.generateDaySummary(
      clientId: widget.clientId,
      day: widget.logDate,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (summary) {
        if (summary == null) {
          AppSnackbar.show(
            'Nothing to summarise',
            'Nothing was recorded for $_firstName on ${widget.logDate}.',
            force: true,
          );
          return;
        }
        if (_summary?.isShared == true) {
          AppSnackbar.show(
            'Regenerated',
            'Share it again if the family should see the new version.',
            force: true,
          );
        }
        setState(() => _summary = summary);
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not generate summary',
        );
      },
    );
  }

  Future<void> _toggleShare() async {
    final current = _summary;
    if (current == null || _busy) return;
    if ((current.familySummary ?? '').trim().isEmpty && !current.isShared) {
      AppSnackbar.show(
        'Family summary needed',
        'Add a family summary before sharing.',
        force: true,
      );
      return;
    }
    setState(() => _busy = true);
    final result = current.isShared
        ? await _repo.unshareDaySummary(current.id)
        : await _repo.shareDaySummary(current.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (summary) {
        setState(() => _summary = summary);
        AppSnackbar.show(
          summary.isShared
              ? 'Shared with the family'
              : 'Taken back from the family portal',
          '',
          force: true,
        );
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not update sharing',
        );
      },
    );
  }

  Future<void> _edit() async {
    final current = _summary;
    if (current == null || !widget.canReview) return;
    final saved = await showAppBottomSheet<DailySummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditDailySummarySheet(
        summary: current,
        repository: _repo,
      ),
    );
    if (saved != null && mounted) {
      setState(() => _summary = saved);
      AppSnackbar.show(
        'Saved',
        current.isShared && !saved.isShared
            ? 'Share it again if the family should see the change.'
            : '',
        force: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled != true) return const SizedBox.shrink();
    final summary = _summary;
    return Container(
      key: const ValueKey('dl-daily-summary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.secondaryTeal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Daily summary — ${widget.logDate}',
                  style: handoverText(context, 14, weight: FontWeight.w700),
                ),
              ),
              if (widget.canReview)
                HandoverButton(
                  label: _busy
                      ? 'Generating…'
                      : summary == null
                          ? 'Generate summary'
                          : 'Regenerate',
                  icon: Icons.auto_awesome,
                  compact: true,
                  filled: summary == null,
                  onPressed: _busy || _loading ? null : _generate,
                ),
            ],
          ),
          if (summary != null && widget.canReview) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HandoverButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  compact: true,
                  onPressed: _busy ? null : _edit,
                ),
                HandoverButton(
                  label: summary.isShared ? 'Stop sharing' : 'Share with family',
                  icon: summary.isShared
                      ? Icons.undo_rounded
                      : Icons.ios_share_rounded,
                  compact: true,
                  filled: !summary.isShared,
                  onPressed: _busy ||
                          ((summary.familySummary ?? '').trim().isEmpty &&
                              !summary.isShared)
                      ? null
                      : _toggleShare,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (_loading)
            Text(
              'Loading…',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            )
          else if (summary == null)
            Text(
              widget.canReview
                  ? 'No summary for this day yet. One is written automatically the morning after, or generate it now.'
                  : 'No summary for this day yet. One is written automatically the morning after.',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            )
          else ...[
            if (summary.editedAt != null || summary.isShared)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (summary.editedAt != null)
                      const DailyLogPill('Edited'),
                    if (summary.isShared)
                      const DailyLogPill(
                        'Shared with family',
                        tone: DailyLogTone.success,
                      ),
                  ],
                ),
              ),
            Text(
              summary.summary,
              style: handoverText(context, 13).copyWith(height: 1.45),
            ),
            if (summary.attention.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final line in summary.attention)
                Text(
                  '• $line',
                  style: handoverText(
                    context,
                    12.5,
                    color: AppColors.urgentAmber,
                  ),
                ),
            ],
            if ((summary.familySummary ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.isShared
                          ? 'For the family'
                          : 'For the family — not shared',
                      style: handoverText(
                        context,
                        12,
                        weight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.familySummary!,
                      style: handoverText(context, 12.5),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _footer(summary),
              style: handoverText(context, 11.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  String _footer(DailySummary summary) {
    final from = [
      for (final entry in summary.sources.entries)
        if (entry.value > 0)
          _sourceKindLabels[entry.key] ?? entry.key,
    ];
    final when = summary.generatedAt == null
        ? ''
        : ' ${DailyLogLabels.dateTime(summary.generatedAt)}';
    final who = (summary.generatedBy ?? '').trim();
    final lead = summary.generatedBy == null
        ? 'Written automatically'
        : 'Generated';
    return [
      '$lead$when',
      if (from.isNotEmpty) 'from ${from.join(', ')}',
      if (who.isNotEmpty) 'by $who',
      'Read it against the records before relying on it.',
    ].join(from.isEmpty && who.isEmpty ? '. ' : '. ').replaceAll('..', '.');
  }
}

class _EditDailySummarySheet extends StatefulWidget {
  final DailySummary summary;
  final DailyLogsRepository repository;

  const _EditDailySummarySheet({
    required this.summary,
    required this.repository,
  });

  @override
  State<_EditDailySummarySheet> createState() => _EditDailySummarySheetState();
}

class _EditDailySummarySheetState extends State<_EditDailySummarySheet> {
  late final TextEditingController _summary =
      TextEditingController(text: widget.summary.summary);
  late final TextEditingController _family =
      TextEditingController(text: widget.summary.familySummary ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _summary.dispose();
    _family.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _summary.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final result = await widget.repository.updateDaySummary(
      widget.summary.id,
      summary: text,
      familySummary: _family.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (saved) => Navigator.of(context).pop(saved),
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not save summary',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit daily summary',
                style: handoverText(context, 16, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _summary,
                maxLines: 8,
                style: handoverText(context, 13.5),
                decoration: InputDecoration(
                  labelText: 'Staff summary',
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _family,
                maxLines: 5,
                style: handoverText(context, 13.5),
                decoration: InputDecoration(
                  labelText: 'Family summary',
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Spacer(),
                  HandoverButton(
                    label: 'Cancel',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  HandoverButton(
                    label: _saving ? 'Saving…' : 'Save',
                    filled: true,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
