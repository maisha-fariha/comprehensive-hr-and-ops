import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../ai/domain/entities/ai_assist.dart';
import '../../../ai/domain/repositories/ai_assist_repository.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../daily_logs_labels.dart';

/// Web New Log Entry → Care Details "Tidy my note".
Future<AiDailyLogDraftEntry?> showTidyMyNoteSheet(
  BuildContext context, {
  required String clientId,
  required String initialNotes,
  String? logType,
  String? mood,
  String? sleep,
  String? hygiene,
  AiAssistRepository? repository,
}) {
  return showAppBottomSheet<AiDailyLogDraftEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TidyMyNoteSheet(
      clientId: clientId,
      initialNotes: initialNotes,
      logType: logType,
      mood: mood,
      sleep: sleep,
      hygiene: hygiene,
      repository: repository ?? GetIt.instance<AiAssistRepository>(),
    ),
  );
}

class _TidyMyNoteSheet extends StatefulWidget {
  final String clientId;
  final String initialNotes;
  final String? logType;
  final String? mood;
  final String? sleep;
  final String? hygiene;
  final AiAssistRepository repository;

  const _TidyMyNoteSheet({
    required this.clientId,
    required this.initialNotes,
    required this.logType,
    required this.mood,
    required this.sleep,
    required this.hygiene,
    required this.repository,
  });

  @override
  State<_TidyMyNoteSheet> createState() => _TidyMyNoteSheetState();
}

class _TidyMyNoteSheetState extends State<_TidyMyNoteSheet> {
  late final TextEditingController _notes =
      TextEditingController(text: widget.initialNotes);
  late final TextEditingController _draft = TextEditingController();
  AiDailyLogDraftEntry? _result;
  String? _note;
  bool _loading = false;

  @override
  void dispose() {
    _notes.dispose();
    _draft.dispose();
    super.dispose();
  }

  String? _labelOf(List<(String, String)> options, String? value) {
    if (value == null || value.isEmpty) return null;
    final label = DailyLogLabels.labelOf(options, value);
    if (label.isNotEmpty) return label;
    return value;
  }

  Future<void> _generate() async {
    final notes = _notes.text.trim();
    if (notes.isEmpty) {
      AppSnackbar.show(
        'Note required',
        'Enter your note before tidying.',
        force: true,
      );
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    final result = await widget.repository.draftDailyLogEntry(
      clientId: widget.clientId,
      notes: notes,
      logType: widget.logType,
      mood: widget.mood,
      sleep: widget.sleep,
      hygiene: widget.hygiene,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (draft) {
        final filled = <String>[
          ?_labelOf(DailyLogLabels.logTypes, draft.logType),
          ?_labelOf(DailyLogLabels.moods, draft.observations.mood),
          ?_labelOf(DailyLogLabels.sleeps, draft.observations.sleep),
          ?_labelOf(DailyLogLabels.hygiene, draft.observations.hygiene),
          if ((draft.observations.meals ?? '').trim().isNotEmpty)
            'meals: ${draft.observations.meals}',
        ];
        final flag = draft.flag;
        final flagNote = flag == null
            ? ''
            : 'It will also be flagged for attention '
                '(${_labelOf(DailyLogLabels.flagCategories, flag.category) ?? flag.category}): '
                '${flag.note}';
        setState(() {
          _result = draft;
          _draft.text = draft.body;
          _note = [
            if (filled.isNotEmpty) 'Also filled in: ${filled.join(', ')}.',
            if (flagNote.isNotEmpty) flagNote,
          ].join(' ');
          if (_note!.isEmpty) _note = null;
        });
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not tidy note',
        );
      },
    );
  }

  void _use() {
    final draft = _result;
    if (draft == null) return;
    final body = _draft.text.trim();
    Navigator.of(context).pop(
      body.isEmpty ? draft : draft.copyWith(body: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final hasDraft = _result != null;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 20),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 10,
                bottom: 16,
              ),
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
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tidy my note',
                              style: handoverText(
                                context,
                                16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'An AI first draft — read every line and correct it before you use it.',
                              style: handoverText(
                                context,
                                12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Sends your note and the resident's first name to write up the entry and pick the observations it covers.",
                    style: handoverText(
                      context,
                      12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Your note',
                            style: handoverText(
                              context,
                              13,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          TextField(
                            controller: _notes,
                            maxLines: 5,
                            enabled: !_loading,
                            style: handoverText(context, 13.5),
                            decoration: InputDecoration(
                              hintText:
                                  'However you usually write it — e.g. ate well, quiet afternoon, asked for the nurse about 6pm and flag it for the nurse.',
                              hintStyle: handoverText(
                                context,
                                12.5,
                                color: AppColors.textMuted,
                              ),
                              filled: true,
                              fillColor: AppColors.scaffoldBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (!hasDraft)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.searchBorder),
                              ),
                              child: Center(
                                child: HandoverButton(
                                  label: _loading ? 'Drafting…' : 'Draft it',
                                  icon: Icons.auto_awesome,
                                  filled: true,
                                  onPressed: _loading ? null : _generate,
                                ),
                              ),
                            )
                          else ...[
                            if ((_note ?? '').isNotEmpty) ...[
                              Text(
                                _note!,
                                style: handoverText(
                                  context,
                                  12.5,
                                  color: AppColors.urgentAmber,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              'Draft',
                              style: handoverText(
                                context,
                                13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            TextField(
                              controller: _draft,
                              maxLines: 10,
                              style: handoverText(context, 13.5),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.scaffoldBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasDraft)
                        HandoverButton(
                          label: _loading ? 'Drafting…' : 'Draft again',
                          icon: Icons.auto_awesome,
                          onPressed: _loading ? null : _generate,
                        ),
                      const Spacer(),
                      HandoverButton(
                        label: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      if (hasDraft) ...[
                        const SizedBox(width: 8),
                        HandoverButton(
                          label: 'Put it in the entry',
                          filled: true,
                          onPressed: _use,
                        ),
                      ],
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
