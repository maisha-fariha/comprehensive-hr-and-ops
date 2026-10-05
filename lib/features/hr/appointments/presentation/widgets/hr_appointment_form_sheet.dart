import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../controllers/hr_appointments_controller.dart';
import '../hr_appointments_labels.dart';
import 'hr_appointment_day_log_panel.dart';
import 'hr_appointments_common.dart';

/// "Create Appointment" / "Edit Appointment". Resolves true once saved.
Future<bool> showHrAppointmentFormSheet(
  BuildContext context, {
  required HrAppointmentsController controller,
  HrAppointment? editing,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HrAppointmentFormSheet(controller: controller, editing: editing),
  );
  return saved == true;
}

class HrAppointmentFormSheet extends StatefulWidget {
  final HrAppointmentsController controller;
  final HrAppointment? editing;

  const HrAppointmentFormSheet({super.key, required this.controller, this.editing});

  @override
  State<HrAppointmentFormSheet> createState() => _HrAppointmentFormSheetState();
}

class _HrAppointmentFormSheetState extends State<HrAppointmentFormSheet> {
  final _search = TextEditingController();
  final _location = TextEditingController();
  final _purpose = TextEditingController();
  final _notes = TextEditingController();

  late String _type;
  HrAppointmentClient? _client;
  DateTime? _date;
  TimeOfDay? _time;
  bool _pickerOpen = false;
  bool _submitted = false;
  bool _saving = false;
  String? _saveError;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _type = 'family_visit';
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay(hour: now.hour, minute: 0);
    final e = widget.editing;
    if (e != null) {
      _type = e.isFamilyVisit ? 'family_visit' : 'external';
      _client = HrAppointmentClient(
        id: e.clientId,
        name: e.client,
        residence: e.residence,
        residenceId: e.residenceId ?? '',
      );
      final at = e.scheduledAt?.toLocal();
      if (at != null) {
        _date = DateTime(at.year, at.month, at.day);
        _time = TimeOfDay(hour: at.hour, minute: at.minute);
      }
      _location.text = e.location ?? '';
      _purpose.text = e.purpose ?? '';
      _notes.text = e.notes ?? '';
    }
    for (final c in [_location, _purpose, _notes]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [_search, _location, _purpose, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _timeText => _time == null
      ? ''
      : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

  Map<String, String> get _errors => {
        if (_client == null) 'clientId': 'Choose the resident this is for',
        if (_date == null) 'date': 'Set the date',
        if (_time == null) 'time': 'Set the time',
      };

  String? _error(String key) => _submitted ? _errors[key] : null;

  static String? _trimmed(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _saveError = null;
    });
    if (_errors.isNotEmpty) return;
    final d = _date!;
    final t = _time!;
    final client = _client!;
    setState(() => _saving = true);
    final error = await widget.controller.save(
      HrAppointmentInput(
        type: _type,
        clientId: client.id,
        residenceId: client.residenceId.isEmpty ? null : client.residenceId,
        scheduledAt: DateTime(d.year, d.month, d.day, t.hour, t.minute),
        location: _trimmed(_location),
        purpose: _trimmed(_purpose),
        notes: _trimmed(_notes),
      ),
      editing: widget.editing,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _saveError = error;
    });
  }

  Future<void> _pickType() async {
    final picked = await pickHandoverOption(
      context,
      title: 'Type',
      options: HrAppointmentsLabels.formTypes,
      selected: _type,
    );
    if (picked != null) setState(() => _type = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final errorCount = _errors.length;
    final showBanner = (_submitted && errorCount > 0) || _saveError != null;
    const gap = SizedBox(height: 14);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.94,
          decoration: const BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              HrAppointmentSheetHeader(
                title: _isEdit ? 'Edit Appointment' : 'Create Appointment',
                description: _isEdit
                    ? 'Correct the time, place or notes. Approving or refusing is done from the queue.'
                    : 'A family visit arrives pending and needs approving; one the home books itself is confirmed straight away.',
                badges: [
                  if (_isEdit)
                    Text(
                      widget.editing!.reference,
                      style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.textMuted),
                    )
                  else
                    const HrAppointmentPill(label: 'New', tone: HrAppointmentTone.neutral),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 14),
                  children: [
                    // Kept as one slot so the list below never shifts index
                    // and the day-log panel is not rebuilt (and refetched).
                    showBanner
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: HrAppointmentErrorBox(
                              key: const ValueKey('appointment-form-error'),
                              title: _saveError != null
                                  ? 'This appointment could not be saved'
                                  : '$errorCount field${errorCount == 1 ? '' : 's'} need attention',
                              message: _saveError ?? 'Complete the required fields below.',
                            ),
                          )
                        : const SizedBox.shrink(),
                    _Step(
                      n: 1,
                      title: 'Appointment Type',
                      description: 'What kind of visit is this?',
                      children: [
                        HandoverSelect(
                          key: const ValueKey('appointment-form-type'),
                          label: 'Type',
                          required: true,
                          value: HrAppointmentsLabels.formTypeLabel(_type),
                          placeholder: 'Choose a type',
                          onTap: _pickType,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _type == 'family_visit'
                              ? 'A family visit is created pending, and appears in the queue for approval.'
                              : 'An external appointment is confirmed as soon as it is booked.',
                          style: handoverText(context, 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    gap,
                    _Step(
                      n: 2,
                      title: 'Resident & Residence',
                      description: 'Who this appointment is for',
                      children: [
                        _residentPicker(context),
                        const SizedBox(height: 14),
                        _ReadOnlyField(
                          label: 'Residence',
                          value: _client?.residence.isNotEmpty == true ? _client!.residence : '—',
                          helper: "Read from the resident's record",
                        ),
                      ],
                    ),
                    gap,
                    _Step(
                      n: 3,
                      title: 'Date & Time',
                      description: 'When this appointment takes place',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _TapField(
                                key: const ValueKey('appointment-form-date'),
                                label: 'Date',
                                value: _date == null ? '' : WebFormat.date(_date),
                                placeholder: 'Pick a date',
                                icon: Icons.calendar_today_outlined,
                                error: _error('date'),
                                onTap: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TapField(
                                key: const ValueKey('appointment-form-time'),
                                label: 'Time',
                                value: _timeText,
                                placeholder: '--:--',
                                icon: Icons.schedule_rounded,
                                error: _error('time'),
                                onTap: _pickTime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _Input(
                          key: const ValueKey('appointment-form-location'),
                          label: 'Location',
                          controller: _location,
                          placeholder: "e.g. Elm House lounge, or the clinic's address",
                        ),
                      ],
                    ),
                    gap,
                    HandoverPanel(
                      padding: const EdgeInsets.all(16),
                      child: HrAppointmentDayLogPanel(
                        controller: widget.controller,
                        clientId: _client?.id ?? '',
                        residenceId: _client?.residenceId ?? '',
                        clientName: _client?.name,
                      ),
                    ),
                    gap,
                    _Step(
                      n: 4,
                      title: 'Purpose & Notes',
                      description: 'Why it was asked for, and anything the team should know',
                      children: [
                        _Input(
                          key: const ValueKey('appointment-form-purpose'),
                          label: 'Purpose',
                          controller: _purpose,
                          placeholder: 'e.g. Birthday visit, GP review',
                        ),
                        const SizedBox(height: 14),
                        HandoverTextArea(
                          key: const ValueKey('appointment-form-notes'),
                          label: 'Notes',
                          controller: _notes,
                          minLines: 3,
                          placeholder: 'Anything the care team or family should know…',
                        ),
                      ],
                    ),
                    gap,
                    _Step(
                      n: 5,
                      title: 'Summary',
                      description: 'Review before saving',
                      children: [
                        HrAppointmentInfoGrid(
                          children: [
                            HrAppointmentInfo('Type', HrAppointmentsLabels.formTypeLabel(_type)),
                            HrAppointmentInfo('Residence', _client?.residence),
                            HrAppointmentInfo('Resident', _client?.name),
                            HrAppointmentInfo('Location', _trimmed(_location) == null ? 'Not set' : _location.text),
                            HrAppointmentInfo('Date', _date == null ? '' : WebFormat.date(_date)),
                            HrAppointmentInfo('Time', _timeText),
                            HrAppointmentInfo('Purpose', _purpose.text.isEmpty ? 'Not given' : _purpose.text),
                            HrAppointmentInfo(
                              'Status on save',
                              _type == 'family_visit' ? 'Pending approval' : 'Approved',
                            ),
                          ],
                        ),
                      ],
                    ),
                    gap,
                    _preview(context),
                  ],
                ),
              ),
              HrAppointmentSheetFooter(
                children: [
                  HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
                  HandoverButton(
                    key: const ValueKey('appointment-form-submit'),
                    label: _saving
                        ? 'Saving…'
                        : _isEdit
                            ? 'Save Changes'
                            : 'Create Appointment',
                    icon: Icons.edit_calendar_rounded,
                    filled: true,
                    onPressed: _saving ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _residentPicker(BuildContext context) {
    final error = _error('clientId');
    final client = _client;
    final label = Text.rich(
      const TextSpan(
        text: 'Resident',
        children: [TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed))],
      ),
      style: handoverText(context, 13, weight: FontWeight.w500),
    );
    if (client != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label,
          const SizedBox(height: 6),
          Container(
            key: const ValueKey('appointment-form-resident-selected'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                _Initials(name: client.name, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                      Text(
                        '${client.residence}${client.code.isEmpty ? '' : ' · ${client.code}'}',
                        style: handoverText(context, 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const HrAppointmentPill(
                  label: 'Selected',
                  tone: HrAppointmentTone.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
                if (!_isEdit)
                  IconButton(
                    key: const ValueKey('appointment-form-change-resident'),
                    tooltip: 'Change resident',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      _client = null;
                      _search.clear();
                    }),
                    icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    final query = _search.text.trim().toLowerCase();
    final matches = widget.controller.clients
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label,
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('appointment-form-resident-search'),
          controller: _search,
          onTap: () => setState(() => _pickerOpen = true),
          onChanged: (_) => setState(() => _pickerOpen = true),
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search clients or family contacts...',
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: error != null ? AppColors.criticalRed : AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: error != null ? AppColors.criticalRed : AppColors.searchBorder),
            ),
          ),
        ),
        if (_pickerOpen)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No matching clients found',
                      textAlign: TextAlign.center,
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in matches)
                        InkWell(
                          key: ValueKey('appointment-form-resident-${c.id}'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(() {
                            _client = c;
                            _search.clear();
                            _pickerOpen = false;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                _Initials(name: c.name, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: handoverText(context, 12.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
                                      ),
                                      Text(
                                        '#${c.code} · ${c.residence}',
                                        style: handoverText(context, 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        const SizedBox(height: 5),
        Text(
          error ?? 'Type to search clients or family contacts',
          style: handoverText(context, 12, color: error != null ? AppColors.criticalRed : AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _preview(BuildContext context) {
    final checks = [
      ('Type chosen', _type.isNotEmpty),
      ('Resident linked', _client != null),
      ('Date & time set', _date != null && _time != null),
      ('Purpose given', _purpose.text.trim().isNotEmpty),
    ];
    final ready = checks.every((c) => c.$2);
    Widget row(String label, String? value) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
          ),
          child: Row(
            children: [
              Text(label, style: handoverText(context, 12, color: AppColors.textMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value == null || value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: handoverText(context, 13, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
    return HandoverPanel(
      key: const ValueKey('appointment-form-preview'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_calendar_rounded, size: 15, color: AppColors.secondaryTeal),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appointment Preview', style: handoverText(context, 14, weight: FontWeight.w700, color: AppColors.primaryNavy)),
                  Text('Live preview', style: handoverText(context, 11.5, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: AppColors.primaryNavy,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _client?.residence.isNotEmpty == true ? _client!.residence : 'Residence',
                          style: handoverText(context, 13, color: AppColors.surfaceWhite.withValues(alpha: 0.72)),
                        ),
                        Text(
                          _type == 'external' ? 'External appointment' : 'Family visit',
                          style: handoverText(context, 14, weight: FontWeight.w600, color: AppColors.surfaceWhite),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        row('Resident', _client?.name),
                        row('Location', _trimmed(_location) == null ? 'Not set' : _location.text),
                        row('Date', _date == null ? '' : WebFormat.date(_date)),
                        row('Time', _timeText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ready) ...[
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('appointment-form-ready'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.activeBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.activeGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.activeGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Ready to Submit',
                        style: handoverText(context, 12.5, weight: FontWeight.w700, color: AppColors.activeGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All required details are complete. '
                    '${_type == 'family_visit' ? 'It will be created pending, for a manager to approve.' : 'It will be confirmed as soon as it is saved.'}',
                    style: handoverText(context, 11.5, color: AppColors.activeGreen),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, done) in checks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          done ? Icons.check_circle_outline_rounded : Icons.circle_outlined,
                          size: 13,
                          color: done ? AppColors.activeGreen : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: handoverText(context, 12, color: done ? AppColors.activeGreen : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String title;
  final String description;
  final List<Widget> children;

  const _Step({
    required this.n,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$n',
                  style: handoverText(context, 12, weight: FontWeight.w700, color: AppColors.secondaryTeal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: handoverText(context, 14, weight: FontWeight.w700, color: AppColors.primaryNavy)),
                    Text(description, style: handoverText(context, 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: AppColors.criticalRed)),
          ],
        ),
        style: handoverText(context, 13, weight: FontWeight.w500),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;

  const _Input({
    super.key,
    required this.label,
    required this.controller,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        TextField(
          controller: controller,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder,
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: border,
            enabledBorder: border,
          ),
        ),
      ],
    );
  }
}

class _TapField extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final IconData icon;
  final String? error;
  final VoidCallback onTap;

  const _TapField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label, required: true),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: error != null ? AppColors.criticalRed : AppColors.searchBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? placeholder : value,
                    style: handoverText(
                      context,
                      13.5,
                      color: value.isEmpty ? AppColors.textMuted : AppColors.textHeading,
                    ),
                  ),
                ),
                Icon(icon, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error!, style: handoverText(context, 12, color: AppColors.criticalRed)),
        ],
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _ReadOnlyField({required this.label, required this.value, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.filterButtonBackground,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Text(value, style: handoverText(context, 13.5, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 5),
        Text(helper, style: handoverText(context, 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  final double size;

  const _Initials({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        hrAppointmentInitials(name),
        style: handoverText(context, size > 30 ? 12 : 10, weight: FontWeight.w700, color: AppColors.secondaryTeal),
      ),
    );
  }
}
