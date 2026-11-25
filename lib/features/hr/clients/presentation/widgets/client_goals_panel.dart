import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../ai/presentation/widgets/ai_draft_sheet.dart';
import '../../../ai/presentation/widgets/ai_feature_sheets.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/client_goals.dart';
import '../clients_labels.dart';
import '../controllers/clients_controller.dart';
import 'clients_common.dart';

/// Web Care Planning "Goals & Outcomes" panel — AI actions + live goals.
///
/// When [clientId] is empty (Add New Client), [ensureClientId] is called before
/// any AI / add-goal action so the panel matches the saved-client web UI.
class ClientGoalsPanel extends StatefulWidget {
  final ClientsController controller;
  final String clientId;
  final String? firstName;
  final bool readOnly;

  /// Create-wizard hook: persist a draft and return its id so AI can run.
  final Future<String?> Function()? ensureClientId;

  const ClientGoalsPanel({
    super.key,
    required this.controller,
    required this.clientId,
    this.firstName,
    this.readOnly = false,
    this.ensureClientId,
  });

  @override
  State<ClientGoalsPanel> createState() => _ClientGoalsPanelState();
}

class _ClientGoalsPanelState extends State<ClientGoalsPanel> {
  late String _clientId = widget.clientId;
  List<ClientGoal>? _goals;
  ClientGoalOutcomes _outcomes = const ClientGoalOutcomes();
  List<ClientGoalCategory> _categories = const [];
  String? _loadError;

  bool _adding = false;
  bool _saving = false;
  bool _resolving = false;
  String _category = '';
  final _title = TextEditingController();
  String _targetDate = '';
  String? _addError;
  bool? _aiEnabled;

  ClientsController get _c => widget.controller;

  /// Create or update permission — create wizard uses [canCreate].
  bool get _canWrite =>
      !widget.readOnly && (_c.canUpdate || _c.canCreate);

  String get _firstName {
    final raw = (widget.firstName ?? '').trim();
    if (raw.isEmpty) return 'Client';
    return raw.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _c.goalCategories().then((c) {
      if (mounted) setState(() => _categories = c);
    });
    aiDraftingEnabled().then((enabled) {
      if (mounted) setState(() => _aiEnabled = enabled);
    }).catchError((_) {
      if (mounted) setState(() => _aiEnabled = false);
    });
  }

  @override
  void didUpdateWidget(covariant ClientGoalsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clientId.isNotEmpty && widget.clientId != _clientId) {
      _clientId = widget.clientId;
      _load();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<String?> _resolveClientId() async {
    if (_clientId.isNotEmpty) return _clientId;
    final ensure = widget.ensureClientId;
    if (ensure == null) return null;
    setState(() => _resolving = true);
    final id = await ensure();
    if (!mounted) return id;
    setState(() {
      _resolving = false;
      if (id != null && id.isNotEmpty) _clientId = id;
    });
    if (id != null && id.isNotEmpty) await _load();
    return id;
  }

  Future<void> _load() async {
    if (_clientId.isEmpty) {
      if (mounted) {
        setState(() {
          _goals = const [];
          _outcomes = const ClientGoalOutcomes();
          _loadError = null;
        });
      }
      return;
    }
    final goals = await _c.loadGoals(_clientId);
    final outcomes = await _c.loadGoalOutcomes(_clientId);
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

  Future<void> _startAdd() async {
    final id = await _resolveClientId();
    if (id == null || id.isEmpty || !mounted) return;
    setState(() => _adding = true);
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
    final id = await _resolveClientId();
    if (id == null || id.isEmpty || !mounted) return;
    setState(() => _saving = true);
    final error = await _c.addGoal(id, {
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
    final id = await _resolveClientId();
    if (id == null || id.isEmpty) return;
    final error = await _c.setGoalStatus(id, goal.id, status);
    if (error == null) await _load();
  }

  Future<void> _remove(ClientGoal goal) async {
    final id = await _resolveClientId();
    if (id == null || id.isEmpty) return;
    final error = await _c.removeGoal(id, goal.id);
    if (error == null) await _load();
  }

  Future<void> _openSummarise() async {
    final id = await _resolveClientId();
    if (id == null || id.isEmpty || !mounted) return;
    await openSummariseProgressSheet(
      context,
      clientId: id,
      firstName: _firstName,
    );
  }

  Future<void> _openOutcomeReview() async {
    final id = await _resolveClientId();
    if (id == null || id.isEmpty || !mounted) return;
    await openDraftOutcomeReviewSheet(
      context,
      clientId: id,
      firstName: _firstName,
    );
  }

  Future<void> _openSuggestGoals() async {
    final id = await _resolveClientId();
    if (id == null || id.isEmpty || !mounted) return;
    await openSuggestGoalsSheet(
      context,
      clientId: id,
      firstName: _firstName,
      categoryLabel: (key) {
        for (final c in _categories) {
          if (c.key == key) return c.label;
        }
        return 'Custom';
      },
      onAdd: (body) async {
        final error = await _c.addGoal(id, body);
        if (error == null) await _load();
        return error;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = _goals;
    // Match web Client Details: show AI as soon as drafting is enabled.
    final showAi = _aiEnabled == true;
    return Column(
      key: const ValueKey('client-goals-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.track_changes_rounded,
                size: 18,
                color: AppColors.secondaryTeal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Goals & Outcomes',
                style: handoverText(context, 15, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (showAi || (_canWrite && !_adding)) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Web Client Details Care Planning AI row (exact labels).
              if (showAi) ...[
                AiAssistButton(
                  buttonKey: const ValueKey('client-summarise-progress'),
                  label: 'Summarise progress',
                  onPressed: _resolving ? null : _openSummarise,
                ),
                AiAssistButton(
                  buttonKey: const ValueKey('client-draft-outcome-review'),
                  label: 'Draft outcome review',
                  onPressed: _resolving ? null : _openOutcomeReview,
                ),
                if (_canWrite)
                  AiAssistButton(
                    buttonKey: const ValueKey('client-suggest-goals'),
                    label: 'Suggest goals',
                    onPressed: _resolving ? null : _openSuggestGoals,
                  ),
              ],
              if (_canWrite && !_adding)
                HandoverButton(
                  key: const ValueKey('client-goal-add'),
                  label: 'Add goal',
                  icon: Icons.add_rounded,
                  compact: true,
                  onPressed: _resolving ? null : _startAdd,
                ),
            ],
          ),
        ],
        if (_resolving) ...[
          const SizedBox(height: 10),
          Text(
            'Saving draft so AI can run…',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
        ],
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
