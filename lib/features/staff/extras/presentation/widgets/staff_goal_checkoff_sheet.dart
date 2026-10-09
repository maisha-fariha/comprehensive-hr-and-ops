import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../hr/clients/data/clients_endpoints.dart';
import '../../../../hr/clients/data/mappers/clients_mapper.dart';
import '../../../../hr/clients/domain/entities/client_goals.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

Future<void> showStaffGoalCheckoffSheet(
  BuildContext context, {
  required String clientId,
  required String clientName,
  String? staffId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StaffGoalCheckoffSheet(
      clientId: clientId,
      clientName: clientName,
      staffId: staffId,
    ),
  );
}

/// Today's goal check-off for one client: `POST /clients/{id}/goals/logs`
/// with one entry per goal. Re-saving the same day updates the entries.
class StaffGoalCheckoffSheet extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String? staffId;

  const StaffGoalCheckoffSheet({
    super.key,
    required this.clientId,
    required this.clientName,
    this.staffId,
  });

  @override
  State<StaffGoalCheckoffSheet> createState() => _StaffGoalCheckoffSheetState();
}

class _Entry {
  bool achieved = false;
  GoalAssistance assistance = GoalAssistance.independent;
  final TextEditingController notes = TextEditingController();
}

class _StaffGoalCheckoffSheetState extends State<StaffGoalCheckoffSheet> {
  final _api = GetIt.instance<AppApiClient>();
  final _entries = <String, _Entry>{};
  late final String _today = _isoDate(DateTime.now());

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<ClientGoal> _goals = const [];

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final entry in _entries.values) {
      entry.notes.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      _api.get(ClientsEndpoints.goals(widget.clientId), silent: true),
      _api.get(
        ClientsEndpoints.goalLogs(widget.clientId),
        query: {'from': _today, 'to': _today},
        silent: true,
      ),
    ]);
    if (!mounted) return;
    final goalsResult = results[0];
    if (goalsResult.isFailure) {
      setState(() {
        _loading = false;
        _error = goalsResult.error?.message ?? 'Could not load goals.';
      });
      return;
    }
    final goals =
        ClientsMapper.goalsFrom(goalsResult.value).where((g) => g.isActive);
    final logs = results[1].isSuccess
        ? ClientsMapper.goalLogsFrom(results[1].value)
            .where((log) =>
                log.logDate.startsWith(_today) &&
                (widget.staffId == null || log.staffId == widget.staffId))
            .toList()
        : const <ClientGoalLog>[];
    for (final goal in goals) {
      final entry = _entries.putIfAbsent(goal.id, _Entry.new);
      for (final log in logs.where((l) => l.goalId == goal.id)) {
        entry.achieved = log.achieved;
        entry.assistance = log.assistance;
        entry.notes.text = log.notes;
      }
    }
    setState(() {
      _goals = goals.toList();
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving || _goals.isEmpty) return;
    setState(() => _saving = true);
    final result = await _api.post(
      ClientsEndpoints.goalLogs(widget.clientId),
      data: {
        'logDate': _today,
        'entries': [
          for (final goal in _goals)
            {
              'goalId': goal.id,
              'achieved': _entries[goal.id]!.achieved,
              'assistanceLevel': _entries[goal.id]!.assistance.value,
              if (_entries[goal.id]!.notes.text.trim().isNotEmpty)
                'notes': _entries[goal.id]!.notes.text.trim(),
            },
        ],
      },
      silent: true,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Goals saved', '', force: true);
        Navigator.of(context).pop();
      },
      failure: (error) =>
          AppSnackbar.show('Could not save goals', error.message, force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        key: const Key('staff-goal-checkoff'),
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's goals",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textHeading,
                          ),
                        ),
                        Text(
                          widget.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body()),
            if (!_loading && _error == null && _goals.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('staff-goal-checkoff-save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save goals'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_goals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No active goals for this client yet. A manager adds goals on '
            'the client record.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _goalTile(_goals[index]),
    );
  }

  Widget _goalTile(ClientGoal goal) {
    final entry = _entries[goal.id]!;
    return Container(
      key: ValueKey('staff-goal-${goal.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.achieved
              ? AppColors.successGreen.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
        color: entry.achieved
            ? AppColors.activeBackground
            : AppColors.surfaceWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            key: ValueKey('staff-goal-achieved-${goal.id}'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.secondaryTeal,
            value: entry.achieved,
            onChanged: (v) => setState(() => entry.achieved = v ?? false),
            title: Text(
              goal.title.isEmpty ? goal.categoryLabel : goal.title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
            subtitle: goal.title.isEmpty || goal.title == goal.categoryLabel
                ? null
                : Text(
                    goal.categoryLabel,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          DropdownButtonFormField<GoalAssistance>(
            key: ValueKey('staff-goal-assistance-${goal.id}'),
            initialValue: entry.assistance,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Assistance',
              isDense: true,
            ),
            items: [
              for (final a in GoalAssistance.values)
                DropdownMenuItem(value: a, child: Text(a.label)),
            ],
            onChanged: (v) => setState(
              () => entry.assistance = v ?? GoalAssistance.independent,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey('staff-goal-notes-${goal.id}'),
            controller: entry.notes,
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
