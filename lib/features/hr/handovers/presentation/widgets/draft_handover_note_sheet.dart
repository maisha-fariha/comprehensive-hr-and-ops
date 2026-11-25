import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../ai/domain/entities/ai_assist.dart';
import '../../../ai/domain/repositories/ai_assist_repository.dart';
import 'handover_common.dart';

/// Web Record handover → "Draft handover note".
Future<AiHandoverDraft?> showDraftHandoverNoteSheet(
  BuildContext context, {
  required String residenceId,
  DateTime? shiftStartsAt,
  DateTime? shiftEndsAt,
  AiAssistRepository? repository,
}) {
  return showAppBottomSheet<AiHandoverDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DraftHandoverNoteSheet(
      residenceId: residenceId,
      shiftStartsAt: shiftStartsAt,
      shiftEndsAt: shiftEndsAt,
      repository: repository ?? GetIt.instance<AiAssistRepository>(),
    ),
  );
}

class _DraftHandoverNoteSheet extends StatefulWidget {
  final String residenceId;
  final DateTime? shiftStartsAt;
  final DateTime? shiftEndsAt;
  final AiAssistRepository repository;

  const _DraftHandoverNoteSheet({
    required this.residenceId,
    required this.shiftStartsAt,
    required this.shiftEndsAt,
    required this.repository,
  });

  @override
  State<_DraftHandoverNoteSheet> createState() =>
      _DraftHandoverNoteSheetState();
}

class _DraftHandoverNoteSheetState extends State<_DraftHandoverNoteSheet> {
  final _draft = TextEditingController();
  AiHandoverDraft? _result;
  String? _note;
  bool _loading = false;

  bool get _hasShiftWindow =>
      widget.shiftStartsAt != null && widget.shiftEndsAt != null;

  String get _sends => _hasShiftWindow
      ? "Sends this shift's tasks, log entries, checks, medication and "
          "incidents for the home — residents' first names only — to draft "
          'the summary, pending actions, flag and each resident\'s update.'
      : "Sends the last 12 hours of the home's tasks, log entries, checks, "
          "medication and incidents — residents' first names only — to draft "
          'the summary, pending actions, flag and each resident\'s update.';

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() => _loading = true);
    final starts = widget.shiftStartsAt;
    final ends = widget.shiftEndsAt;
    String? since;
    String? until;
    if (starts != null && ends != null) {
      final now = DateTime.now();
      since = starts.toUtc().toIso8601String();
      until = (ends.isAfter(now) ? now : ends).toUtc().toIso8601String();
    }
    final result = await widget.repository.draftHandover(
      residenceId: widget.residenceId,
      since: since,
      until: until,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (draft) {
        final extras = <String>[
          if (draft.actions.isNotEmpty)
            '${draft.actions.length} pending action'
                '${draft.actions.length == 1 ? '' : 's'}',
          if (draft.clientUpdates.isNotEmpty)
            'an update for ${draft.clientUpdates.length} resident'
                '${draft.clientUpdates.length == 1 ? '' : 's'}',
          if ((draft.flagCategory ?? '').isNotEmpty) 'a flag for attention',
        ];
        setState(() {
          _result = draft;
          _draft.text = draft.summary;
          _note = extras.isEmpty
              ? null
              : 'Also added to the form: ${extras.join(', ')}. '
                  'Anything you have already written stays as it is.';
        });
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not draft handover',
        );
      },
    );
  }

  void _use() {
    final draft = _result;
    if (draft == null) return;
    final summary = _draft.text.trim();
    Navigator.of(context).pop(
      summary.isEmpty ? draft : draft.copyWith(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    // Cap to the visible area (keyboard + home indicator already reserved).
    final maxHeight = (media.size.height - bottomInset) * 0.92;
    final hasDraft = _result != null;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: maxHeight,
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
                              'Draft handover note',
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _sends,
                            style: handoverText(
                              context,
                              12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!hasDraft)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.searchBorder,
                                ),
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
                              minLines: 6,
                              maxLines: 12,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    children: [
                      if (hasDraft)
                        HandoverButton(
                          label: _loading ? 'Drafting…' : 'Draft again',
                          icon: Icons.auto_awesome,
                          onPressed: _loading ? null : _generate,
                        ),
                      HandoverButton(
                        label: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      if (hasDraft)
                        HandoverButton(
                          label: 'Put it in the handover',
                          filled: true,
                          onPressed: _use,
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
