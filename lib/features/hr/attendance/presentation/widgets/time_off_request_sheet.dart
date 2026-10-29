import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../../domain/entities/time_off_request.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'manual_entry/manual_entry_fields.dart';

/// Result of [showTimeOffRequestSheet].
typedef TimeOffRequestDraft = ({
  TimeOffType type,
  String startDate,
  String endDate,
  String? staffId,
  String? reason,
});

Future<TimeOffRequestDraft?> showTimeOffRequestSheet({
  required BuildContext context,
  required bool pickStaff,
  AttendanceRepository? repository,
  String? defaultStaffId,
  String? defaultStaffName,
}) {
  assert(!pickStaff || repository != null, 'repository required when pickStaff');
  return showAppBottomSheet<TimeOffRequestDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TimeOffRequestSheet(
      repository: repository,
      pickStaff: pickStaff,
      defaultStaffId: defaultStaffId,
      defaultStaffName: defaultStaffName,
    ),
  );
}

class _TimeOffRequestSheet extends StatefulWidget {
  final AttendanceRepository? repository;
  final bool pickStaff;
  final String? defaultStaffId;
  final String? defaultStaffName;

  const _TimeOffRequestSheet({
    required this.pickStaff,
    this.repository,
    this.defaultStaffId,
    this.defaultStaffName,
  });

  @override
  State<_TimeOffRequestSheet> createState() => _TimeOffRequestSheetState();
}

class _TimeOffRequestSheetState extends State<_TimeOffRequestSheet> {
  final _reason = TextEditingController();
  final _staffSearch = TextEditingController();
  TimeOffType _type = TimeOffType.annualLeave;
  DateTime? _start;
  DateTime? _end;
  ManualEntryStaffOption? _staff;
  List<ManualEntryStaffOption> _staffHits = const [];
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final id = widget.defaultStaffId;
    if (id != null && id.isNotEmpty) {
      final name = widget.defaultStaffName ?? 'Staff';
      _staff = ManualEntryStaffOption(
        id: id,
        name: name,
        detail: '',
        initials: _initials(name),
      );
      _staffSearch.text = name;
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    _staffSearch.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length.clamp(1, 2)).toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String? _dateLabel(DateTime? d) {
    if (d == null) return null;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = (start ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.secondaryTeal,
                  onPrimary: Colors.white,
                  surface: AppColors.surfaceWhite,
                  onSurface: AppColors.textHeading,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end != null && _end!.isBefore(_start!)) _end = _start;
      } else {
        _end = DateTime(picked.year, picked.month, picked.day);
        if (_start != null && _end!.isBefore(_start!)) _start = _end;
      }
      _error = null;
    });
  }

  Future<void> _searchStaff(String query) async {
    final repo = widget.repository;
    final q = query.trim();
    if (repo == null || q.length < 2) {
      setState(() {
        _staffHits = const [];
        if (q.isEmpty) _staff = null;
      });
      return;
    }
    setState(() => _searching = true);
    final result = await repo.searchStaff(search: q);
    if (!mounted) return;
    result.when(
      success: (rows) => setState(() {
        _staffHits = rows;
        _searching = false;
      }),
      failure: (_) => setState(() {
        _staffHits = const [];
        _searching = false;
      }),
    );
  }

  Future<void> _pickType() async {
    final picked = await showAppBottomSheet<TimeOffType>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Text(
                    'Leave type',
                    style: handoverText(sheetContext, 16, weight: FontWeight.w700),
                  ),
                ),
                for (final t in TimeOffType.values)
                  ListTile(
                    key: ValueKey('time-off-type-${t.name}'),
                    title: Text(
                      t.label,
                      style: handoverText(
                        sheetContext,
                        14,
                        weight: FontWeight.w500,
                      ),
                    ),
                    trailing: t == _type
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.secondaryTeal,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(t),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _type = picked);
  }

  void _submit() {
    if (widget.pickStaff && (_staff == null || _staff!.id.isEmpty)) {
      setState(() => _error = 'Select a staff member');
      return;
    }
    if (_start == null || _end == null) {
      setState(() => _error = 'Start and end dates are required');
      return;
    }
    Navigator.of(context).pop((
      type: _type,
      startDate: _iso(_start!),
      endDate: _iso(_end!),
      staffId: widget.pickStaff ? _staff?.id : null,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text(
                'Request Time Off',
                style: handoverText(context, 18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the leave type and the dates you need off.',
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              if (widget.pickStaff) ...[
                const ManualEntryFieldLabel('Staff member', required: true),
                ManualEntrySearchField(
                  controller: _staffSearch,
                  hint: 'Search staff…',
                  onChanged: _searchStaff,
                ),
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.secondaryTeal,
                      backgroundColor: AppColors.filterButtonBackground,
                    ),
                  ),
                if (_staffHits.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      border: Border.all(color: AppColors.searchBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _staffHits.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.cardBorder,
                      ),
                      itemBuilder: (context, i) {
                        final s = _staffHits[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            s.name,
                            style: handoverText(
                              context,
                              13.5,
                              weight: FontWeight.w600,
                            ),
                          ),
                          subtitle: s.detail.isEmpty
                              ? null
                              : Text(
                                  s.detail,
                                  style: handoverText(
                                    context,
                                    12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                          onTap: () => setState(() {
                            _staff = s;
                            _staffSearch.text = s.name;
                            _staffHits = const [];
                            _error = null;
                          }),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
              const ManualEntryFieldLabel('Type', required: true),
              ManualEntryDropdownField(
                key: const ValueKey('time-off-type'),
                value: _type.label,
                placeholder: 'Select leave type',
                onTap: _pickType,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ManualEntryFieldLabel(
                          'Start date',
                          required: true,
                        ),
                        ManualEntryDateTimeField(
                          value: _dateLabel(_start),
                          placeholder: 'Pick a date',
                          onTap: () => _pickDate(start: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ManualEntryFieldLabel(
                          'End date',
                          required: true,
                        ),
                        ManualEntryDateTimeField(
                          value: _dateLabel(_end),
                          placeholder: 'Pick a date',
                          onTap: () => _pickDate(start: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const ManualEntryFieldLabel('Reason (optional)'),
              ManualEntryTextField(
                key: const ValueKey('time-off-reason'),
                controller: _reason,
                hint: 'Add a short note for your manager…',
                maxLines: 3,
              ),
              ManualEntryErrorText(_error),
              const SizedBox(height: 18),
              FilledButton(
                key: const ValueKey('time-off-submit'),
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.secondaryTeal.withValues(alpha: 0.4),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Submit request',
                  style: handoverText(
                    context,
                    14.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
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
