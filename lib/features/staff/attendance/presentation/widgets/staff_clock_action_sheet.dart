import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_mapper.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../extras/presentation/pages/staff_shift_handovers_page.dart';
import '../../../../hr/attendance/domain/entities/manual_entry_options.dart';
import '../../../../hr/attendance/presentation/attendance_formatters.dart';
import '../../../../hr/attendance/presentation/pages/attendance_clock_page.dart'
    show earlyDepartureReasons;
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../../../../core/media/app_file_picker.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// A device fix sent with clock in / clock out when the web would send one.
class StaffClockFix {
  final double latitude;
  final double longitude;
  final double accuracyMeters;

  const StaffClockFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
}

/// Best-effort position. Throws a short message when it cannot be read.
/// Photo and location stay optional: a failure still allows submit.
Future<StaffClockFix> staffClockDeviceLocation() async {
  try {
    return await _readStaffClockFix();
  } catch (error) {
    if (error is String) rethrow;
    throw 'Location unavailable';
  }
}

Future<StaffClockFix> _readStaffClockFix() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw 'Location services are turned off';
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw 'Location permission was not given';
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 8),
    ),
  );
  return StaffClockFix(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracyMeters: position.accuracy,
  );
}

/// Web-parity Clock in / Clock out sheet.
///
/// Residence is required. Photo is optional (uploaded to
/// `POST /uploads?category=attendance`). Location is captured when the device
/// allows it and omitted when it does not — same as the web.
class StaffClockActionSheet extends StatefulWidget {
  final bool isCheckIn;
  final String? initialResidenceId;
  final String? shiftId;
  final DateTime? shiftEndsAt;
  final bool showNotRosteredWarning;
  final List<ManualEntryResidenceOption> residences;
  final Future<StaffClockFix> Function()? locate;

  const StaffClockActionSheet({
    super.key,
    required this.isCheckIn,
    required this.residences,
    this.initialResidenceId,
    this.shiftId,
    this.shiftEndsAt,
    this.showNotRosteredWarning = false,
    this.locate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool isCheckIn,
    required List<ManualEntryResidenceOption> residences,
    String? initialResidenceId,
    String? shiftId,
    DateTime? shiftEndsAt,
    bool showNotRosteredWarning = false,
    Future<StaffClockFix> Function()? locate,
  }) {
    return showAppBottomSheet<bool>(
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
        shiftEndsAt: shiftEndsAt,
        showNotRosteredWarning: showNotRosteredWarning,
        locate: locate,
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
  StaffClockFix? _location;
  String? _locationError;
  String? _submitError;
  bool _writeHandover = false;
  String? _earlyReason;
  final _earlyNotes = TextEditingController();
  Timer? _locationGiveUp;
  late final Future<void> _locationTask;

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
    _locationTask = _captureLocation();
  }

  @override
  void dispose() {
    _locationGiveUp?.cancel();
    _earlyNotes.dispose();
    super.dispose();
  }

  /// Web shows the early-leave box only while the rostered shift is still
  /// running. After it ends the reason is not kept.
  bool get _leavingEarly {
    final endsAt = widget.shiftEndsAt;
    if (widget.isCheckIn || endsAt == null) return false;
    return DateTime.now().isBefore(endsAt);
  }

  Future<void> _captureLocation() async {
    final done = Completer<StaffClockFix?>();
    _locationGiveUp = Timer(const Duration(seconds: 8), () {
      if (!done.isCompleted) done.complete(null);
    });
    final locate = widget.locate ?? staffClockDeviceLocation;
    locate().then((fix) {
      if (!done.isCompleted) done.complete(fix);
    }, onError: (Object error, StackTrace _) {
      if (!done.isCompleted) done.completeError(error);
    });
    try {
      final fix = await done.future;
      if (!mounted) return;
      setState(() {
        _location = fix;
        _locationError = fix == null ? 'Location unavailable' : null;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().trim();
      setState(() {
        _location = null;
        _locationError = message.isEmpty ? 'Location unavailable' : message;
      });
    } finally {
      _locationGiveUp?.cancel();
    }
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

  void _showSubmitError(String message, {bool writeHandover = false}) {
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitError = message;
      _writeHandover = writeHandover;
    });
  }

  /// Web clock-out toast for `HANDOVER_REQUIRED`, including the "Write it" action.
  bool _handoverRequired(AppError? error) {
    final data = error is ApiError ? error.responseData : null;
    final code = '${data?['code'] ?? data?['errorCode'] ?? ''}'.toUpperCase();
    if (code == 'HANDOVER_REQUIRED') return true;
    return (error?.message ?? '').toLowerCase().contains('handover');
  }

  Future<void> _submit() async {
    final residenceId = _residenceId;
    if (residenceId == null || residenceId.isEmpty) {
      _showSubmitError(
        'Where is required — pick the residence you are clocking at.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
      _writeHandover = false;
    });
    await _locationTask;
    if (!mounted) return;

    String? selfieUrl;
    if (_selfiePath != null && _selfiePath!.isNotEmpty) {
      final upload = await _repo.uploadAttendanceSelfie(
        localPath: _selfiePath!,
        fileName: _selfieName ?? 'attendance-selfie.jpg',
      );
      if (upload.isFailure) {
        final info = AppErrorMapper.from(
          upload.error,
          fallbackTitle: 'Could not upload photo',
        );
        _showSubmitError('${info.title}. ${info.message}');
        return;
      }
      selfieUrl = upload.value;
    }

    final fix = _location;
    final result = widget.isCheckIn
        ? await _repo.checkIn(
            shiftId: widget.shiftId,
            residenceId: residenceId,
            latitude: fix?.latitude,
            longitude: fix?.longitude,
            accuracyMeters: fix?.accuracyMeters,
            selfieUrl: selfieUrl,
          )
        : await _repo.checkOut(
            shiftId: widget.shiftId,
            residenceId: residenceId,
            latitude: fix?.latitude,
            longitude: fix?.longitude,
            accuracyMeters: fix?.accuracyMeters,
            selfieUrl: selfieUrl,
            earlyDepartureReason: _leavingEarly ? _earlyReason : null,
            earlyDepartureNotes:
                _leavingEarly ? _earlyNotes.text.trim() : null,
          );
    if (!mounted) return;

    if (result.isFailure) {
      final handover =
          !widget.isCheckIn && _handoverRequired(result.error);
      if (handover) {
        // Web ignores the raw body and always shows this sentence + Write it.
        _showSubmitError(
          'Write the handover for this shift before clocking out.',
          writeHandover: true,
        );
        return;
      }
      final info = AppErrorMapper.from(
        result.error,
        fallbackTitle:
            widget.isCheckIn ? 'Could not clock in' : 'Could not clock out',
      );
      _showSubmitError('${info.title}. ${info.message}');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCheckIn ? 'Clock in' : 'Clock out';
    final location = _location;
    final who = _session.displayName.trim().isEmpty
        ? 'You'
        : _session.displayName.trim();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final residenceItems = [
      for (final r in widget.residences)
        DropdownMenuItem(value: r.id, child: Text(r.name)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context).height;
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screen;
        final room = available - bottomInset;
        final height = room <= 0
            ? 0.0
            : (screen * 0.88).clamp(0.0, room);
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: height,
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
                    if (_leavingEarly) ...[
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      _EarlyLeaveBox(
                        endsAt: widget.shiftEndsAt!,
                        reason: _earlyReason,
                        notesController: _earlyNotes,
                        onReason: _submitting
                            ? null
                            : (value) => setState(() => _earlyReason = value),
                      ),
                    ],
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    _ClockLocationRow(
                      location: location,
                      error: _locationError,
                      clockOut: !widget.isCheckIn,
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
            if (_submitError != null)
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  top: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _submitError!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.criticalRed,
                        height: 1.35,
                      ),
                    ),
                    if (_writeHandover)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                            Get.to(() => const StaffShiftHandoversPage());
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Write it',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
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
      },
    );
  }
}

/// Same location line as the web clock dialog: a status pill plus the
/// device accuracy in meters.
class _ClockLocationRow extends StatelessWidget {
  final StaffClockFix? location;
  final String? error;
  final bool clockOut;

  const _ClockLocationRow({
    required this.location,
    required this.error,
    required this.clockOut,
  });

  @override
  Widget build(BuildContext context) {
    final found = location;
    final action = clockOut ? 'clock-out' : 'clock-in';
    Widget pill(String label, Color foreground, Color background) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: foreground,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.place_outlined, size: 15, color: AppColors.textMuted),
          if (found != null) ...[
            pill(
              'Location found',
              AppColors.activeGreen,
              AppColors.activeBackground,
            ),
            Text(
              'accurate to about ${found.accuracyMeters.round()} m',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ] else if (error != null) ...[
            pill(
              'No location',
              AppColors.urgentAmber,
              AppColors.urgentBackground,
            ),
            Text(
              '$error — the record will say the position was not provided, '
              'and the $action still goes through.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: 12.5,
                height: 1.3,
                color: AppColors.textSecondary,
              ),
            ),
          ] else
            const Text(
              'Finding your location…',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Same early-leave block the web clock-out dialog shows while the shift
/// is still running. The reason and notes are optional.
class _EarlyLeaveBox extends StatelessWidget {
  final DateTime endsAt;
  final String? reason;
  final TextEditingController notesController;
  final ValueChanged<String?>? onReason;

  const _EarlyLeaveBox({
    required this.endsAt,
    required this.reason,
    required this.notesController,
    required this.onReason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.urgentAmber),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your shift runs until ${AttendanceFormat.time(endsAt)}',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppColors.primaryNavy,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Only kept if you are actually finishing early.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Why are you leaving early?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Choose a reason (optional)'),
                value: reason,
                items: [
                  for (final option in earlyDepartureReasons)
                    DropdownMenuItem(value: option.$1, child: Text(option.$2)),
                ],
                onChanged: onReason,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            enabled: onReason != null,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: AppColors.textHeading,
            ),
            decoration: InputDecoration(
              hintText: 'Anything worth recording',
              hintStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
