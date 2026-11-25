import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/incident_ai_draft.dart';
import '../../domain/repositories/incidents_repository.dart';

/// Web "Draft from my notes" dialog for Create Incident step 1.
Future<IncidentAiDraft?> showDraftFromNotesSheet(
  BuildContext context, {
  required IncidentsRepository repository,
  required String initialNotes,
  String? residenceId,
  String? clientId,
  String? categoryId,
  required List<String> detectedDuringOptions,
  required List<String> notificationParties,
}) {
  return showAppBottomSheet<IncidentAiDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DraftFromNotesSheet(
      repository: repository,
      initialNotes: initialNotes,
      residenceId: residenceId,
      clientId: clientId,
      categoryId: categoryId,
      detectedDuringOptions: detectedDuringOptions,
      notificationParties: notificationParties,
    ),
  );
}

class _DraftFromNotesSheet extends StatefulWidget {
  final IncidentsRepository repository;
  final String initialNotes;
  final String? residenceId;
  final String? clientId;
  final String? categoryId;
  final List<String> detectedDuringOptions;
  final List<String> notificationParties;

  const _DraftFromNotesSheet({
    required this.repository,
    required this.initialNotes,
    required this.residenceId,
    required this.clientId,
    required this.categoryId,
    required this.detectedDuringOptions,
    required this.notificationParties,
  });

  @override
  State<_DraftFromNotesSheet> createState() => _DraftFromNotesSheetState();
}

class _DraftFromNotesSheetState extends State<_DraftFromNotesSheet> {
  static const _tips = [
    'when and where',
    'what happened',
    'who found it and who saw it',
    'injuries',
    'what you did straight away',
    'who you told and when',
    'your supervisor',
    'any follow-up or debrief',
  ];

  late final TextEditingController _notesController;
  late final TextEditingController _previewController;
  IncidentAiDraft? _draft;
  String? _note;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
    _previewController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      AppSnackbar.show(
        'Notes required',
        'Enter your notes before drafting.',
        force: true,
      );
      return;
    }
    if (_generating) return;

    setState(() => _generating = true);
    final result = await widget.repository.draftIncidentFromNotes(
      notes: notes,
      residenceId: widget.residenceId,
      clientId: widget.clientId,
      categoryId: widget.categoryId,
      detectedDuringOptions: widget.detectedDuringOptions,
      notificationParties: widget.notificationParties,
    );
    if (!mounted) return;
    setState(() => _generating = false);

    result.when(
      success: (draft) {
        final filled = <String>[
          if (draft.date != null || draft.time != null) 'when it happened',
          if (draft.categoryId != null) 'the category',
          if (draft.clientId != null) 'the resident',
          if (draft.detectedDuring != null) 'when it was noticed',
          if (draft.witnesses.isNotEmpty) 'witnesses',
          if (draft.externalAgency != null) 'the attending service',
          if (draft.notifications.isNotEmpty) 'who was told',
          'the title',
          if (draft.immediateAction.trim().isNotEmpty) 'the immediate action',
          if ((draft.categoryDetail ?? '').trim().isNotEmpty)
            'the category detail',
          if (draft.reportedBy != null) 'you as the reporter',
          if (draft.supervisor != null)
            'the supervisor (${draft.supervisor!.name})',
          if (_hasChildDetails(draft.child)) "the child's details",
          if (draft.followUp?.required == true) 'the follow-up',
          if (draft.debrief?.completed == true) 'the debrief',
          if (draft.severity != null) 'severity (${draft.severity})',
        ];
        final noteParts = <String>[
          'This is the description. ${filled.join(', ')} will be filled in too.',
          if (draft.missing.isNotEmpty)
            'Still needed: ${draft.missing.join('; ')}.',
        ];
        setState(() {
          _draft = draft;
          _previewController.text = draft.description;
          _note = noteParts.join(' ');
        });
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not draft from notes',
        );
      },
    );
  }

  bool _hasChildDetails(IncidentAiChild? child) {
    if (child == null) return false;
    return (child.idNumber ?? '').trim().isNotEmpty ||
        child.cfsStatus.isNotEmpty ||
        (child.cipName ?? '').trim().isNotEmpty ||
        (child.cipOffice ?? '').trim().isNotEmpty ||
        child.informedOfRights != null;
  }

  void _putInReport() {
    final draft = _draft;
    if (draft == null) return;
    Navigator.of(context).pop(
      IncidentAiDraft(
        date: draft.date,
        time: draft.time,
        endTime: draft.endTime,
        categoryId: draft.categoryId,
        clientId: draft.clientId,
        residenceId: draft.residenceId,
        detectedDuring: draft.detectedDuring,
        witnesses: draft.witnesses,
        externalAgency: draft.externalAgency,
        notifications: draft.notifications,
        title: draft.title,
        description: _previewController.text.trim().isEmpty
            ? draft.description
            : _previewController.text.trim(),
        immediateAction: draft.immediateAction,
        severity: draft.severity,
        emergencyServicesContacted: draft.emergencyServicesContacted,
        familyNotified: draft.familyNotified,
        categoryDetail: draft.categoryDetail,
        reportedBy: draft.reportedBy,
        supervisor: draft.supervisor,
        child: draft.child,
        followUp: draft.followUp,
        debrief: draft.debrief,
        missing: draft.missing,
        cirAnswers: draft.cirAnswers,
        model: draft.model,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

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
                      width: ResponsiveHelper.getResponsiveWidth(context, 40),
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                      decoration: BoxDecoration(
                        color: AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 14),
                  ),
                  Text(
                    'Draft incident report',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 18),
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 8),
                  ),
                  Text(
                    "Sends your notes, the category (or the list to choose from) and the resident's first name to draft the report: when it happened, title, description, immediate action, witnesses, who was told, follow-up and debrief, and a severity to consider. A supervisor named in your notes is matched to staff here, not by the AI.",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 14),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your notes',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13,
                              ),
                              color: AppColors.textHeading,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              7,
                            ),
                          ),
                          TextField(
                            controller: _notesController,
                            maxLines: 6,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                14,
                              ),
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'In your own words: what happened, when, who was there, what you did.',
                              hintStyle: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  13,
                                ),
                                color: AppColors.textPlaceholder,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceWhite,
                              contentPadding:
                                  ResponsiveHelper.getResponsivePadding(
                                context,
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveRadius(
                                    context,
                                    14,
                                  ),
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveRadius(
                                    context,
                                    14,
                                  ),
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveRadius(
                                    context,
                                    14,
                                  ),
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              8,
                            ),
                          ),
                          Text(
                            'Include: ${_tips.join(', ')}.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                11.5,
                              ),
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              14,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _generating ? null : _generate,
                              icon: _generating
                                  ? SizedBox(
                                      width: ResponsiveHelper.getResponsiveSize(
                                        context,
                                        16,
                                      ),
                                      height:
                                          ResponsiveHelper.getResponsiveSize(
                                        context,
                                        16,
                                      ),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.auto_awesome,
                                      size: ResponsiveHelper.getResponsiveSize(
                                        context,
                                        16,
                                      ),
                                    ),
                              label: Text(
                                _generating ? 'Drafting…' : 'Generate draft',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    14,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryNavy,
                                side: const BorderSide(
                                  color: AppColors.searchBorder,
                                ),
                                padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveRadius(
                                      context,
                                      12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_draft != null) ...[
                            SizedBox(
                              height: ResponsiveHelper.getResponsiveHeight(
                                context,
                                18,
                              ),
                            ),
                            Text(
                              'Draft description',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  13,
                                ),
                                color: AppColors.textHeading,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveHelper.getResponsiveHeight(
                                context,
                                7,
                              ),
                            ),
                            TextField(
                              controller: _previewController,
                              maxLines: 5,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  14,
                                ),
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.scaffoldBackground,
                                contentPadding:
                                    ResponsiveHelper.getResponsivePadding(
                                  context,
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveRadius(
                                      context,
                                      14,
                                    ),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            if ((_note ?? '').isNotEmpty) ...[
                              SizedBox(
                                height: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  8,
                                ),
                              ),
                              Text(
                                _note!,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    12,
                                  ),
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 12),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                              color: AppColors.searchBorder,
                            ),
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveRadius(
                                  context,
                                  12,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveWidth(context, 10),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _draft == null ? null : _putInReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            disabledBackgroundColor:
                                AppColors.primaryNavy.withValues(alpha: 0.4),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveRadius(
                                  context,
                                  12,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            'Put it in the report',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13.5,
                              ),
                            ),
                          ),
                        ),
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
