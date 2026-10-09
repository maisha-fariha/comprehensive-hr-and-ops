import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/client_goals.dart';
import '../clients_labels.dart';
import '../controllers/clients_controller.dart';
import 'clients_common.dart';

/// The web "Goals & Outcomes" panel on a saved client: the resident's goals
/// with week / month / whole-stay progress from the shift check-offs.
class ClientGoalsPanel extends StatefulWidget {
  final ClientsController controller;
  final String clientId;
  final bool readOnly;

  const ClientGoalsPanel({
    super.key,
    required this.controller,
    required this.clientId,
    this.readOnly = false,
  });

  @override
  State<ClientGoalsPanel> createState() => _ClientGoalsPanelState();
}

class _ClientGoalsPanelState extends State<ClientGoalsPanel> {
  List<ClientGoal>? _goals;
  ClientGoalOutcomes _outcomes = const ClientGoalOutcomes();
  List<ClientGoalCategory> _categories = const [];
  String? _loadError;

  bool _adding = false;
  bool _saving = false;
  String _category = '';
  final _title = TextEditingController();
  String _targetDate = '';
  String? _addError;

  ClientsController get _c => widget.controller;
  bool get _canWrite => _c.canUpdate && !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _load();
    _c.goalCategories().then((c) {
      if (mounted) setState(() => _categories = c);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final goals = await _c.loadGoals(widget.clientId);
    final outcomes = await _c.loadGoalOutcomes(widget.clientId);
    if (!mounted) return;
    setState(() {
      goals.when(
        success: (g) {
          _goals = g;
          _loadError = null;
        },
        failure: (e) {
          _goals ??= const [];
          _loadError = e.message;
        },
      );
      outcomes.when(success: (o) => _outcomes = o, failure: (_) {});
    });
  }

  Future<void> _add() async {
    setState(() => _addError = null);
    if (_category.isEmpty) {
      setState(() => _addError = 'Choose a category.');
      return;
    }
    final title = _title.text.trim();
    if (_category == 'custom' && title.isEmpty) {
      setState(() => _addError = 'A custom goal needs a title.');
      return;
    }
    setState(() => _saving = true);
    final error = await _c.addGoal(widget.clientId, {
      'category': _category,
      if (title.isNotEmpty) 'title': title,
      if (_targetDate.isNotEmpty) 'targetDate': _targetDate,
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      _addError = error;
      if (error == null) {
        _adding = false;
        _category = '';
        _title.clear();
        _targetDate = '';
      }
    });
    if (error == null) await _load();
  }

  Future<void> _setStatus(ClientGoal goal, String status) async {
    final error = await _c.setGoalStatus(widget.clientId, goal.id, status);
    if (error == null) await _load();
  }

  Future<void> _remove(ClientGoal goal) async {
    final error = await _c.removeGoal(widget.clientId, goal.id);
    if (error == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final goals = _goals;
    return Column(
      key: const ValueKey('client-goals-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.track_changes_rounded, size: 18, color: AppColors.secondaryTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Goals & Outcomes',
                style: handoverText(context, 15, weight: FontWeight.w700),
              ),
            ),
            if (_canWrite && !_adding)
              HandoverButton(
                key: const ValueKey('client-goal-add'),
                label: 'Add goal',
                icon: Icons.add_rounded,
                compact: true,
                onPressed: () => setState(() => _adding = true),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (goals != null && goals.isNotEmpty) ...[
          _PeriodsRow(
            periods: _outcomes.overall,
            labels: const ('This week', 'This month', 'Whole stay'),
            boxed: true,
          ),
          const SizedBox(height: 12),
        ],
        if (_adding) ...[_addForm(context), const SizedBox(height: 12)],
        if (goals == null)
          Text('Loading goals…', style: handoverText(context, 13, color: AppColors.textMuted))
        else if (goals.isEmpty)
          Text(
            _loadError ??
                'No goals yet. Goals are logged by staff on each shift, '
                    'and their progress appears here.',
            style: handoverText(context, 13, color: AppColors.textMuted),
          )
        else
          for (final goal in goals) ...[
            _goalTile(context, goal),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _addForm(BuildContext context) {
    final custom = _category == 'custom';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_addError != null) ...[
            Text(_addError!, style: handoverText(context, 13, color: AppColors.criticalRed)),
            const SizedBox(height: 8),
          ],
          ClientSelect(
            key: const ValueKey('client-goal-category'),
            label: 'Category',
            required: true,
            placeholder: 'Choose a category',
            value: _category,
            options: [for (final c in _categories) (c.key, c.label)],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          ClientInput(
            key: const ValueKey('client-goal-title'),
            label: custom ? 'Goal' : 'Goal (optional wording)',
            required: custom,
            placeholder: 'e.g. Weekly call with mum',
            controller: _title,
          ),
          const SizedBox(height: 12),
          ClientDateField(
            label: 'Target date',
            value: _targetDate,
            onChanged: (v) => setState(() => _targetDate = v),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              HandoverButton(
                label: 'Cancel',
                compact: true,
                onPressed: () => setState(() {
                  _adding = false;
                  _addError = null;
                }),
              ),
              const SizedBox(width: 8),
              HandoverButton(
                key: const ValueKey('client-goal-save'),
                label: _saving ? 'Adding…' : 'Add goal',
                filled: true,
                compact: true,
                onPressed: _saving ? null : _add,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalTile(BuildContext context, ClientGoal goal) {
    final periods = _outcomes.byGoal[goal.id] ?? const GoalPeriods();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(goal.title, style: handoverText(context, 14, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ClientPill(label: goal.categoryLabel, tone: ClientTone.info),
              if (!goal.isActive)
                ClientPill(
                  label: goal.status == 'achieved' ? 'Achieved' : 'Discontinued',
                  tone: goal.status == 'achieved' ? ClientTone.success : ClientTone.neutral,
                ),
              if (goal.targetDate != null)
                Text(
                  'Target ${ClientsLabels.date(ClientsLabels.parseDateInput(goal.targetDate!))}',
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
            ],
          ),
          if (_canWrite) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (goal.isActive) ...[
                  HandoverButton(
                    label: 'Mark achieved',
                    compact: true,
                    onPressed: () => _setStatus(goal, 'achieved'),
                  ),
                  HandoverButton(
                    label: 'Discontinue',
                    compact: true,
                    onPressed: () => _setStatus(goal, 'discontinued'),
                  ),
                ] else
                  HandoverButton(
                    label: 'Reopen',
                    compact: true,
                    onPressed: () => _setStatus(goal, 'active'),
                  ),
                HandoverButton(
                  label: 'Remove',
                  compact: true,
                  foreground: AppColors.criticalRed,
                  onPressed: () => _remove(goal),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _PeriodsRow(periods: periods, labels: const ('Week', 'Month', 'Stay')),
        ],
      ),
    );
  }
}

class _PeriodsRow extends StatelessWidget {
  final GoalPeriods periods;
  final (String, String, String) labels;
  final bool boxed;

  const _PeriodsRow({required this.periods, required this.labels, this.boxed = false});

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _PeriodCell(label: labels.$1, period: periods.weekly)),
        Expanded(child: _PeriodCell(label: labels.$2, period: periods.monthly)),
        Expanded(child: _PeriodCell(label: labels.$3, period: periods.discharge)),
      ],
    );
    if (!boxed) return row;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: row,
    );
  }
}

class _PeriodCell extends StatelessWidget {
  final String label;
  final GoalPeriod period;

  const _PeriodCell({required this.label, required this.period});

  @override
  Widget build(BuildContext context) {
    final progress = period.progress;
    final trend = switch (period.trend) {
      'upward' => (Icons.trending_up_rounded, AppColors.activeGreen),
      'downward' => (Icons.trending_down_rounded, AppColors.criticalRed),
      _ => (Icons.arrow_forward_rounded, AppColors.textMuted),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              progress == null ? '—' : '$progress%',
              style: handoverText(context, 18, weight: FontWeight.w700),
            ),
            if (progress != null) ...[
              const SizedBox(width: 4),
              Icon(trend.$1, size: 14, color: trend.$2),
            ],
          ],
        ),
        Text(
          period.logged > 0
              ? '${period.achieved} of ${period.logged} shifts'
              : 'Nothing logged',
          style: handoverText(context, 11.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
