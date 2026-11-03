import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../ai/domain/entities/ai_assist.dart';
import '../../../ai/domain/repositories/ai_assist_repository.dart';
import '../../../ai/presentation/widgets/ai_feature_sheets.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

const _askDayPresets = [
  (
    id: 'overview',
    label: 'Full Day Overview',
    icon: Icons.description_outlined,
  ),
  (
    id: 'handover',
    label: 'Shift Handover',
    icon: Icons.assignment_outlined,
  ),
  (
    id: 'medication',
    label: 'Meds & Doses',
    icon: Icons.medication_outlined,
  ),
  (
    id: 'meals',
    label: 'Meals & Fluids',
    icon: Icons.restaurant_outlined,
  ),
  (
    id: 'behavior',
    label: 'Behavior & Mood',
    icon: Icons.sentiment_satisfied_alt_outlined,
  ),
];

const _sourceLabels = {
  'care_note': 'Care note',
  'medication': 'Medication',
  'check': 'Check',
  'task': 'Task',
  'incident': 'Incident',
  'handover': 'Handover',
  'activity': 'Activity',
  'appointment': 'Appointment',
};

/// Web Resident Activity "AI Day Assistant" card.
class AiDayAssistantCard extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String logDate;

  const AiDayAssistantCard({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.logDate,
  });

  @override
  State<AiDayAssistantCard> createState() => _AiDayAssistantCardState();
}

class _AiDayAssistantCardState extends State<AiDayAssistantCard> {
  final _question = TextEditingController();
  bool? _enabled;
  bool _expanded = true;
  bool _asking = false;
  String? _activePreset;
  AiAskDayAnswer? _answer;
  bool _copied = false;

  String get _firstName {
    final parts = widget.clientName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'Resident' : parts.first;
  }

  @override
  void initState() {
    super.initState();
    _loadEnabled();
  }

  @override
  void didUpdateWidget(covariant AiDayAssistantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId ||
        oldWidget.logDate != widget.logDate) {
      _question.clear();
      _answer = null;
      _activePreset = null;
    }
  }

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _loadEnabled() async {
    final enabled = await aiDraftingEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  Future<void> _ask({required String query, required String preset}) async {
    if (_asking) return;
    setState(() {
      _asking = true;
      _answer = null;
      _activePreset = preset == 'custom' ? null : preset;
    });
    final repo = GetIt.instance<AiAssistRepository>();
    final result = await repo.askDay(
      clientId: widget.clientId,
      logDate: widget.logDate,
      query: query,
      preset: preset,
    );
    if (!mounted) return;
    setState(() => _asking = false);
    result.when(
      success: (answer) => setState(() => _answer = answer),
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not ask AI',
        );
      },
    );
  }

  Future<void> _copy() async {
    final text = _answer?.answer.trim() ?? '';
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    AppSnackbar.show('Summary copied to clipboard', '', force: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  void _reset() {
    setState(() {
      _question.clear();
      _answer = null;
      _activePreset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled != true) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('dl-ai-day-assistant'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceWhite,
            AppColors.secondaryTeal.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'AI Day Assistant',
                          style: handoverText(
                            context,
                            14,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const DailyLogPill(
                          'Interactive',
                          tone: DailyLogTone.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ask any question or get instant briefings about $_firstName's day",
                      style: handoverText(
                        context,
                        12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_answer != null)
                IconButton(
                  tooltip: 'Reset',
                  onPressed: _asking ? null : _reset,
                  icon: const Icon(Icons.close, size: 18),
                ),
              IconButton(
                tooltip: _expanded ? 'Collapse' : 'Expand',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 22,
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _askDayPresets)
                  _PresetChip(
                    label: preset.label,
                    icon: preset.icon,
                    selected: _activePreset == preset.id,
                    enabled: !_asking,
                    onTap: () => _ask(query: '', preset: preset.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _question,
                    enabled: !_asking,
                    minLines: 1,
                    maxLines: 3,
                    style: handoverText(context, 13),
                    decoration: InputDecoration(
                      hintText:
                          "Ask anything about $_firstName's day (e.g. 'Did he eat dinner?', 'Any incidents?')...",
                      hintStyle: handoverText(
                        context,
                        12.5,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceWhite,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.searchBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.searchBorder),
                      ),
                      suffixIcon: _question.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear question',
                              onPressed: () => setState(_question.clear),
                              icon: const Icon(Icons.close, size: 16),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      final q = _question.text.trim();
                      if (q.isNotEmpty) _ask(query: q, preset: 'custom');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                HandoverButton(
                  label: _asking ? 'Analyzing…' : 'Ask AI',
                  icon: _asking ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  filled: true,
                  compact: true,
                  onPressed: _asking || _question.text.trim().isEmpty
                      ? null
                      : () => _ask(
                            query: _question.text.trim(),
                            preset: 'custom',
                          ),
                ),
              ],
            ),
            if (_asking) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.searchBorder),
                  color: AppColors.filterButtonBackground,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reading the day and drafting an answer…',
                        style: handoverText(
                          context,
                          12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_answer case final answer?) ...[
              const SizedBox(height: 12),
              _AnswerPanel(
                answer: answer,
                copied: _copied,
                onCopy: _copy,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected
            ? AppColors.secondaryTeal.withValues(alpha: 0.12)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.secondaryTeal
                    : AppColors.searchBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.textHeading),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: handoverText(context, 12, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  final AiAskDayAnswer answer;
  final bool copied;
  final VoidCallback onCopy;

  const _AnswerPanel({
    required this.answer,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (answer.status) {
      'partly' => 'Partly answered',
      'not_recorded' => 'Not recorded',
      _ => 'Answered',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.searchBorder),
        color: AppColors.surfaceWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DailyLogPill(
                statusLabel,
                tone: answer.status == 'not_recorded'
                    ? DailyLogTone.warning
                    : DailyLogTone.success,
              ),
              const Spacer(),
              HandoverButton(
                label: copied ? 'Copied' : 'Copy',
                icon: copied ? Icons.check_rounded : Icons.copy_rounded,
                compact: true,
                onPressed: onCopy,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            answer.answer,
            style: handoverText(context, 13).copyWith(height: 1.45),
          ),
          if (answer.needsAttention.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.urgentAmber.withValues(alpha: 0.35),
                ),
                color: AppColors.urgentBackground,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Needs attention',
                    style: handoverText(
                      context,
                      12,
                      weight: FontWeight.w700,
                      color: AppColors.urgentAmber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final line in answer.needsAttention)
                    Text(
                      '• $line',
                      style: handoverText(context, 12.5),
                    ),
                ],
              ),
            ),
          ],
          if (answer.notIncluded.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Not included: ${answer.notIncluded.join(', ')}',
              style: handoverText(context, 11.5, color: AppColors.textMuted),
            ),
          ],
          if (answer.sources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Sources:',
                  style: handoverText(
                    context,
                    11.5,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                for (final source in answer.sources)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      [
                        _sourceLabels[source.type] ?? source.type,
                        if ((source.time ?? '').isNotEmpty) source.time,
                        if (source.label.isNotEmpty) source.label,
                      ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                      style: handoverText(context, 11.5),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
