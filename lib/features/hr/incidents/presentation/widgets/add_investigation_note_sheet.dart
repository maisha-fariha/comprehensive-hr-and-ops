import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/investigation_incident.dart';
import '../../domain/repositories/incidents_repository.dart';

/// Opens a sheet to add an investigation note via
/// `PATCH /incidents/:id/investigation`.
Future<bool> showAddInvestigationNoteSheet(
  BuildContext context, {
  required InvestigationIncident incident,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddInvestigationNoteSheet(incident: incident),
  );
  return result == true;
}

class _AddInvestigationNoteSheet extends StatefulWidget {
  final InvestigationIncident incident;

  const _AddInvestigationNoteSheet({required this.incident});

  @override
  State<_AddInvestigationNoteSheet> createState() =>
      _AddInvestigationNoteSheetState();
}

class _AddInvestigationNoteSheetState
    extends State<_AddInvestigationNoteSheet> {
  late final TextEditingController _noteController;
  late final IncidentsRepository _repository;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _repository = GetIt.instance<IncidentsRepository>();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      AppSnackbar.show('Missing note', 'Please enter an investigation note.');
      return;
    }
    if (_saving) return;

    setState(() => _saving = true);
    final result = await _repository.recordInvestigation(
      incidentId: widget.incident.id,
      findings: note,
      status: 'open',
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        AppSnackbar.show(
          'Note added',
          'Investigation note was saved for ${widget.incident.title}.',
        );
        Navigator.of(context).pop(true);
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not add note',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: ResponsiveHelper.getResponsiveWidth(context, 40),
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.searchBorder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 16),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Note',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              18,
                            ),
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: ResponsiveHelper.getResponsiveSize(context, 22),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.incident.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 16),
                  ),
                  Text(
                    'Investigation note *',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 8),
                  ),
                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    minLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter findings or investigation notes…',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textFaint,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13.5,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceWhite,
                      contentPadding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 14,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 12),
                        ),
                        borderSide:
                            const BorderSide(color: AppColors.searchBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 12),
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.secondaryTeal,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 16),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textHeading,
                            side: const BorderSide(
                              color: AppColors.searchBorder,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.getResponsiveHeight(
                                context,
                                14,
                              ),
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
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveWidth(context, 10),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.primaryNavy.withValues(alpha: 0.5),
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.getResponsiveHeight(
                                context,
                                14,
                              ),
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
                          child: _saving
                              ? SizedBox(
                                  width: ResponsiveHelper.getResponsiveSize(
                                    context,
                                    18,
                                  ),
                                  height: ResponsiveHelper.getResponsiveSize(
                                    context,
                                    18,
                                  ),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Note',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
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
