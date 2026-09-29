import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../attendance_formatters.dart';
import '../widgets/attendance_filters.dart';
import '../widgets/manual_entry/manual_entry_fields.dart';

class ClockLocation {
  final double latitude;
  final double longitude;
  final int accuracyMeters;

  const ClockLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
}

/// Throws a message string when the position cannot be read.
typedef ClockLocator = Future<ClockLocation> Function();

/// Returns the captured photo path, or null when the user backs out.
/// Throws a message string when no camera can be used.
typedef ClockPhotoTaker = Future<String?> Function();

Future<ClockLocation> _deviceLocation() async {
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
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return ClockLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy.round(),
    );
  } catch (error) {
    throw 'Location unavailable';
  }
}

Future<String?> _devicePhoto() async {
  try {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 1280,
    );
    return photo?.path;
  } catch (_) {
    throw 'Camera unavailable';
  }
}

const earlyDepartureReasons = <(String, String)>[
  ('sent_home', 'Sent home'),
  ('unwell', 'Unwell'),
  ('family_emergency', 'Family emergency'),
  ('cover_arrived', 'Cover arrived early'),
  ('shift_shortened', 'Shift was shortened'),
  ('appointment', 'Appointment'),
  ('other', 'Other — say below'),
];

/// The web "Clock in" / "Clock out" dialog: who, where, early-leave reason,
/// location and photo, posted to `/attendance/check-in|check-out`.
class AttendanceClockPage extends StatefulWidget {
  final bool clockOut;
  final OpenAttendance? openAttendance;
  final List<ManualEntryResidenceOption> residences;
  final String? defaultResidenceId;
  final ClockLocator locate;
  final ClockPhotoTaker takePhoto;

  const AttendanceClockPage({
    super.key,
    required this.clockOut,
    this.openAttendance,
    this.residences = const [],
    this.defaultResidenceId,
    this.locate = _deviceLocation,
    this.takePhoto = _devicePhoto,
  });

  @override
  State<AttendanceClockPage> createState() => _AttendanceClockPageState();
}

class _AttendanceClockPageState extends State<AttendanceClockPage> {
  late final AttendanceRepository _repository;
  late final UserSession _session;
  final _notesController = TextEditingController();

  AttendanceShiftWindow? _shift;
  String? _residenceId;
  String? _earlyReason;
  ClockLocation? _location;
  String? _locationError;
  String? _photoPath;
  String? _cameraError;
  bool _saving = false;

  String get _mode => widget.clockOut ? 'out' : 'in';

  String get _staffId => _session.staffId ?? _session.userId ?? '';

  OpenAttendance? get _open => widget.clockOut ? widget.openAttendance : null;

  bool get _canSubmit => widget.clockOut || (_shift?.isCurrent ?? false);

  String? get _effectiveResidenceId {
    final open = _open?.residenceId;
    if (open != null && open.isNotEmpty) return open;
    if (_residenceId != null && _residenceId!.isNotEmpty) return _residenceId;
    return _shift?.residenceId ?? widget.defaultResidenceId;
  }

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<AttendanceRepository>();
    _session = Get.find<UserSession>();
    _residenceId = widget.defaultResidenceId;
    _loadShift();
    _findLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadShift() async {
    if (_staffId.isEmpty || !_session.can('scheduling:read')) return;
    final result = await _repository.getMyShiftWindow(_staffId);
    if (!mounted) return;
    result.when(
      success: (shift) => setState(() => _shift = shift),
      failure: (_) {},
    );
  }

  Future<void> _findLocation() async {
    try {
      final location = await widget.locate();
      if (mounted) {
        setState(() {
          _location = location;
          _locationError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _locationError = error.toString());
    }
  }

  Future<void> _takePhoto() async {
    try {
      final path = await widget.takePhoto();
      if (path != null && mounted) setState(() => _photoPath = path);
    } catch (error) {
      if (mounted) setState(() => _cameraError = error.toString());
    }
  }

  Future<void> _submit() async {
    if (_staffId.isEmpty) {
      AppSnackbar.show(
        'Attendance',
        'Your login is not linked to an active staff record or user account.',
      );
      return;
    }
    final residenceId = _effectiveResidenceId;
    if (residenceId == null || residenceId.isEmpty) {
      AppSnackbar.show('Attendance', 'Choose a residence.');
      return;
    }
    setState(() => _saving = true);
    try {
      String? selfieUrl;
      final photo = _photoPath;
      if (photo != null) {
        final upload =
            await _repository.uploadSelfie(photo, 'clock-$_mode.jpg');
        upload.when(
          success: (url) => selfieUrl = url,
          failure: (error) => AppSnackbar.show(
            'Attendance',
            'Photo could not be saved: ${error.message}',
          ),
        );
      }
      final location = _location;
      final notes = _notesController.text.trim();
      final shift = _shift;
      final body = <String, dynamic>{
        'staffId': _staffId,
        'residenceId': residenceId,
        if (shift != null && shift.isCurrent) 'shiftId': shift.shiftId,
        if (location != null) ...{
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracyMeters': location.accuracyMeters,
        },
        'selfieUrl': ?selfieUrl,
        'earlyDepartureReason': ?_earlyReason,
        if (notes.isNotEmpty) 'earlyDepartureNotes': notes,
      };
      final result = widget.clockOut
          ? await _repository.clockOut(body)
          : await _repository.clockIn(body);
      if (!mounted) return;
      result.when(
        success: (_) {
          AppSnackbar.show(
            'Attendance',
            widget.clockOut ? 'Clocked out' : 'Clocked in',
          );
          Navigator.of(context).pop(true);
        },
        failure: (error) => AppSnackbar.show('Attendance', error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.clockOut ? 'Clock out' : 'Clock in';
    final shift = _shift;
    final open = _open;
    final residenceName = widget.residences
        .where((r) => r.id == _effectiveResidenceId)
        .map((r) => r.name)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: _text(18, FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'The photo and the location are recorded with the '
                          'time. Neither is required — without them the record '
                          'simply says so.',
                          style: _text(12.5, FontWeight.w400,
                              AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (!_canSubmit) ...[
                    _WarningBox(
                      title: shift != null
                          ? 'Your next shift starts '
                              '${AttendanceFormat.date(shift.startsAt)} at '
                              '${AttendanceFormat.time(shift.startsAt)}'
                          : 'You are not rostered on a shift right now',
                      body: shift != null
                          ? 'Clocking in opens at '
                              '${AttendanceFormat.time(shift.opensAt)}.'
                          : 'Clocking in follows the rota. If you worked hours '
                              'nobody rostered, ask a manager to add them.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  const ManualEntryFieldLabel('Who'),
                  _ReadOnlyField(
                    icon: Icons.person_outline_rounded,
                    value: _session.displayName.isNotEmpty
                        ? _session.displayName
                        : (_session.email.isNotEmpty ? _session.email : 'You'),
                  ),
                  ManualEntryHelperText('Clocking $_mode as yourself.'),
                  const SizedBox(height: 16),
                  if (open != null) ...[
                    const ManualEntryFieldLabel('Where'),
                    _ReadOnlyField(
                      icon: Icons.place_outlined,
                      value: open.residenceName ??
                          residenceName ??
                          'Your residence',
                    ),
                    const ManualEntryHelperText(
                      'Where you clocked in — a shift is signed off at the '
                      'home it was started at.',
                    ),
                  ] else ...[
                    const ManualEntryFieldLabel('Where', required: true),
                    ManualEntryDropdownField(
                      key: const ValueKey('attendance-clock-where'),
                      value: residenceName,
                      placeholder: 'Choose a residence',
                      onTap: _pickResidence,
                    ),
                    if (shift?.residenceName != null)
                      ManualEntryHelperText(
                        'Rostered on ${shift!.residenceName}',
                      ),
                  ],
                  if (widget.clockOut && shift != null) ...[
                    const SizedBox(height: 16),
                    _EarlyLeaveBox(
                      endsAt: shift.endsAt,
                      reason: _earlyReason,
                      onPickReason: _pickEarlyReason,
                      notesController: _notesController,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _LocationRow(location: _location, error: _locationError),
                  const SizedBox(height: 16),
                  Text('Photo', style: _text(12.5, FontWeight.w500)),
                  const SizedBox(height: 8),
                  _photoSection(),
                  const SizedBox(height: 6),
                  const ManualEntryHelperText(
                    'Kept as evidence of who was here and when. Nothing '
                    'compares the face to anything.',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: const ValueKey('attendance-clock-submit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                    ),
                    onPressed: _saving || !_canSubmit ? null : _submit,
                    child: Text(_saving ? 'Saving…' : title),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoSection() {
    final error = _cameraError;
    if (error != null) {
      return _MutedBox('$error — clocking in without a photo is allowed.');
    }
    final photo = _photoPath;
    if (photo != null) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(photo),
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 140,
                width: 100,
                child: Icon(Icons.image_outlined),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _photoPath = null),
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Take another'),
          ),
        ],
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: const ValueKey('attendance-clock-photo'),
        onPressed: _takePhoto,
        icon: const Icon(Icons.photo_camera_outlined, size: 15),
        label: const Text('Take the photo'),
      ),
    );
  }

  Future<void> _pickResidence() async {
    final picked = await showAttendanceOptionSheet<ManualEntryResidenceOption>(
      context,
      title: 'Where',
      options: widget.residences,
      labelOf: (r) => r.name,
    );
    if (picked != null) setState(() => _residenceId = picked.value.id);
  }

  Future<void> _pickEarlyReason() async {
    final picked = await showAttendanceOptionSheet<(String, String)>(
      context,
      title: 'Why are you leaving early?',
      options: earlyDepartureReasons,
      labelOf: (r) => r.$2,
    );
    if (picked != null) setState(() => _earlyReason = picked.value.$1);
  }
}

TextStyle _text(
  double size,
  FontWeight weight, [
  Color color = AppColors.textHeading,
]) =>
    TextStyle(
      fontFamily: 'Outfit',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
    );

class _WarningBox extends StatelessWidget {
  final String title;
  final String body;

  const _WarningBox({required this.title, required this.body});

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
          Text(title, style: _text(12.5, FontWeight.w600, AppColors.primaryNavy)),
          const SizedBox(height: 4),
          Text(body, style: _text(11.5, FontWeight.w400, AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ReadOnlyField({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: _text(14, FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarlyLeaveBox extends StatelessWidget {
  final DateTime endsAt;
  final String? reason;
  final VoidCallback onPickReason;
  final TextEditingController notesController;

  const _EarlyLeaveBox({
    required this.endsAt,
    required this.reason,
    required this.onPickReason,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final reasonLabel = earlyDepartureReasons
        .where((r) => r.$1 == reason)
        .map((r) => r.$2)
        .firstOrNull;
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
            style: _text(12.5, FontWeight.w600, AppColors.primaryNavy),
          ),
          const SizedBox(height: 4),
          Text(
            'Only kept if you are actually finishing early.',
            style: _text(11.5, FontWeight.w400, AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          const ManualEntryFieldLabel('Why are you leaving early?'),
          ManualEntryDropdownField(
            value: reasonLabel,
            placeholder: 'Choose a reason (optional)',
            onTap: onPickReason,
          ),
          const SizedBox(height: 10),
          ManualEntryTextField(
            controller: notesController,
            hint: 'Anything worth recording',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final ClockLocation? location;
  final String? error;

  const _LocationRow({this.location, this.error});

  @override
  Widget build(BuildContext context) {
    final found = location;
    Widget pill(String label, Color fg, Color bg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: _text(11, FontWeight.w600, fg)),
        );

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
            pill('Location found', AppColors.activeGreen,
                AppColors.activeBackground),
            Text(
              'accurate to about ${found.accuracyMeters} m',
              style: _text(12.5, FontWeight.w400, AppColors.textSecondary),
            ),
          ] else if (error != null) ...[
            pill('No location', AppColors.urgentAmber,
                AppColors.urgentBackground),
            Text(
              '$error — the record will say the position was not provided, '
              'and the clock-in still goes through.',
              style: _text(12.5, FontWeight.w400, AppColors.textSecondary),
            ),
          ] else
            Text(
              'Finding your location…',
              style: _text(12.5, FontWeight.w400, AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _MutedBox extends StatelessWidget {
  final String text;

  const _MutedBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: _text(13, FontWeight.w400, AppColors.textSecondary)),
    );
  }
}

/// Opens the clock sheet; resolves `true` once the clock action saved.
Future<bool?> openAttendanceClock({
  required bool clockOut,
  OpenAttendance? openAttendance,
  List<ManualEntryResidenceOption> residences = const [],
  String? defaultResidenceId,
}) {
  return Get.to<bool>(
        () => AttendanceClockPage(
          clockOut: clockOut,
          openAttendance: openAttendance,
          residences: residences,
          defaultResidenceId: defaultResidenceId,
        ),
        fullscreenDialog: true,
      ) ??
      Future.value();
}
