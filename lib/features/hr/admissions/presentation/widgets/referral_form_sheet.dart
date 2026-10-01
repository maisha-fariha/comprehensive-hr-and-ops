import 'package:flutter/material.dart';

import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../admissions_labels.dart';
import '../controllers/admissions_controller.dart';
import 'admissions_common.dart';
import 'intake_fields_form.dart';

/// Opens "New referral", or "Edit referral" when [referral] is given.
Future<void> showReferralFormSheet(
  BuildContext context, {
  required AdmissionsController controller,
  Referral? referral,
}) =>
    showAdmissionSheet<void>(
      context,
      ReferralFormSheet(controller: controller, referral: referral),
    );

class ReferralFormSheet extends StatefulWidget {
  final AdmissionsController controller;
  final Referral? referral;

  const ReferralFormSheet({super.key, required this.controller, this.referral});

  @override
  State<ReferralFormSheet> createState() => _ReferralFormSheetState();
}

class _ReferralFormSheetState extends State<ReferralFormSheet> {
  static final _name = RegExp(r"^[A-Za-z][A-Za-z\s'.-]*$");
  static final _phone = RegExp(r'^\+?[\d\s().-]{7,20}$');
  static final _email = RegExp(
    r"^(?!\.)(?!.*\.\.)([A-Z0-9_'+\-\.]*)[A-Z0-9_+-]@([A-Z0-9][A-Z0-9\-]*\.)+[A-Z]{2,}$",
    caseSensitive: false,
  );

  late final _firstName = TextEditingController(text: widget.referral?.firstName);
  late final _lastName = TextEditingController(text: widget.referral?.lastName);
  late final _source = TextEditingController(text: widget.referral?.source);
  late final _reason =
      TextEditingController(text: widget.referral?.reasonForAdmission);
  late final _contactName =
      TextEditingController(text: widget.referral?.contactName);
  late final _contactPhone =
      TextEditingController(text: widget.referral?.contactPhone);
  late final _contactEmail =
      TextEditingController(text: widget.referral?.contactEmail);
  late final _priority = TextEditingController(
    text: widget.referral?.priority?.toString() ?? '0',
  );
  late final _notes = TextEditingController(text: widget.referral?.notes);

  late String _dateOfBirth = _dateOnly(widget.referral?.dateOfBirth);
  late String _expected = _dateOnly(widget.referral?.expectedAdmissionDate);
  late String _admissionType = widget.referral?.admissionType ?? '';
  late String _preferredResidence = widget.referral?.preferredResidenceId ?? '';
  String _templateId = '';
  Map<String, dynamic> _payload = {};

  List<IntakeTemplate> _templates = const [];
  Map<String, String> _fieldErrors = {};
  String? _error;
  bool _saving = false;

  bool get _editing => widget.referral != null;

  AdmissionsController get _c => widget.controller;

  /// The stored date as the API returned it (`slice(0, 10)` on the web).
  static String _dateOnly(DateTime? value) =>
      value == null ? '' : AdmissionDateField.format(value.toUtc());

  @override
  void initState() {
    super.initState();
    if (!_editing) _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final result = await _c.repository.templates(activeOnly: true);
    if (!mounted) return;
    result.when(
      success: (list) => setState(() => _templates = list),
      failure: (_) {},
    );
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _source,
      _reason,
      _contactName,
      _contactPhone,
      _contactEmail,
      _priority,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _requiredName(String label, String value) {
    final v = value.trim();
    if (v.isEmpty) return '$label is required';
    if (v.length > 80) return '$label must be 80 characters or fewer';
    if (!_name.hasMatch(v)) return '$label can only contain letters';
    return null;
  }

  String? _optionalName(String label, String value) {
    if (value.isEmpty) return null;
    if (value.length > 80) return '$label must be 80 characters or fewer';
    if (!_name.hasMatch(value)) return '$label can only contain letters';
    return null;
  }

  Map<String, String> _validate() => {
        'firstName': ?_requiredName('First name', _firstName.text),
        'lastName': ?_requiredName('Last name', _lastName.text),
        'contactName': ?_optionalName('Contact name', _contactName.text),
        if (_contactPhone.text.isNotEmpty && !_phone.hasMatch(_contactPhone.text))
          'contactPhone': 'Enter a valid phone number',
        if (_contactEmail.text.isNotEmpty && !_email.hasMatch(_contactEmail.text))
          'contactEmail': 'Enter a valid email',
      };

  String? _trimmed(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _fieldErrors = _validate();
    });
    if (_fieldErrors.isNotEmpty) return;
    setState(() => _saving = true);
    final priority = num.tryParse(_priority.text);
    final body = <String, dynamic>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'dateOfBirth': ?(_dateOfBirth.isEmpty ? null : _dateOfBirth),
      'source': ?_trimmed(_source),
      'admissionType': ?(_admissionType.isEmpty ? null : _admissionType),
      'expectedAdmissionDate': ?(_expected.isEmpty ? null : _expected),
      'reasonForAdmission': ?_trimmed(_reason),
      'contactName': ?_trimmed(_contactName),
      'contactPhone': ?_trimmed(_contactPhone),
      'contactEmail': ?_trimmed(_contactEmail),
      'notes': ?_trimmed(_notes),
      'preferredResidenceId':
          ?(_preferredResidence.isEmpty ? null : _preferredResidence),
      'priority': priority == null || priority.isNaN ? 0 : priority,
    };
    final String? error;
    if (_editing) {
      error = await _c.updateReferral(widget.referral!.id, body);
    } else {
      error = await _c.createReferral({
        ...body,
        if (_templateId.isNotEmpty) ...{
          'intakeTemplateId': _templateId,
          'payload': _payload,
        },
      });
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    final template = _templates.where((t) => t.id == _templateId).firstOrNull;
    return AdmissionSheetFrame(
      icon: Icons.person_add_alt_1_outlined,
      title: _editing ? 'Edit referral' : 'New referral',
      description: _editing
          ? 'Corrects what was recorded — the stage and intake answers are changed elsewhere.'
          : 'Enough to hold someone\'s place in the queue — the intake form can be filled in later.',
      footer: [
        HandoverButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        HandoverButton(
          key: const ValueKey('referral-form-save'),
          label: _saving
              ? 'Saving…'
              : _editing
                  ? 'Save changes'
                  : 'Record referral',
          filled: true,
          onPressed: _saving ? null : _save,
        ),
      ],
      children: [
        if (_error != null) ...[
          AdmissionErrorBanner(_error!, key: const ValueKey('referral-form-error')),
          gap,
        ],
        AdmissionInput(
          key: const ValueKey('referral-first-name'),
          label: 'First name',
          required: true,
          controller: _firstName,
          error: _fieldErrors['firstName'],
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('referral-last-name'),
          label: 'Last name',
          required: true,
          controller: _lastName,
          error: _fieldErrors['lastName'],
        ),
        gap,
        AdmissionDateField(
          key: const ValueKey('referral-dob'),
          label: 'Date of birth',
          value: _dateOfBirth,
          lastDate: DateTime.now(),
          onChanged: (v) => setState(() => _dateOfBirth = v),
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('referral-source'),
          label: 'Referred by',
          placeholder: 'Hospital, family, social services…',
          controller: _source,
        ),
        gap,
        HandoverSelect(
          key: const ValueKey('referral-admission-type'),
          label: 'On what basis',
          value: _admissionType.isEmpty
              ? null
              : AdmissionsLabels.label(AdmissionsLabels.admissionTypes, _admissionType),
          placeholder: 'Not decided yet',
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: 'On what basis',
              options: AdmissionsLabels.admissionTypes,
              selected: _admissionType,
            );
            if (picked != null) setState(() => _admissionType = picked);
          },
        ),
        gap,
        AdmissionDateField(
          key: const ValueKey('referral-expected'),
          label: 'Expected admission date',
          helper: 'When they are expected, not when the referral arrived',
          value: _expected,
          onChanged: (v) => setState(() => _expected = v),
        ),
        gap,
        HandoverTextArea(
          key: const ValueKey('referral-reason'),
          label: 'Reason for admission',
          placeholder: 'Why they are coming…',
          controller: _reason,
          minLines: 3,
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('referral-contact-name'),
          label: 'Contact name',
          controller: _contactName,
          error: _fieldErrors['contactName'],
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('referral-contact-phone'),
          label: 'Contact phone',
          controller: _contactPhone,
          keyboardType: TextInputType.phone,
          error: _fieldErrors['contactPhone'],
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('referral-contact-email'),
          label: 'Contact email',
          controller: _contactEmail,
          keyboardType: TextInputType.emailAddress,
          error: _fieldErrors['contactEmail'],
        ),
        gap,
        HandoverSelect(
          key: const ValueKey('referral-preferred'),
          label: 'Preferred residence',
          value: _c.residenceName(_preferredResidence.isEmpty ? null : _preferredResidence),
          placeholder: 'No preference',
          helper: 'Waitlisting against a residence with a free bed alerts the intake team',
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: 'Preferred residence',
              options: [for (final r in _c.residences) (r.id, r.label)],
              selected: _preferredResidence,
            );
            if (picked != null) setState(() => _preferredResidence = picked);
          },
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('referral-priority'),
          label: 'Priority',
          controller: _priority,
          keyboardType: TextInputType.number,
          helper: '0–100. Higher sits nearer the top of the waitlist.',
        ),
        gap,
        HandoverTextArea(
          key: const ValueKey('referral-notes'),
          label: 'Notes',
          controller: _notes,
          minLines: 3,
        ),
        if (!_editing) ...[
          gap,
          HandoverSelect(
            key: const ValueKey('referral-template'),
            label: 'Intake form',
            value: template?.name,
            placeholder: 'None',
            helper: 'Only forms currently in use are offered — a retired one is refused',
            onTap: () async {
              final picked = await pickHandoverOption(
                context,
                title: 'Intake form',
                options: [for (final t in _templates) (t.id, t.name)],
                selected: _templateId,
              );
              if (picked != null) {
                setState(() {
                  _templateId = picked;
                  _payload = {};
                });
              }
            },
          ),
          if (template != null) ...[
            gap,
            IntakeFieldsForm(
              key: ValueKey('intake-${template.id}'),
              fields: template.fields,
              values: _payload,
              onChanged: (k, v) => setState(() => _payload = {..._payload, k: v}),
            ),
          ],
        ],
      ],
    );
  }
}
