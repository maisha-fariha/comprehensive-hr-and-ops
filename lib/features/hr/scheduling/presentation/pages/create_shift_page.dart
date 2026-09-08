import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/shift_break_duration_option.dart';
import '../../domain/entities/shift_coverage_level_option.dart';
import '../../domain/entities/shift_qualification_option.dart';
import '../../domain/entities/shift_reminder_option.dart';
import '../../domain/entities/shift_residence_option.dart';
import '../../domain/entities/shift_staff_option.dart';
import '../../domain/entities/shift_type_option.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../widgets/create_shift/create_shift_header.dart';
import '../widgets/create_shift/create_shift_info_form.dart';
import '../widgets/create_shift/create_shift_notifications_form.dart';
import '../widgets/create_shift/create_shift_open_shift_form.dart';
import '../widgets/create_shift/create_shift_recurring_form.dart';
import '../widgets/create_shift/create_shift_staff_assignment_form.dart';

/// "Add New Shift" screen matching the design reference.
class CreateShiftPage extends StatefulWidget {
  const CreateShiftPage({super.key});

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  CreateShiftTab _tab = CreateShiftTab.shiftInformation;
  late final TextEditingController _peopleNeededController;
  late final TextEditingController _titleController;
  late final TextEditingController _staffSearchController;
  late final TextEditingController _notificationMessageController;

  late final SchedulingRepository _repository;
  late final UserSession _session;
  bool _isSubmitting = false;

  final List<ShiftResidenceOption> _residences = [];
  ShiftResidenceOption? _selectedResidence;
  bool _isLoadingResidences = false;

  static const List<ShiftTypeOption> _shiftTypes = ShiftTypeOption.predefined;
  ShiftTypeOption? _selectedShiftType = ShiftTypeOption.predefined.first;

  final List<ShiftQualificationOption> _qualifications = [];
  ShiftQualificationOption? _selectedQualification;
  bool _isLoadingQualifications = false;

  static const List<ShiftBreakDurationOption> _breakDurations =
      ShiftBreakDurationOption.predefined;
  ShiftBreakDurationOption? _selectedBreakDuration =
      ShiftBreakDurationOption.defaultOption;

  static const List<ShiftCoverageLevelOption> _coverageLevels =
      ShiftCoverageLevelOption.predefined;
  ShiftCoverageLevelOption? _selectedCoverageLevel =
      ShiftCoverageLevelOption.defaultOption;

  final List<ShiftStaffOption> _staff = [];
  final Set<String> _selectedStaffIds = {};
  bool _isLoadingStaff = false;
  String _staffSearchError = '';
  Timer? _staffSearchDebounce;
  int _staffSearchRequestId = 0;
  static const Duration _staffSearchDebounceDuration =
      Duration(milliseconds: 350);

  DateTime _shiftDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);

  bool _isOpenShift = false;
  bool _isRecurring = false;
  bool _notifyAssignedStaff = true;
  ShiftReminderOption _selectedReminder = ShiftReminderOption.defaultOption;
  static const List<ShiftReminderOption> _reminders =
      ShiftReminderOption.predefined;

  @override
  void initState() {
    super.initState();
    _peopleNeededController = TextEditingController(text: '1');
    _titleController = TextEditingController();
    _staffSearchController = TextEditingController();
    _notificationMessageController = TextEditingController();
    _repository = GetIt.instance<SchedulingRepository>();
    _session = Get.find<UserSession>();
    final now = DateTime.now();
    _shiftDate = DateTime(now.year, now.month, now.day);
    _applyShiftTypeTimes(_selectedShiftType);
    _seedResidenceFromSession();
    _loadResidences();
    _loadQualifications();
    _loadStaff();
  }

  void _applyShiftTypeTimes(ShiftTypeOption? option) {
    if (option == null || !option.hasPresetTimes) return;
    _startTime = TimeOfDay(
      hour: option.startHour!,
      minute: option.startMinute!,
    );
    _endTime = TimeOfDay(
      hour: option.endHour!,
      minute: option.endMinute!,
    );
  }

  void _seedResidenceFromSession() {
    final name = _session.residenceName;
    final id = _session.residenceId;
    if (name == null || name.isEmpty) return;
    _selectedResidence = ShiftResidenceOption(
      id: id ?? name,
      name: name,
    );
  }

  Future<void> _loadResidences() async {
    if (_isLoadingResidences) return;
    setState(() => _isLoadingResidences = true);
    final result = await _repository.getResidences();
    if (!mounted) return;
    setState(() => _isLoadingResidences = false);

    result.when(
      success: (data) {
        setState(() {
          _residences
            ..clear()
            ..addAll(data);
          final currentId = _selectedResidence?.id;
          if (currentId != null) {
            for (final option in data) {
              if (option.id == currentId) {
                _selectedResidence = option;
                break;
              }
            }
          }
        });
      },
      failure: (error) {
        AppSnackbar.show('Could not load residences', error.message);
      },
    );
  }

  Future<void> _pickResidence() async {
    if (_residences.isEmpty && !_isLoadingResidences) {
      await _loadResidences();
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<ShiftResidenceOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              if (_isLoadingResidences && _residences.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                );
              }
              if (_residences.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No residences available.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _loadResidences();
                          if (context.mounted) setSheetState(() {});
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Select residence',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  for (final option in _residences)
                    ListTile(
                      title: Text(
                        option.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHeading,
                        ),
                      ),
                      trailing: _selectedResidence?.id == option.id
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.secondaryTeal,
                            )
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    ),
                ],
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedResidence = selected;
        _selectedQualification = null;
        _qualifications.clear();
      });
      _loadQualifications();
      _loadStaff();
    }
  }

  Future<void> _loadQualifications() async {
    if (_isLoadingQualifications) return;
    setState(() => _isLoadingQualifications = true);
    final result = await _repository.getQualifications(
      residenceId: _selectedResidence?.id,
    );
    if (!mounted) return;
    setState(() => _isLoadingQualifications = false);

    result.when(
      success: (data) {
        setState(() {
          _qualifications
            ..clear()
            ..addAll(data);
          final currentId = _selectedQualification?.id;
          if (currentId != null) {
            ShiftQualificationOption? matched;
            for (final option in data) {
              if (option.id == currentId) {
                matched = option;
                break;
              }
            }
            _selectedQualification = matched;
          }
        });
      },
      failure: (error) {
        AppSnackbar.show('Could not load qualifications', error.message);
      },
    );
  }

  Future<void> _pickShiftType() async {
    final selected = await showModalBottomSheet<ShiftTypeOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select shift type',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              for (final option in _shiftTypes)
                ListTile(
                  title: Text(
                    option.label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  trailing: _selectedShiftType?.id == option.id
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedShiftType = selected;
        _applyShiftTypeTimes(selected);
      });
    }
  }

  Future<void> _pickQualification() async {
    if (_qualifications.isEmpty && !_isLoadingQualifications) {
      await _loadQualifications();
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<ShiftQualificationOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              if (_isLoadingQualifications && _qualifications.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                );
              }
              if (_qualifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No qualifications available.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _loadQualifications();
                          if (context.mounted) setSheetState(() {});
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Select qualification',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  for (final option in _qualifications)
                    ListTile(
                      title: Text(
                        option.label,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHeading,
                        ),
                      ),
                      trailing: _selectedQualification?.id == option.id
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.secondaryTeal,
                            )
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    ),
                ],
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedQualification = selected);
      _loadStaff();
    }
  }

  Future<void> _pickBreakDuration() async {
    final selected = await showModalBottomSheet<ShiftBreakDurationOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select break duration',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              for (final option in _breakDurations)
                ListTile(
                  title: Text(
                    option.label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  trailing: _selectedBreakDuration?.id == option.id
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedBreakDuration = selected);
    }
  }

  Future<void> _pickCoverageLevel() async {
    final selected = await showModalBottomSheet<ShiftCoverageLevelOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select coverage level',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              for (final option in _coverageLevels)
                ListTile(
                  title: Text(
                    option.label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  trailing: _selectedCoverageLevel?.id == option.id
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedCoverageLevel = selected);
    }
  }

  void _onStaffSearchChanged(String value) {
    _staffSearchDebounce?.cancel();
    _staffSearchDebounce = Timer(
      _staffSearchDebounceDuration,
      () => _loadStaff(value),
    );
  }

  Future<void> _loadStaff([String? query]) async {
    final requestId = ++_staffSearchRequestId;
    setState(() {
      _isLoadingStaff = true;
      _staffSearchError = '';
    });

    final result = await _repository.searchStaff(
      search: query ?? _staffSearchController.text,
      residenceId: _selectedResidence?.id,
      categoryId: _selectedQualification?.id,
    );
    if (!mounted || requestId != _staffSearchRequestId) return;

    setState(() => _isLoadingStaff = false);
    result.when(
      success: (data) {
        setState(() {
          _staff
            ..clear()
            ..addAll(data);
          _staffSearchError = '';
        });
      },
      failure: (error) {
        setState(() {
          _staff.clear();
          _staffSearchError = error.message;
        });
        AppSnackbar.show('Could not load staff', error.message);
      },
    );
  }

  void _toggleStaff(String id) {
    setState(() {
      if (_selectedStaffIds.contains(id)) {
        _selectedStaffIds.remove(id);
      } else {
        _selectedStaffIds.add(id);
      }
    });
  }

  Future<void> _pickShiftDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _shiftDate.isBefore(today) ? today : _shiftDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.secondaryTeal,
                ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _shiftDate = selected);
  }

  Future<void> _pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.secondaryTeal,
                ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startTime = selected;
      _selectedShiftType = const ShiftTypeOption(
        id: 'custom',
        name: 'Custom',
        label: 'Custom',
      );
    });
  }

  Future<void> _pickEndTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.secondaryTeal,
                ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _endTime = selected;
      _selectedShiftType = const ShiftTypeOption(
        id: 'custom',
        name: 'Custom',
        label: 'Custom',
      );
    });
  }

  String _formatShiftDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatShiftTime(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickReminder() async {
    final selected = await showModalBottomSheet<ShiftReminderOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select reminder',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              for (final option in _reminders)
                ListTile(
                  title: Text(
                    option.label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  trailing: _selectedReminder.id == option.id
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedReminder = selected);
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Map<String, dynamic> _buildCreatePayload() {
    final startsAt = _combineDateAndTime(_shiftDate, _startTime);
    var endsAt = _combineDateAndTime(_shiftDate, _endTime);
    if (!endsAt.isAfter(startsAt)) {
      endsAt = endsAt.add(const Duration(days: 1));
    }

    final requiredStaffCount =
        int.tryParse(_peopleNeededController.text.trim()) ?? 1;
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : '${_selectedShiftType?.name ?? 'Shift'} Care Shift';
    final notificationMessage = _notificationMessageController.text.trim();
    final reminderMinutes = _selectedReminder.minutesBefore;
    final categoryId = _selectedQualification?.id;

    final payload = <String, dynamic>{
      'residenceId': _selectedResidence!.id,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'title': title,
      'shiftType': _selectedShiftType?.id ?? 'custom',
      'coverageLevel': _selectedCoverageLevel?.id ?? 'standard',
      'breakMinutes': _selectedBreakDuration?.minutes ?? 0,
      'requiredStaffCount': requiredStaffCount,
      if (categoryId != null && categoryId.isNotEmpty)
        'requiredCategoryId': categoryId,
      'staffIds': _selectedStaffIds.toList(),
      'notifyAssignedStaff': _notifyAssignedStaff,
      'reminderMinutesBefore': ?reminderMinutes,
      if (notificationMessage.isNotEmpty)
        'notificationMessage': notificationMessage,
    };

    if (_isOpenShift) {
      final closesAt = DateTime(
        _shiftDate.year,
        _shiftDate.month,
        _shiftDate.day,
      ).subtract(const Duration(minutes: 1));
      payload['biddingConfig'] = {
        'eligibleCategoryIds': [
          if (categoryId != null && categoryId.isNotEmpty) categoryId,
        ],
        'biddingClosesAt': closesAt.toUtc().toIso8601String(),
        'maxBids': 5,
        'priority': 'medium',
        'awardMethod': 'manual',
        'noteToBidders': 'Open to all qualified care workers.',
      };
    }

    if (_isRecurring) {
      payload['recurrence'] = {
        'occurrences': 4,
        'intervalDays': 7,
        'weekdays': [_shiftDate.weekday],
      };
    }

    return payload;
  }

  Future<void> _createShift() async {
    if (_isSubmitting) return;

    final residenceId = _selectedResidence?.id.trim() ?? '';
    if (residenceId.isEmpty) {
      AppSnackbar.show('Missing details', 'Please select a residence.');
      setState(() => _tab = CreateShiftTab.shiftInformation);
      return;
    }

    if (_selectedShiftType == null) {
      AppSnackbar.show('Missing details', 'Please select a shift type.');
      setState(() => _tab = CreateShiftTab.shiftInformation);
      return;
    }

    final requiredStaffCount =
        int.tryParse(_peopleNeededController.text.trim());
    if (requiredStaffCount == null || requiredStaffCount < 1) {
      AppSnackbar.show(
        'Missing details',
        'People needed must be at least 1.',
      );
      setState(() => _tab = CreateShiftTab.shiftInformation);
      return;
    }

    final startsAt = _combineDateAndTime(_shiftDate, _startTime);
    var endsAt = _combineDateAndTime(_shiftDate, _endTime);
    if (!endsAt.isAfter(startsAt)) {
      endsAt = endsAt.add(const Duration(days: 1));
    }
    if (!endsAt.isAfter(startsAt)) {
      AppSnackbar.show('Invalid times', 'End time must be after start time.');
      setState(() => _tab = CreateShiftTab.shiftInformation);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.createShift(_buildCreatePayload());
      if (!mounted) return;

      final created = result.when(
        success: (_) => true,
        failure: (error) {
          AppSnackbar.show('Could not create shift', error.message);
          return false;
        },
      );
      if (created && mounted) {
        Navigator.of(context).pop(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.show(
            'Shift created',
            'The shift was created successfully.',
          );
        });
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Could not create shift',
        error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _staffSearchDebounce?.cancel();
    _peopleNeededController.dispose();
    _titleController.dispose();
    _staffSearchController.dispose();
    _notificationMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    CreateShiftHeader(
                      onClose: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    CreateShiftStepTabs(
                      selected: _tab,
                      onSelected: _isSubmitting
                          ? null
                          : (tab) {
                              setState(() => _tab = tab);
                              if (tab == CreateShiftTab.staffAssignment &&
                                  _staff.isEmpty &&
                                  !_isLoadingStaff) {
                                _loadStaff();
                              }
                            },
                    ),
                    CreateShiftCompletionBar(
                      currentStep: _tab.index + 1,
                      totalSteps: CreateShiftTab.values.length,
                      percent: ((_tab.index + 1) /
                              CreateShiftTab.values.length) *
                          100,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _bodyForTab(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CreateShiftFooter(
              isSubmitting: _isSubmitting,
              onCancel:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              onCreate: _isSubmitting ? null : () => _createShift(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyForTab() {
    switch (_tab) {
      case CreateShiftTab.shiftInformation:
        return CreateShiftInfoForm(
          peopleNeededController: _peopleNeededController,
          titleController: _titleController,
          residenceValue: _selectedResidence?.name,
          isLoadingResidences: _isLoadingResidences,
          onResidenceTap: _pickResidence,
          shiftTypeValue: _selectedShiftType?.label,
          onShiftTypeTap: _pickShiftType,
          shiftDateValue: _formatShiftDate(_shiftDate),
          onShiftDateTap: _pickShiftDate,
          startTimeValue: _formatShiftTime(_startTime),
          onStartTimeTap: _pickStartTime,
          endTimeValue: _formatShiftTime(_endTime),
          onEndTimeTap: _pickEndTime,
          qualificationValue: _selectedQualification?.label,
          isLoadingQualifications: _isLoadingQualifications,
          onQualificationTap: _pickQualification,
          breakDurationValue: _selectedBreakDuration?.label,
          onBreakDurationTap: _pickBreakDuration,
          coverageLevelValue: _selectedCoverageLevel?.label,
          onCoverageLevelTap: _pickCoverageLevel,
        );
      case CreateShiftTab.staffAssignment:
        return CreateShiftStaffAssignmentForm(
          searchController: _staffSearchController,
          staff: _staff,
          selectedIds: _selectedStaffIds,
          isLoading: _isLoadingStaff,
          errorMessage: _staffSearchError.isEmpty ? null : _staffSearchError,
          onSearchChanged: _onStaffSearchChanged,
          onToggleStaff: _toggleStaff,
          onRetry: _loadStaff,
        );
      case CreateShiftTab.openShift:
        return CreateShiftOpenShiftForm(
          isOpenShift: _isOpenShift,
          onChanged: (value) => setState(() => _isOpenShift = value),
        );
      case CreateShiftTab.recurring:
        return CreateShiftRecurringForm(
          isRecurring: _isRecurring,
          onChanged: (value) => setState(() => _isRecurring = value),
        );
      case CreateShiftTab.notifications:
        return CreateShiftNotificationsForm(
          notifyAssignedStaff: _notifyAssignedStaff,
          onNotifyAssignedStaffChanged: (value) =>
              setState(() => _notifyAssignedStaff = value),
          selectedReminder: _selectedReminder,
          onReminderTap: _pickReminder,
          messageController: _notificationMessageController,
        );
    }
  }
}
