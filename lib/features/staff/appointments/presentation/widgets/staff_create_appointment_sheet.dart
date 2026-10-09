import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_appointment.dart';
import '../controllers/staff_appointments_controller.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

InputDecoration _apptFieldDecoration({String? hint, String? helper}) {
  const radius = 12.0;
  return InputDecoration(
    hintText: hint,
    helperText: helper,
    helperStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w400,
      fontSize: 11.5,
      color: AppColors.textMuted,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: AppColors.textMuted,
    ),
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
  );
}

const _fieldTextStyle = TextStyle(
  fontFamily: 'Outfit',
  fontWeight: FontWeight.w500,
  fontSize: 14,
  color: AppColors.textHeading,
);

Future<void> showStaffCreateAppointmentSheet(
  BuildContext context,
  StaffAppointmentsController controller, {
  StaffAppointment? editing,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateSheet(controller: controller, editing: editing),
  );
}

class _CreateSheet extends StatefulWidget {
  final StaffAppointmentsController controller;
  final StaffAppointment? editing;

  const _CreateSheet({required this.controller, this.editing});

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _purpose = TextEditingController();
  final _notes = TextEditingController();
  final _location = TextEditingController();

  String _type = 'family_visit';
  String? _clientId;
  DateTime? _date;
  TimeOfDay? _time;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _type = editing.type == 'external' ? 'external' : 'family_visit';
      _clientId = editing.clientId.isEmpty ? null : editing.clientId;
      _purpose.text = editing.purpose ?? '';
      _notes.text = editing.notes ?? '';
      _location.text = editing.location ?? '';
      final at = editing.scheduledAt?.toLocal();
      if (at != null) {
        _date = DateTime(at.year, at.month, at.day);
        _time = TimeOfDay(hour: at.hour, minute: at.minute);
      }
    }
  }

  @override
  void dispose() {
    _purpose.dispose();
    _notes.dispose();
    _location.dispose();
    super.dispose();
  }

  List<StaffAppointmentClientOption> get _clients =>
      widget.controller.clients.toList();

  StaffAppointmentClientOption? get _selectedClient {
    final id = _clientId;
    if (id == null) return null;
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  String get _residenceLabel {
    final client = _selectedClient;
    if (client == null) return '—';
    if (client.residenceName.isEmpty) return '—';
    return client.residenceName;
  }

  String get _typeLabel =>
      _type == 'external' ? 'External appointment' : 'Family visit';

  String get _whenLabel {
    if (_date == null || _time == null) return '—';
    final d = _date!;
    final t = _time!;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} · $h:$m';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
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

  Future<void> _submit() async {
    if (_type.isEmpty) {
      setState(() => _error = 'Choose an appointment type');
      return;
    }
    if (_clientId == null || _clientId!.isEmpty) {
      setState(() => _error = 'Select a resident');
      return;
    }
    if (_date == null || _time == null) {
      setState(() => _error = 'Set both date and time');
      return;
    }

    final scheduledAt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    setState(() {
      _submitting = true;
      _error = null;
    });

    final client = _selectedClient;
    final Result<void> result;
    if (_isEdit) {
      result = await widget.controller.updateAppointment(
        widget.editing!.id,
        StaffUpdateAppointmentInput(
          scheduledAt: scheduledAt,
          purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          location:
              _location.text.trim().isEmpty ? null : _location.text.trim(),
          clientId: _clientId,
          residenceId: client?.residenceId,
        ),
      );
    } else {
      result = await widget.controller.createAppointment(
        StaffCreateAppointmentInput(
          type: _type,
          clientId: _clientId!,
          scheduledAt: scheduledAt,
          purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          location:
              _location.text.trim().isEmpty ? null : _location.text.trim(),
          residenceId: client?.residenceId,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) {
        Navigator.pop(context);
        Get.snackbar(
          _isEdit ? 'Updated' : 'Created',
          _isEdit
              ? 'Appointment saved successfully.'
              : 'Appointment saved successfully.',
        );
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.92,
          child: Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.quickActionCreateShiftBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_available_rounded,
                              color: AppColors.secondaryTeal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEdit
                                      ? 'Edit Appointment'
                                      : 'Create Appointment',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      18,
                                    ),
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Book a family visit or external appointment for a resident.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    _Labeled(
                      label: 'Type',
                      required: true,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.filterButtonBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TypeToggle(
                                label: 'Family visit',
                                selected: _type == 'family_visit',
                                onTap: () =>
                                    setState(() => _type = 'family_visit'),
                              ),
                            ),
                            Expanded(
                              child: _TypeToggle(
                                label: 'External appointment',
                                selected: _type == 'external',
                                onTap: () =>
                                    setState(() => _type = 'external'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Resident',
                      required: true,
                      child: DropdownButtonFormField<String>(
                        initialValue: _clientId,
                        isExpanded: true,
                        style: _fieldTextStyle,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                        decoration: _apptFieldDecoration(
                          hint: _clients.isEmpty
                              ? 'No residents available'
                              : 'Select a resident',
                        ),
                        items: [
                          for (final c in _clients)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(c.label),
                            ),
                        ],
                        onChanged: (v) => setState(() => _clientId = v),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Residence',
                      hint: 'Filled from the resident record when available',
                      child: InputDecorator(
                        decoration: _apptFieldDecoration().copyWith(
                          filled: true,
                          fillColor: AppColors.filterButtonBackground,
                          prefixIcon: const Icon(
                            Icons.home_outlined,
                            color: AppColors.textMuted,
                          ),
                        ),
                        child: Text(
                          _residenceLabel,
                          style: _residenceLabel == '—'
                              ? const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.textMuted,
                                )
                              : _fieldTextStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Labeled(
                            label: 'Date',
                            required: true,
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _apptFieldDecoration(
                                  hint: 'Pick date',
                                ).copyWith(
                                  prefixIcon: const Icon(
                                    Icons.event_outlined,
                                    color: AppColors.secondaryTeal,
                                  ),
                                ),
                                child: Text(
                                  _date == null
                                      ? 'Pick date'
                                      : '${_date!.day.toString().padLeft(2, '0')}/'
                                          '${_date!.month.toString().padLeft(2, '0')}/'
                                          '${_date!.year}',
                                  style: _date == null
                                      ? const TextStyle(
                                          fontFamily: 'Outfit',
                                          color: AppColors.textMuted,
                                        )
                                      : _fieldTextStyle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Labeled(
                            label: 'Time',
                            required: true,
                            child: InkWell(
                              onTap: _pickTime,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _apptFieldDecoration(
                                  hint: 'Pick time',
                                ).copyWith(
                                  prefixIcon: const Icon(
                                    Icons.schedule_rounded,
                                    color: AppColors.secondaryTeal,
                                  ),
                                ),
                                child: Text(
                                  _time == null
                                      ? 'Pick time'
                                      : '${_time!.hour.toString().padLeft(2, '0')}:'
                                          '${_time!.minute.toString().padLeft(2, '0')}',
                                  style: _time == null
                                      ? const TextStyle(
                                          fontFamily: 'Outfit',
                                          color: AppColors.textMuted,
                                        )
                                      : _fieldTextStyle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Purpose',
                      hint: 'Recommended',
                      child: TextField(
                        controller: _purpose,
                        style: _fieldTextStyle,
                        decoration: _apptFieldDecoration(
                          hint: 'e.g. GP review, weekend visit',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Location (optional)',
                      child: TextField(
                        controller: _location,
                        style: _fieldTextStyle,
                        decoration: _apptFieldDecoration(
                          hint: 'e.g. Reception, Elm House lounge',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: 'Notes (optional)',
                      child: TextField(
                        controller: _notes,
                        maxLines: 3,
                        style: _fieldTextStyle,
                        decoration: _apptFieldDecoration(
                          hint: 'Anything the care team should know...',
                        ).copyWith(
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LivePreview(
                      typeLabel: _typeLabel,
                      residentLabel: _selectedClient?.label ?? '—',
                      residenceLabel: _residenceLabel,
                      whenLabel: _whenLabel,
                      purpose: _purpose.text.trim().isEmpty
                          ? '—'
                          : _purpose.text.trim(),
                      notes: _notes.text.trim().isEmpty
                          ? '—'
                          : _notes.text.trim(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.criticalBackgroundSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.criticalRed.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.criticalRed,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryTeal,
                              side: const BorderSide(
                                color: AppColors.secondaryTeal,
                              ),
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
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              _submitting
                                  ? 'Saving…'
                                  : (_isEdit
                                      ? 'Save Changes'
                                      : 'Create Appointment'),
                              style: const TextStyle(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceWhite : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.secondaryTeal, width: 1.2)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.shadowNavy.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final String? hint;
  final bool required;
  final Widget child;

  const _Labeled({
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textHeading,
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.criticalRed,
                  ),
                ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _LivePreview extends StatelessWidget {
  final String typeLabel;
  final String residentLabel;
  final String residenceLabel;
  final String whenLabel;
  final String purpose;
  final String notes;

  const _LivePreview({
    required this.typeLabel,
    required this.residentLabel,
    required this.residenceLabel,
    required this.whenLabel,
    required this.purpose,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.infoBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Live preview',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PreviewRow(label: 'Type', value: typeLabel),
          _PreviewRow(label: 'Resident', value: residentLabel),
          _PreviewRow(label: 'Residence', value: residenceLabel),
          _PreviewRow(label: 'When', value: whenLabel),
          _PreviewRow(label: 'Purpose', value: purpose),
          _PreviewRow(label: 'Notes', value: notes),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
