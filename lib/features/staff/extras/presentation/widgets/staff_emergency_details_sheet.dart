import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_emergency_alert.dart';

/// Reference-matched Emergency details panel.
class StaffEmergencyDetailsSheet extends StatefulWidget {
  final StaffEmergencyAlert initialAlert;

  const StaffEmergencyDetailsSheet({super.key, required this.initialAlert});

  static Future<void> show(StaffEmergencyAlert alert) {
    return Get.dialog<void>(
      StaffEmergencyDetailsSheet(initialAlert: alert),
      barrierDismissible: true,
    );
  }

  @override
  State<StaffEmergencyDetailsSheet> createState() =>
      _StaffEmergencyDetailsSheetState();
}

class _StaffEmergencyDetailsSheetState
    extends State<StaffEmergencyDetailsSheet> {
  late final AppApiClient _api;
  late StaffEmergencyAlert _alert;
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _submittingNote = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<AppApiClient>();
    _alert = widget.initialAlert;
    _loadDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await _api.get(
      ApiEndpoints.emergencyAlertById(_alert.id),
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        setState(() {
          _alert = StaffEmergencyAlert.fromJson(JsonCodec.unwrapMap(body));
          _loading = false;
        });
      },
      failure: (error) {
        // Keep list payload so the sheet still shows something useful.
        setState(() {
          _loading = false;
          _loadError = error.message;
        });
      },
    );
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        'Note required',
        'Write what you found or did.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _submittingNote = true);
    final result = await _api.post(
      ApiEndpoints.emergencyAlertNotes(_alert.id),
      data: {'note': text},
    );
    if (!mounted) return;
    setState(() => _submittingNote = false);
    result.when(
      success: (body) {
        _noteController.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _alert = StaffEmergencyAlert.fromJson(JsonCodec.unwrapMap(body));
        });
        Get.snackbar(
          'Note added',
          'Your response note was saved.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not add note',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxWidth =
        ResponsiveHelper.getResponsiveWidth(context, 440).clamp(300.0, 480.0);
    // Fixed height avoids Dialog + Expanded unbounded-height crashes.
    final dialogHeight = (media.size.height - media.viewInsets.bottom - 48)
        .clamp(360.0, media.size.height * 0.9);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        20 + media.viewInsets.bottom,
      ),
      child: SizedBox(
        width: maxWidth,
        height: dialogHeight,
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon(
                        'assets/icons/staff_core/panic_siren.svg',
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _alert.typeLabel,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: AppColors.textHeading,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _alert.headerSubtitle,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: _alert.statusLabel,
                        active: _alert.isActive,
                      ),
                      if (_alert.priorityLabel.isNotEmpty)
                        _PriorityChip(label: _alert.priorityLabel),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          children: [
                            if (_loadError != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.urgentBackgroundSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.searchBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Could not refresh details. Showing list data.\n$_loadError',
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadDetail,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            _SectionCard(
                              title: 'What was reported',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_alert.note.isNotEmpty)
                                    Text(
                                      _alert.note,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: AppColors.textHeading,
                                        height: 1.4,
                                      ),
                                    ),
                                  const SizedBox(height: 14),
                                  _DetailField(
                                    label: 'Raised by',
                                    value: _alert.raisedByName.isEmpty
                                        ? '—'
                                        : _alert.raisedByName,
                                  ),
                                  _DetailField(
                                    label: 'Resident',
                                    value: _alert.residentLabel,
                                  ),
                                  _DetailField(
                                    label: 'Where in the building',
                                    value: _alert.locationDisplay,
                                  ),
                                  _DetailField(
                                    label: 'Assigned to',
                                    value: _alert.assignedToLabel,
                                  ),
                                  _DetailField(
                                    label: 'House line',
                                    value: _alert.houseLine.isEmpty
                                        ? '—'
                                        : _alert.houseLine,
                                  ),
                                  _DetailField(
                                    label: "Reporter's phone",
                                    value: _alert.raisedByPhone.isEmpty
                                        ? '—'
                                        : _alert.raisedByPhone,
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Response',
                              child: _alert.responseNotes.isEmpty
                                  ? const Text(
                                      'No response notes yet.',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0;
                                            i < _alert.responseNotes.length;
                                            i++) ...[
                                          if (i > 0) const SizedBox(height: 12),
                                          _ResponseNoteTile(
                                            note: _alert.responseNotes[i],
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                            if (!_alert.isResolved) ...[
                              const SizedBox(height: 12),
                              _SectionCard(
                                title: 'Add to the response',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Note',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                        color: AppColors.textHeading,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _noteController,
                                      minLines: 4,
                                      maxLines: 6,
                                      enabled: !_submittingNote,
                                      textInputAction: TextInputAction.newline,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        color: AppColors.textHeading,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'What you found, what you did...',
                                        hintStyle: const TextStyle(
                                          fontFamily: 'Outfit',
                                          color: AppColors.textMuted,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.surfaceWhite,
                                        contentPadding:
                                            const EdgeInsets.all(14),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.searchBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.searchBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.secondaryTeal,
                                            width: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed:
                                          _submittingNote ? null : _addNote,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textHeading,
                                        side: const BorderSide(
                                          color: AppColors.searchBorder,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      child: _submittingNote
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.secondaryTeal,
                                              ),
                                            )
                                          : const Text(
                                              'Add note',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
              const Divider(height: 1, color: AppColors.dividerLight),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textHeading,
                      side: const BorderSide(color: AppColors.searchBorder),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailField({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseNoteTile extends StatelessWidget {
  final StaffEmergencyResponseNote note;

  const _ResponseNoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final meta = <String>[];
    if (note.actorName.isNotEmpty) meta.add(note.actorName);
    if (note.createdAt != null) {
      final d = note.createdAt!.toLocal();
      meta.add(
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.note,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
            color: AppColors.textHeading,
            height: 1.35,
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            meta.join(' · '),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFFCE8E8) : const Color(0xFFEEF1F4);
    final fg = active ? const Color(0xFFC62828) : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;

  const _PriorityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Color(0xFFB4791C),
        ),
      ),
    );
  }
}
