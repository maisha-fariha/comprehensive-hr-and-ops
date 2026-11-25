import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/ai_assist.dart';
import '../../domain/repositories/ai_assist_repository.dart';
import 'ai_draft_sheet.dart';

Future<bool> aiDraftingEnabled([AiAssistRepository? repository]) async {
  try {
    final repo = repository ?? GetIt.instance<AiAssistRepository>();
    final result = await repo.isDraftingEnabled();
    return await result.when(
      success: (enabled) async => enabled,
      failure: (_) async => false,
    );
  } catch (_) {
    // GetIt / network failures must not leave Care Planning AI stuck on null.
    return false;
  }
}

Future<void> openMarMedicationReview(
  BuildContext context, {
  required String clientId,
  required String firstName,
  AiAssistRepository? repository,
}) async {
  final repo = repository ?? GetIt.instance<AiAssistRepository>();
  var days = 14;
  List<AiMarFigure> figures = const [];

  await showAiDraftSheet(
    context,
    title: 'Medication review — $firstName',
    sends:
        "Sends $firstName's medication record for the period — medicines, doses not given and why, late rounds and as-needed use, first name only — to draft what stands out for the nurse.",
    options: [
      StatefulBuilder(
        builder: (context, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AiDropdownField(
              label: 'Period',
              value: '$days',
              options: const [
                AiSelectOption('7', 'Last 7 days'),
                AiSelectOption('14', 'Last 14 days'),
                AiSelectOption('30', 'Last 30 days'),
              ],
              onChanged: (v) => setLocal(() => days = int.tryParse(v) ?? 14),
            ),
            if (figures.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SimpleTable(
                headers: const [
                  'Medicine',
                  'Given',
                  'Refused',
                  'Missed',
                  'Withheld',
                  'Late',
                ],
                rows: [
                  for (final f in figures)
                    [
                      '${f.medication}${f.asNeeded ? ' (PRN)' : ''}',
                      '${f.given}',
                      '${f.refused}',
                      '${f.missed}',
                      '${f.withheld}',
                      '${f.late}',
                    ],
                ],
              ),
            ],
          ],
        ),
      ),
    ],
    generate: () async {
      final result = await repo.reviewMar(clientId: clientId, days: days);
      return result.when(
        success: (review) async {
          figures = review.figures;
          return Result.success(
            AiDraftPayload(
              draft: review.draft,
              note:
                  'The table is counted from the record. This is advice for the nurse — it does not change any dose.',
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    },
  );
}

Future<void> openRotaReviewSheet(
  BuildContext context, {
  required String fromDate,
  required List<AiSelectOption> residences,
  String? initialResidenceId,
  AiAssistRepository? repository,
}) async {
  if (residences.isEmpty) {
    AppSnackbar.show('No homes', 'Add a residence before reviewing the rota.');
    return;
  }
  final repo = repository ?? GetIt.instance<AiAssistRepository>();
  var residenceId = initialResidenceId?.isNotEmpty == true
      ? initialResidenceId!
      : residences.first.value;
  var days = 7;
  List<String> findings = const [];

  await showAiDraftSheet(
    context,
    title: 'Rota review — from $fromDate',
    sends:
        "Sends the home's shifts, how many each needs and has, hours worked, rest between shifts and training run out — with staff as S1, S2… and never by name — to write up what needs sorting.",
    options: [
      StatefulBuilder(
        builder: (context, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AiDropdownField(
                    label: 'Home',
                    value: residenceId,
                    options: residences,
                    onChanged: (v) => setLocal(() => residenceId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AiDropdownField(
                    label: 'Period',
                    value: '$days',
                    options: const [
                      AiSelectOption('7', 'This week'),
                      AiSelectOption('14', 'Two weeks'),
                    ],
                    onChanged: (v) =>
                        setLocal(() => days = int.tryParse(v) ?? 7),
                  ),
                ),
              ],
            ),
            if (findings.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final line in findings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $line',
                    style: handoverText(context, 12),
                  ),
                ),
            ],
          ],
        ),
      ),
    ],
    generate: () async {
      final result = await repo.reviewRota(
        residenceId: residenceId,
        from: fromDate,
        days: days,
      );
      return result.when(
        success: (review) async {
          findings = review.lines.isEmpty
              ? const ['Nothing found to sort out.']
              : review.lines;
          return Result.success(
            AiDraftPayload(
              draft: review.draft,
              note:
                  'The list above is worked out from the rota; the note below explains it.',
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    },
  );
}

Future<void> openTrainingGapsSheet(
  BuildContext context, {
  AiAssistRepository? repository,
}) async {
  final repo = repository ?? GetIt.instance<AiAssistRepository>();
  AiTrainingGaps? gaps;

  await showAiDraftSheet(
    context,
    title: 'Training gaps',
    sends:
        'Sends the counts per course — assigned, done, overdue, due soon, certificates run out — and who has several things overdue, as S1, S2… and never by name, to write up what to deal with first.',
    options: [
      StatefulBuilder(
        builder: (context, setLocal) {
          final data = gaps;
          if (data == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SimpleTable(
                headers: const [
                  'Course',
                  'Done',
                  'Overdue',
                  'Due ≤30d',
                  'Certs expired',
                ],
                rows: [
                  for (final c in data.courses)
                    [
                      c.course,
                      '${c.completed}/${c.assigned}',
                      '${c.overdue}${c.mandatoryOverdue > 0 ? ' (${c.mandatoryOverdue} mandatory)' : ''}',
                      '${c.dueWithin30Days}',
                      '${c.certificatesExpired}',
                    ],
                ],
              ),
              if (data.people.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final p in data.people)
                  Text(
                    '${p.name} — ${p.overdue.join(', ')}'
                    '${p.mandatory > 0 ? ' (${p.mandatory} mandatory)' : ''}',
                    style: handoverText(context, 12),
                  ),
              ],
            ],
          );
        },
      ),
    ],
    generate: () async {
      final result = await repo.trainingGaps();
      return result.when(
        success: (review) async {
          gaps = review;
          return Result.success(
            AiDraftPayload(
              draft: review.draft,
              note:
                  'The table is counted from the records; the note below says what to deal with first.',
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    },
  );
}

Future<void> openWhatToOrderSheet(
  BuildContext context, {
  required List<AiSelectOption> residences,
  String? initialResidenceId,
  AiAssistRepository? repository,
}) async {
  if (residences.isEmpty) {
    AppSnackbar.show('No homes', 'Choose a residence before ordering.');
    return;
  }
  final repo = repository ?? GetIt.instance<AiAssistRepository>();
  var residenceId = initialResidenceId?.isNotEmpty == true
      ? initialResidenceId!
      : residences.first.value;
  var days = 30;
  List<AiStockOrderItem> items = const [];

  await showAiDraftSheet(
    context,
    title: 'What to order',
    sends:
        "Sends each item's stock, usage, reorder level, write-offs and what is on order — no staff or residents — to write a purchasing note.",
    options: [
      StatefulBuilder(
        builder: (context, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AiDropdownField(
                    label: 'Home',
                    value: residenceId,
                    options: residences,
                    onChanged: (v) => setLocal(() => residenceId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AiDropdownField(
                    label: 'Usage over',
                    value: '$days',
                    options: const [
                      AiSelectOption('30', 'Last 30 days'),
                      AiSelectOption('60', 'Last 60 days'),
                    ],
                    onChanged: (v) =>
                        setLocal(() => days = int.tryParse(v) ?? 30),
                  ),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SimpleTable(
                headers: const [
                  'Item',
                  'Stock',
                  'Days left',
                  'On order',
                  'Order',
                ],
                rows: [
                  for (final i in items)
                    [
                      '${i.item}${i.atOrBelowReorderLevel ? ' (under level)' : ''}',
                      '${i.stock}${i.unit == null ? '' : ' ${i.unit}'}',
                      i.daysLeft?.toString() ?? '—',
                      '${i.onOrder}',
                      '${i.suggestedOrder}',
                    ],
                ],
              ),
            ],
          ],
        ),
      ),
    ],
    generate: () async {
      final result =
          await repo.reviewStock(residenceId: residenceId, days: days);
      return result.when(
        success: (review) async {
          items = review.items;
          return Result.success(
            AiDraftPayload(
              draft: review.draft,
              note:
                  'The table is worked out from usage and open orders; the note explains it.',
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    },
  );
}

Future<void> openSummariseProgressSheet(
  BuildContext context, {
  required String clientId,
  required String firstName,
  AiAssistRepository? repository,
}) async {
  final repo = repository ?? GetIt.instance<AiAssistRepository>();
  var days = 7;

  await showAiDraftSheet(
    context,
    title: 'Progress summary — $firstName',
    sends:
        "Sends $firstName's daily log entries (and incidents, if you can see them) for the period — first name only — to draft a short summary for a handover or a family update.",
    options: [
      StatefulBuilder(
        builder: (context, setLocal) => AiDropdownField(
          label: 'Period',
          value: '$days',
          options: const [
            AiSelectOption('7', 'Last 7 days'),
            AiSelectOption('30', 'Last 30 days'),
          ],
          onChanged: (v) => setLocal(() => days = int.tryParse(v) ?? 7),
        ),
      ),
    ],
    generate: () async {
      final result =
          await repo.summarizeDailyLogs(clientId: clientId, days: days);
      return result.when(
        success: (draft) async => Result.success(
          AiDraftPayload(
            draft: draft.draft,
            note: draft.partial
                ? 'Drafted from the most recent entries only — the period had more.'
                : null,
          ),
        ),
        failure: (error) async => Result.failure(error),
      );
    },
  );
}

Future<void> openDraftOutcomeReviewSheet(
  BuildContext context, {
  required String clientId,
  required String firstName,
  AiAssistRepository? repository,
}) async {
  final repo = repository ?? GetIt.instance<AiAssistRepository>();
  var days = 30;

  await showAiDraftSheet(
    context,
    title: 'Outcome review — $firstName',
    sends:
        "Sends $firstName's goals and what was logged against them in the period — first name only — to draft a progress review.",
    options: [
      StatefulBuilder(
        builder: (context, setLocal) => AiDropdownField(
          label: 'Period',
          value: '$days',
          options: const [
            AiSelectOption('30', 'Last 30 days'),
            AiSelectOption('60', 'Last 60 days'),
            AiSelectOption('90', 'Last 90 days'),
          ],
          onChanged: (v) => setLocal(() => days = int.tryParse(v) ?? 30),
        ),
      ),
    ],
    generate: () async {
      final result = await repo.reviewGoals(clientId: clientId, days: days);
      return result.when(
        success: (draft) async => Result.success(
          AiDraftPayload(draft: draft.draft),
        ),
        failure: (error) async => Result.failure(error),
      );
    },
  );
}

Future<void> openSuggestGoalsSheet(
  BuildContext context, {
  required String clientId,
  required String firstName,
  required String Function(String category) categoryLabel,
  required Future<String?> Function(Map<String, dynamic> body) onAdd,
  AiAssistRepository? repository,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SuggestGoalsSheet(
      clientId: clientId,
      firstName: firstName,
      categoryLabel: categoryLabel,
      onAdd: onAdd,
      repository: repository ?? GetIt.instance<AiAssistRepository>(),
    ),
  );
}

class _SuggestGoalsSheet extends StatefulWidget {
  final String clientId;
  final String firstName;
  final String Function(String category) categoryLabel;
  final Future<String?> Function(Map<String, dynamic> body) onAdd;
  final AiAssistRepository repository;

  const _SuggestGoalsSheet({
    required this.clientId,
    required this.firstName,
    required this.categoryLabel,
    required this.onAdd,
    required this.repository,
  });

  @override
  State<_SuggestGoalsSheet> createState() => _SuggestGoalsSheetState();
}

class _SuggestGoalsSheetState extends State<_SuggestGoalsSheet> {
  final _notes = TextEditingController();
  List<AiGoalSuggestion>? _suggestions;
  final Set<int> _selected = {};
  bool _loading = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _suggest() async {
    if (_loading) return;
    setState(() => _loading = true);
    final result = await widget.repository.suggestGoals(
      clientId: widget.clientId,
      notes: _notes.text,
      count: 4,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (data) {
        setState(() {
          _suggestions = data.suggestions;
          _selected
            ..clear()
            ..addAll([
              for (var i = 0; i < data.suggestions.length; i++) i,
            ]);
        });
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not suggest goals',
        );
      },
    );
  }

  Future<void> _addSelected() async {
    final list = _suggestions;
    if (list == null || _selected.isEmpty || _loading) return;
    setState(() => _loading = true);
    for (final index in _selected.toList()..sort()) {
      final item = list[index];
      final error = await widget.onAdd({
        'category': item.category,
        if ((item.title ?? '').trim().isNotEmpty) 'title': item.title!.trim(),
        if ((item.description ?? '').trim().isNotEmpty)
          'description': item.description!.trim(),
        if ((item.targetDate ?? '').trim().isNotEmpty)
          'targetDate': item.targetDate!.trim(),
      });
      if (error != null) {
        if (mounted) {
          setState(() => _loading = false);
          AppSnackbar.show('Could not add goal', error, force: true);
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    AppSnackbar.show(
      'Goals added',
      '${_selected.length} goal${_selected.length == 1 ? '' : 's'} added.',
      force: true,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final suggestions = _suggestions;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Suggested goals — ${widget.firstName}',
                    style: handoverText(context, 16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI suggestions — choose only the ones that fit, and edit them after adding.',
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Sends ${widget.firstName}'s service plan, diagnoses and care notes on file, their current goals and the last 30 days of their daily log — first name only, no medicines — with your notes below.",
                    style: handoverText(
                      context,
                      12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: suggestions == null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _notes,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Optional — what came up at the assessment or the last review',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: HandoverButton(
                                    label: _loading ? 'Thinking…' : 'Suggest',
                                    icon: Icons.auto_awesome,
                                    filled: true,
                                    onPressed: _loading ? null : _suggest,
                                  ),
                                ),
                              ],
                            )
                          : suggestions.isEmpty
                              ? Text(
                                  'Too little is known about ${widget.firstName} to suggest a goal — add to the care plan or write your notes, then try again.',
                                  style: handoverText(
                                    context,
                                    13.5,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (var i = 0; i < suggestions.length; i++)
                                      _GoalSuggestionTile(
                                        suggestion: suggestions[i],
                                        categoryLabel: widget.categoryLabel(
                                          suggestions[i].category,
                                        ),
                                        selected: _selected.contains(i),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked) {
                                              _selected.add(i);
                                            } else {
                                              _selected.remove(i);
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      HandoverButton(
                        label: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (suggestions != null && suggestions.isNotEmpty)
                        HandoverButton(
                          label: _loading
                              ? 'Adding…'
                              : 'Add selected (${_selected.length})',
                          filled: true,
                          onPressed: _selected.isEmpty || _loading
                              ? null
                              : _addSelected,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalSuggestionTile extends StatelessWidget {
  final AiGoalSuggestion suggestion;
  final String categoryLabel;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _GoalSuggestionTile({
    required this.suggestion,
    required this.categoryLabel,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title?.trim().isNotEmpty == true
                      ? suggestion.title!
                      : categoryLabel,
                  style: handoverText(context, 13.5, weight: FontWeight.w700),
                ),
                if ((suggestion.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestion.description!,
                    style: handoverText(context, 12.5),
                  ),
                ],
                if ((suggestion.why ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestion.why!,
                    style: handoverText(
                      context,
                      12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const _SimpleTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 40,
        columnSpacing: 16,
        columns: [
          for (final h in headers)
            DataColumn(
              label: Text(h, style: handoverText(context, 11, weight: FontWeight.w600)),
            ),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                for (final cell in row)
                  DataCell(Text(cell, style: handoverText(context, 11.5))),
              ],
            ),
        ],
      ),
    );
  }
}
