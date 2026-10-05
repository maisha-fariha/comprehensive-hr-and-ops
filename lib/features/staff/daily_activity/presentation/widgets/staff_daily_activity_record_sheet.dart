import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/staff_daily_activity_option.dart';
import '../../domain/repositories/staff_daily_activity_repository.dart';
import '../../../../../core/media/app_file_picker.dart';

InputDecoration _fieldDecoration({String? hint, Widget? prefixIcon}) {
  const radius = 12.0;
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: AppColors.textMuted,
    ),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: AppColors.surfaceWhite,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.criticalRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.criticalRed, width: 1.4),
    ),
  );
}

const _fieldTextStyle = TextStyle(
  fontFamily: 'Outfit',
  fontWeight: FontWeight.w500,
  fontSize: 14,
  color: AppColors.textHeading,
);

/// Web-parity "Add Daily Activity" sheet with required-field validation.
class StaffDailyActivityRecordSheet extends StatefulWidget {
  final List<StaffDailyActivityPersonOption> clients;
  final List<StaffDailyActivityPersonOption> staff;
  final String? initialClientId;
  final String? currentStaffId;

  const StaffDailyActivityRecordSheet({
    super.key,
    required this.clients,
    required this.staff,
    this.initialClientId,
    this.currentStaffId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<StaffDailyActivityPersonOption> clients,
    required List<StaffDailyActivityPersonOption> staff,
    String? initialClientId,
    String? currentStaffId,
  }) {
    final height = MediaQuery.sizeOf(context).height;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: height * 0.94,
        child: StaffDailyActivityRecordSheet(
          clients: clients,
          staff: staff,
          initialClientId: initialClientId,
          currentStaffId: currentStaffId,
        ),
      ),
    );
  }

  @override
  State<StaffDailyActivityRecordSheet> createState() =>
      _StaffDailyActivityRecordSheetState();
}

class _StaffDailyActivityRecordSheetState
    extends State<StaffDailyActivityRecordSheet> {
  final _repo = GetIt.instance<StaffDailyActivityRepository>();
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _clientSearch = TextEditingController();
  final _staffSearch = TextEditingController();

  String? _clientId;
  String _activityType = 'care_activity';
  String _status = 'completed';
  String? _recordedByStaffId;
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  String? _uploadPath;
  String? _uploadName;
  String? _uploadedUrl;
  bool _uploading = false;
  bool _submitting = false;
  String? _banner;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialClientId;
    if (initial != null &&
        widget.clients.any((c) => c.id == initial)) {
      _clientId = initial;
      final match = widget.clients.firstWhere((c) => c.id == initial);
      _clientSearch.text = match.name;
    }
    final self = widget.currentStaffId;
    if (self != null && widget.staff.any((s) => s.id == self)) {
      _recordedByStaffId = self;
      final match = widget.staff.firstWhere((s) => s.id == self);
      _staffSearch.text = match.name;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _notes.dispose();
    _clientSearch.dispose();
    _staffSearch.dispose();
    super.dispose();
  }

  List<StaffDailyActivityPersonOption> _filtered(
    List<StaffDailyActivityPersonOption> source,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _pickFile() async {
    final picked = await AppFilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: false,
    );
    final file = picked?.files.single;
    if (file?.path == null || file!.path!.isEmpty) return;
    setState(() {
      _uploadPath = file.path;
      _uploadName = file.name;
      _uploadedUrl = null;
      _banner = null;
    });
  }

  Future<String?> _ensureUpload() async {
    if (_uploadedUrl != null) return _uploadedUrl;
    final path = _uploadPath;
    if (path == null || path.isEmpty) return null;
    setState(() => _uploading = true);
    final result = await _repo.uploadDocument(
      localPath: path,
      fileName: _uploadName ?? 'activity-document',
    );
    if (!mounted) return null;
    setState(() => _uploading = false);
    return result.when(
      success: (url) {
        _uploadedUrl = url;
        return url;
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not upload document',
        );
        return null;
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _banner = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _banner = 'Fill every required field before saving.');
      return;
    }
    final clientId = _clientId;
    if (clientId == null || clientId.isEmpty) {
      setState(() => _banner = 'Select a resident.');
      return;
    }

    setState(() => _submitting = true);
    String? fileUrl;
    if (_uploadPath != null) {
      fileUrl = await _ensureUpload();
      if (fileUrl == null && mounted) {
        setState(() => _submitting = false);
        return;
      }
    }

    final ymd =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    String? occurredAt;
    final time = _time;
    if (time != null) {
      final local = DateTime(
        _date.year,
        _date.month,
        _date.day,
        time.hour,
        time.minute,
      );
      occurredAt = local.toUtc().toIso8601String();
    }

    final result = await _repo.recordActivity(
      clientId: clientId,
      activityDate: ymd,
      activityType: _activityType,
      status: _status,
      description: _description.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      recordedByStaffId: _recordedByStaffId,
      occurredAt: occurredAt,
      attachments: fileUrl == null
          ? null
          : [
              {
                'fileUrl': fileUrl,
                'fileName': ?_uploadName,
              },
            ],
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not save activity',
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        children: [
          _Header(onClose: () => Navigator.of(context).pop(false)),
          if (_banner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.criticalBackgroundSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _banner!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.criticalRed,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  _Label(text: 'Select Resident', required: true),
                  _PersonSearchField(
                    controller: _clientSearch,
                    hint: 'Search select resident...',
                    helper: 'Type to search select resident',
                    options: _filtered(widget.clients, _clientSearch.text),
                    selectedId: _clientId,
                    onSelected: (option) {
                      setState(() {
                        _clientId = option.id;
                        _clientSearch.text = option.name;
                      });
                    },
                    onChanged: (_) => setState(() {
                      _clientId = null;
                    }),
                    validator: (_) =>
                        _clientId == null ? 'Resident is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Activity Type', required: true),
                  DropdownButtonFormField<String>(
                    key: const Key('staff-daily-activity-type'),
                    initialValue: _activityType,
                    decoration: _fieldDecoration(),
                    style: _fieldTextStyle,
                    items: [
                      for (final entry in StaffDailyActivityEnums.activityTypes)
                        DropdownMenuItem(
                          value: entry.$1,
                          child: Text(entry.$2),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _activityType = v ?? 'care_activity'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Activity type is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'How it went', required: true),
                  DropdownButtonFormField<String>(
                    key: const Key('staff-daily-activity-status'),
                    initialValue: _status,
                    decoration: _fieldDecoration(),
                    style: _fieldTextStyle,
                    items: [
                      for (final entry in StaffDailyActivityEnums.statuses)
                        DropdownMenuItem(
                          value: entry.$1,
                          child: Text(entry.$2),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _status = v ?? 'completed'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'How it went is required' : null,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A refusal or a partial is the one somebody reads',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Activity Description', required: true),
                  TextFormField(
                    key: const Key('staff-daily-activity-description'),
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(
                      hint:
                          'Describe the activity performed or observation recorded...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  const _Label(text: 'Additional Notes (Optional)'),
                  TextFormField(
                    key: const Key('staff-daily-activity-notes'),
                    controller: _notes,
                    minLines: 2,
                    maxLines: 4,
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(
                      hint: 'Add additional observations or comments...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _Label(text: 'Upload Document (Optional)'),
                  _UploadZone(
                    fileName: _uploadName,
                    uploading: _uploading,
                    onTap: _pickFile,
                    onClear: () => setState(() {
                      _uploadPath = null;
                      _uploadName = null;
                      _uploadedUrl = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                  const _Label(text: 'Recorded by'),
                  _PersonSearchField(
                    controller: _staffSearch,
                    hint: 'Search recorded by...',
                    helper: 'Type to search recorded by',
                    options: _filtered(widget.staff, _staffSearch.text),
                    selectedId: _recordedByStaffId,
                    onSelected: (option) {
                      setState(() {
                        _recordedByStaffId = option.id;
                        _staffSearch.text = option.name;
                      });
                    },
                    onChanged: (_) => setState(() {
                      _recordedByStaffId = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Date', required: true),
                  InkWell(
                    key: const Key('staff-daily-activity-date'),
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _fieldDecoration().copyWith(
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                      child: Text(
                        '${_date.day.toString().padLeft(2, '0')}/'
                        '${_date.month.toString().padLeft(2, '0')}/'
                        '${_date.year}',
                        style: _fieldTextStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _Label(text: 'Time (Optional)'),
                  InkWell(
                    key: const Key('staff-daily-activity-time'),
                    onTap: _pickTime,
                    onLongPress: () => setState(() => _time = null),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _fieldDecoration().copyWith(
                        suffixIcon: const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                      child: Text(
                        _time == null
                            ? '--:-- --'
                            : _time!.format(context),
                        style: _time == null
                            ? _fieldTextStyle.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w400,
                              )
                            : _fieldTextStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optional — without it the record is placed to the day',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textHeading,
                        side: const BorderSide(color: AppColors.searchBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: const Key('staff-daily-activity-save'),
                      onPressed: (_submitting || _uploading) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting || _uploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Activity',
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
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Daily Activity',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Separate from the daily log — this is what they did, not how care went.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool required;

  const _Label({required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textHeading,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppColors.criticalRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String helper;
  final List<StaffDailyActivityPersonOption> options;
  final String? selectedId;
  final ValueChanged<StaffDailyActivityPersonOption> onSelected;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const _PersonSearchField({
    required this.controller,
    required this.hint,
    required this.helper,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          style: _fieldTextStyle,
          decoration: _fieldDecoration(
            hint: hint,
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          onChanged: onChanged,
          validator: validator,
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        if (controller.text.trim().isNotEmpty && selectedId == null) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: options.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No matches',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length.clamp(0, 8),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          option.name,
                          style: _fieldTextStyle,
                        ),
                        subtitle: option.subtitle == null
                            ? null
                            : Text(
                                option.subtitle!,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _UploadZone extends StatelessWidget {
  final String? fileName;
  final bool uploading;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _UploadZone({
    required this.fileName,
    required this.uploading,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.searchBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 28,
              color: AppColors.secondaryTeal,
            ),
            const SizedBox(height: 8),
            Text(
              fileName ?? 'Click to upload or drag & drop',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PDF, DOC, JPG or PNG — up to 15MB',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            if (fileName != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: uploading ? null : onClear,
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
