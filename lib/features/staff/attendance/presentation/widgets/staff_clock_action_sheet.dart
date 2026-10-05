import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../../../../core/media/app_file_picker.dart';

/// Web-parity Clock in / Clock out sheet.
///
/// Residence is required. Photo is optional (uploaded to
/// `POST /uploads?category=attendance`). Location is recorded when provided;
/// without a geo package the record notes position was not provided — same as
/// web when the browser denies geolocation.
class StaffClockActionSheet extends StatefulWidget {
  final bool isCheckIn;
  final String? initialResidenceId;
  final String? shiftId;
  final bool showNotRosteredWarning;
  final List<ManualEntryResidenceOption> residences;

  const StaffClockActionSheet({
    super.key,
    required this.isCheckIn,
    required this.residences,
    this.initialResidenceId,
    this.shiftId,
    this.showNotRosteredWarning = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool isCheckIn,
    required List<ManualEntryResidenceOption> residences,
    String? initialResidenceId,
    String? shiftId,
    bool showNotRosteredWarning = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StaffClockActionSheet(
        isCheckIn: isCheckIn,
        residences: residences,
        initialResidenceId: initialResidenceId,
        shiftId: shiftId,
        showNotRosteredWarning: showNotRosteredWarning,
      ),
    );
  }

  @override
  State<StaffClockActionSheet> createState() => _StaffClockActionSheetState();
}

class _StaffClockActionSheetState extends State<StaffClockActionSheet> {
  final _repo = GetIt.instance<StaffAttendanceRepository>();
  final _session = Get.find<UserSession>();

  String? _residenceId;
  String? _selfiePath;
  String? _selfieName;
  bool _submitting = false;
  String? _photoNote;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialResidenceId;
    if (initial != null &&
        initial.isNotEmpty &&
        widget.residences.any((r) => r.id == initial)) {
      _residenceId = initial;
    } else if (widget.residences.length == 1) {
      _residenceId = widget.residences.first.id;
    }
    _photoNote =
        'Permission denied — clocking ${widget.isCheckIn ? 'in' : 'out'} without a photo is allowed.';
  }

  Future<void> _pickPhoto() async {
    final picked = await AppFilePicker.pickFiles(
      context: context,
      type: FileType.image,
      allowMultiple: false,
      withData: false,
      title: 'Clock photo',
      preferredCamera: CameraDevice.front,
    );
    final file = picked?.files.single;
    if (file?.path == null || file!.path!.isEmpty) return;
    setState(() {
      _selfiePath = file.path;
      _selfieName = file.name;
      _photoNote = 'Photo ready — uploaded on submit.';
    });
  }

  Future<void> _submit() async {
    final residenceId = _residenceId;
    if (residenceId == null || residenceId.isEmpty) {
      AppErrorDialog.showPageError(
        title: widget.isCheckIn ? 'Choose a residence' : 'Residence required',
        message: 'Where is required — pick the residence you are clocking at.',
      );
      return;
    }

    setState(() => _submitting = true);
    String? selfieUrl;
    if (_selfiePath != null && _selfiePath!.isNotEmpty) {
      final upload = await _repo.uploadAttendanceSelfie(
        localPath: _selfiePath!,
        fileName: _selfieName ?? 'attendance-selfie.jpg',
      );
      if (upload.isFailure) {
        setState(() => _submitting = false);
        AppErrorDialog.showResultError(
          upload.error,
          fallbackTitle: 'Could not upload photo',
        );
        return;
      }
      selfieUrl = upload.value;
    }

    final result = widget.isCheckIn
        ? await _repo.checkIn(
            shiftId: widget.shiftId,
            residenceId: residenceId,
            selfieUrl: selfieUrl,
          )
        : await _repo.checkOut(
            shiftId: widget.shiftId,
            residenceId: residenceId,
            selfieUrl: selfieUrl,
          );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle:
            widget.isCheckIn ? 'Could not clock in' : 'Could not clock out',
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCheckIn ? 'Clock in' : 'Clock out';
    final who = _session.displayName.trim().isEmpty
        ? 'You'
        : _session.displayName.trim();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final residenceItems = [
      for (final r in widget.residences)
        DropdownMenuItem(value: r.id, child: Text(r.name)),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                top: 12,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isCheckIn
                        ? Icons.photo_camera_outlined
                        : Icons.logout_rounded,
                    color: AppColors.textHeading,
                    size: 22,
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 8),
                  ),
                  Expanded(
                    child: Text(
                      title,
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
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).maybePop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  bottom: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'The photo and the location are recorded with the time. '
                      'Neither is required — without them the record simply says so.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (widget.isCheckIn && widget.showNotRosteredWarning) ...[
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.urgentBackgroundSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.urgentAmber.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          'You are not rostered on a shift right now. Clocking in '
                          'follows the rota. If you worked hours nobody rostered, '
                          'ask a manager to add them.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              12.5,
                            ),
                            color: AppColors.urgentAmber,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                    Text(
                      'Who',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 6),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.filterButtonBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.searchBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              who,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  14,
                                ),
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      widget.isCheckIn
                          ? 'Clocking in as yourself.'
                          : 'Clocking out as yourself.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          11.5,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textHeading,
                        ),
                        children: const [
                          TextSpan(text: 'Where '),
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: AppColors.criticalRed),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 6),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.searchBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Choose a residence.'),
                          value: _residenceId,
                          items: residenceItems,
                          onChanged: _submitting
                              ? null
                              : (v) => setState(() => _residenceId = v),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.urgentBackgroundSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.urgentAmber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No location',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      13,
                                    ),
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Position was not provided — the '
                                  '${widget.isCheckIn ? 'clock-in' : 'clock-out'} '
                                  'still goes through.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      11.5,
                                    ),
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    Text(
                      'Photo',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 6),
                    ),
                    InkWell(
                      onTap: _submitting ? null : _pickPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.filterButtonBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.searchBorder),
                        ),
                        child: Text(
                          _photoNote ?? '',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              12.5,
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      'Kept as evidence of who was here and when. Nothing compares the face to anything.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          11,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                top: 8,
                bottom: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).maybePop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 10),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(title),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
