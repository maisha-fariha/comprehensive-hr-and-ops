import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../clients/presentation/widgets/clients_common.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/users_access_repository.dart';

/// Web "Add User" wizard — same shell as Add Client (`ClientSheetFrame`).
Future<bool?> showAddUserOnboardSheet(
  BuildContext context, {
  required UsersAccessRepository repository,
}) {
  return showClientSheet<bool>(
    context,
    _AddUserOnboardSheet(repository: repository),
  );
}

enum _UserStep {
  personal,
  emergency,
  employment,
  residence,
  compliance,
  account,
}

extension on _UserStep {
  String get label => switch (this) {
        _UserStep.personal => 'Personal Information',
        _UserStep.emergency => 'Emergency Contact',
        _UserStep.employment => 'Employment Information',
        _UserStep.residence => 'Residence Assignment',
        _UserStep.compliance => 'Compliance & Expiry Tracking',
        _UserStep.account => 'Account Setup',
      };

  String get description => switch (this) {
        _UserStep.personal => 'Core identity details.',
        _UserStep.emergency => 'Who to contact in an emergency.',
        _UserStep.employment => 'Role, pay basis & compensation.',
        _UserStep.residence => 'Residences & payroll split.',
        _UserStep.compliance => 'Documents & certifications.',
        _UserStep.account => 'Invitation & access.',
      };
}

class _AddUserOnboardSheet extends StatefulWidget {
  final UsersAccessRepository repository;

  const _AddUserOnboardSheet({required this.repository});

  @override
  State<_AddUserOnboardSheet> createState() => _AddUserOnboardSheetState();
}

class _AddUserOnboardSheetState extends State<_AddUserOnboardSheet> {
  static const _gap = SizedBox(height: 16);

  static const _relationships = [
    'Spouse',
    'Parent',
    'Child',
    'Sibling',
    'Friend',
    'Caseworker',
    'Other',
  ];

  static const _employmentTypes = <(String, String)>[
    ('full_time', 'Full-time'),
    ('part_time', 'Part-time'),
    ('casual', 'Casual'),
    ('contract', 'Contract'),
  ];

  static const _statuses = <(String, String)>[
    ('active', 'Active'),
    ('inactive', 'Inactive'),
    ('on_leave', 'On leave'),
  ];

  static const _paymentDurations = <(String, String)>[
    ('weekly', 'Weekly'),
    ('fortnightly', 'Fortnightly'),
    ('monthly', 'Monthly'),
  ];

  static const _paymentBases = <(String, String)>[
    ('hourly', 'Hourly'),
    ('salary_based', 'Salary based'),
    ('contract', 'Contract'),
  ];

  final _scroll = ScrollController();
  _UserStep _step = _UserStep.personal;
  bool _saving = false;
  bool _loadingLookups = true;
  String? _banner;
  Map<String, String> _errors = {};

  String? _photoPath;
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _dob = '';

  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _alternativeContact = TextEditingController();
  String _relationship = '';

  final Set<String> _roleIds = {};
  String _employmentType = 'full_time';
  String _hireDate = '';
  String _status = 'active';
  String _paymentDuration = 'fortnightly';
  String _paymentBasis = '';
  bool _medAdminApproved = false;
  bool _syncQuickBooks = true;

  List<({String id, String name})> _residences = const [];
  final Set<String> _residenceIds = {};
  String _primaryResidenceId = '';

  final List<({String name, String path})> _documents = [];

  List<({String id, String name, String code})> _roles = const [];
  bool _createLogin = true;
  bool _sendInvite = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final residences = await widget.repository.fetchResidences();
    final roles = await widget.repository.fetchRoles();
    if (!mounted) return;
    setState(() {
      residences.when(
        success: (rows) => _residences = rows,
        failure: (_) => _residences = const [],
      );
      roles.when(
        success: (rows) => _roles = rows,
        failure: (_) => _roles = const [],
      );
      _loadingLookups = false;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _firstName,
      _middleName,
      _lastName,
      _email,
      _phone,
      _address,
      _emergencyName,
      _emergencyPhone,
      _alternativeContact,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {});

  void _goTo(_UserStep step) {
    setState(() {
      _step = step;
      _banner = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  bool _stepComplete(_UserStep step) {
    switch (step) {
      case _UserStep.personal:
        return _firstName.text.trim().isNotEmpty &&
            _lastName.text.trim().isNotEmpty &&
            _email.text.trim().isNotEmpty;
      case _UserStep.emergency:
        return _emergencyName.text.trim().isNotEmpty &&
            _emergencyPhone.text.trim().isNotEmpty;
      case _UserStep.employment:
        return _roleIds.isNotEmpty && _hireDate.isNotEmpty;
      case _UserStep.residence:
        return _residenceIds.isNotEmpty && _primaryResidenceId.isNotEmpty;
      case _UserStep.compliance:
        return true;
      case _UserStep.account:
        return !_createLogin || _roleIds.isNotEmpty;
    }
  }

  Map<String, String> _validateStep(_UserStep step) {
    final errors = <String, String>{};
    switch (step) {
      case _UserStep.personal:
        if (_firstName.text.trim().isEmpty) {
          errors['firstName'] = 'First name is required.';
        }
        if (_lastName.text.trim().isEmpty) {
          errors['lastName'] = 'Last name is required.';
        }
        if (_email.text.trim().isEmpty) {
          errors['email'] = 'Email is required.';
        }
      case _UserStep.emergency:
        if (_emergencyName.text.trim().isEmpty) {
          errors['emergencyContactName'] =
              'Emergency contact name is required.';
        }
        if (_emergencyPhone.text.trim().isEmpty) {
          errors['emergencyContactPhone'] =
              'Emergency contact phone is required.';
        }
      case _UserStep.employment:
        if (_roleIds.isEmpty) {
          errors['roleIds'] = 'Add at least one staff role.';
        }
        if (_hireDate.isEmpty) {
          errors['hireDate'] = 'Hire date is required.';
        }
      case _UserStep.residence:
        if (_residenceIds.isEmpty) {
          errors['residenceIds'] = 'Assign at least one residence.';
        }
        if (_primaryResidenceId.isEmpty) {
          errors['primaryResidenceId'] = 'Choose a primary residence.';
        }
      case _UserStep.compliance:
        break;
      case _UserStep.account:
        if (_createLogin && _roleIds.isEmpty) {
          errors['roleIds'] = 'A login needs at least one role.';
        }
    }
    return errors;
  }

  bool _stepValid() {
    final errors = _validateStep(_step);
    setState(() {
      _errors = {..._errors}
        ..removeWhere((k, _) => _stepOf(k) == _step)
        ..addAll(errors);
      if (errors.isNotEmpty) {
        _banner =
            '${errors.length} field${errors.length == 1 ? '' : 's'} still need attention — ${errors.keys.join(', ')}.';
      } else {
        _banner = null;
      }
    });
    return errors.isEmpty;
  }

  _UserStep _stepOf(String field) => switch (field) {
        'firstName' ||
        'lastName' ||
        'email' ||
        'phone' ||
        'dateOfBirth' ||
        'address' =>
          _UserStep.personal,
        'emergencyContactName' ||
        'emergencyContactPhone' ||
        'relationship' =>
          _UserStep.emergency,
        'roleIds' ||
        'hireDate' ||
        'employmentType' ||
        'paymentBasis' =>
          _UserStep.employment,
        'residenceIds' || 'primaryResidenceId' => _UserStep.residence,
        _ => _UserStep.account,
      };

  void _jump(_UserStep step) {
    if (step.index > _step.index && !_stepValid()) return;
    _goTo(step);
  }

  void _next() {
    if (!_stepValid()) return;
    if (_step.index < _UserStep.values.length - 1) {
      _goTo(_UserStep.values[_step.index + 1]);
      return;
    }
    _submit();
  }

  Map<String, dynamic> _buildBody() {
    final staff = <String, dynamic>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim(),
      if (_middleName.text.trim().isNotEmpty)
        'middleName': _middleName.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
      if (_dob.isNotEmpty) 'dateOfBirth': _dob,
      'emergencyContactName': _emergencyName.text.trim(),
      'emergencyContactPhone': _emergencyPhone.text.trim(),
      if (_relationship.isNotEmpty)
        'emergencyContactRelationship': _relationship,
      if (_alternativeContact.text.trim().isNotEmpty)
        'alternativeContactPhone': _alternativeContact.text.trim(),
      'employmentType': _employmentType,
      if (_hireDate.isNotEmpty) 'hireDate': _hireDate,
      'status': _status,
      'paymentFrequency': _paymentDuration,
      if (_paymentBasis.isNotEmpty) 'paymentBasis': _paymentBasis,
      'medAdminApproved': _medAdminApproved,
      'syncQuickBooks': _syncQuickBooks,
      if (_residenceIds.isNotEmpty)
        'residenceIds': _residenceIds.toList(growable: false),
      if (_primaryResidenceId.isNotEmpty)
        'primaryResidenceId': _primaryResidenceId,
    };
    return {
      'staff': staff,
      if (_roleIds.isNotEmpty) 'roleIds': _roleIds.toList(growable: false),
      if (_residenceIds.isNotEmpty)
        'residenceIds': _residenceIds.toList(growable: false),
      if (_primaryResidenceId.isNotEmpty)
        'primaryResidenceId': _primaryResidenceId,
      'createLogin': _createLogin,
      'sendInvite': _createLogin && _sendInvite,
    };
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_stepValid()) return;
    setState(() {
      _saving = true;
      _banner = null;
    });
    final result = await widget.repository.onboardUser(_buildBody());
    if (!mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(
          'Person added',
          '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
          force: true,
        );
        if (_documents.isNotEmpty) {
          AppSnackbar.show(
            'Documents',
            'Attach compliance files from the staff profile after create.',
            force: true,
          );
        }
        Navigator.of(context).pop(true);
      },
      failure: (err) => setState(() {
        _saving = false;
        _banner = err.message;
      }),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await AppFilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    final files = picked?.files ?? const [];
    if (files.isEmpty || !mounted) return;
    final path = files.first.path;
    if (path == null) return;
    setState(() => _photoPath = path);
  }

  Future<void> _pickDocument() async {
    final picked = await AppFilePicker.pickFiles(allowMultiple: false);
    final files = picked?.files ?? const [];
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    final path = file.path;
    if (path == null) return;
    setState(() => _documents.add((name: file.name, path: path)));
  }

  @override
  Widget build(BuildContext context) {
    final index = _step.index;
    final total = _UserStep.values.length;
    final percent = (((index + 1) / total) * 100).round();
    final last = _step == _UserStep.account;

    return ClientSheetFrame(
      icon: Icons.person_add_alt_1_outlined,
      title: 'Add User',
      description:
          'Create a user profile, assign residences, and grant account access.',
      scrollController: _scroll,
      statusBar: const ClientStatusBar(
        TextSpan(
          children: [
            TextSpan(
              text: '*',
              style: TextStyle(
                color: AppColors.criticalRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text:
                  ' Required fields · User records control platform access, residence scope, and compliance tracking.',
            ),
          ],
        ),
      ),
      top: ClientStepChips(
        current: _step.name,
        onTap: (id) => _jump(_UserStep.values.byName(id)),
        steps: [
          for (final s in _UserStep.values)
            (s.name, s.label, s.description, _stepComplete(s)),
        ],
      ),
      footerLeft: Text.rich(
        const TextSpan(
          children: [
            TextSpan(
              text: '*',
              style: TextStyle(color: AppColors.criticalRed),
            ),
            TextSpan(text: ' Required fields'),
          ],
        ),
        style: handoverText(context, 12, color: AppColors.textMuted),
      ),
      footer: [
        if (index == 0)
          HandoverButton(
            label: 'Cancel',
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          )
        else
          HandoverButton(
            label: 'Back',
            onPressed: _saving
                ? null
                : () => _goTo(_UserStep.values[index - 1]),
          ),
        HandoverButton(
          label: 'Save Draft',
          onPressed: _saving
              ? null
              : () => AppSnackbar.show(
                    'Draft kept on this device',
                    'Continue filling steps, then Save.',
                    force: true,
                  ),
        ),
        HandoverButton(
          label: _saving ? 'Saving…' : (last ? 'Save' : 'Next'),
          filled: true,
          onPressed: _saving ? null : _next,
        ),
      ],
      children: [
        ClientProgressCard(
          caption: 'Completion',
          trailing: 'Step ${index + 1} of $total',
          fraction: (index + 1) / total,
          line: '$percent% complete',
          lineAccent: true,
        ),
        const SizedBox(height: 16),
        if (_banner != null) ...[
          ClientBanner(_banner!),
          const SizedBox(height: 12),
        ],
        if (_loadingLookups)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          switch (_step) {
            _UserStep.personal => _personal(),
            _UserStep.emergency => _emergency(),
            _UserStep.employment => _employment(),
            _UserStep.residence => _residence(),
            _UserStep.compliance => _compliance(),
            _UserStep.account => _account(),
          },
      ],
    );
  }

  Widget _personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _UserStep.personal.label,
          description: _UserStep.personal.description,
        ),
        _gap,
        ClientFileField(
          label: 'User Photo',
          hint: 'JPG, PNG, WebP or HEIC · up to 25MB',
          fileName: _photoPath?.split('/').last,
          onPick: _saving ? null : _pickPhoto,
          onClear: _photoPath == null
              ? null
              : () => setState(() => _photoPath = null),
        ),
        _gap,
        ClientInput(
          label: 'First Name',
          required: true,
          controller: _firstName,
          enabled: !_saving,
          error: _errors['firstName'],
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientInput(
          label: 'Middle Name',
          controller: _middleName,
          enabled: !_saving,
          placeholder: 'Optional',
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientInput(
          label: 'Last Name',
          required: true,
          controller: _lastName,
          enabled: !_saving,
          error: _errors['lastName'],
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientInput(
          label: 'Email',
          required: true,
          controller: _email,
          enabled: !_saving,
          keyboardType: TextInputType.emailAddress,
          helper: 'Must be unique within your organization.',
          error: _errors['email'],
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientInput(
          label: 'Phone',
          controller: _phone,
          enabled: !_saving,
          keyboardType: TextInputType.phone,
          placeholder: '(555) 123-4567',
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientDateField(
          label: 'Date of Birth',
          value: _dob,
          enabled: !_saving,
          lastDate: DateTime.now(),
          onChanged: (v) => setState(() => _dob = v),
        ),
        _gap,
        ClientInput(
          label: 'Address',
          controller: _address,
          enabled: !_saving,
          placeholder: 'Street, city, state, zip',
          onChanged: (_) => _changed(),
        ),
      ],
    );
  }

  Widget _emergency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _UserStep.emergency.label,
          description: _UserStep.emergency.description,
        ),
        _gap,
        ClientInput(
          label: 'Emergency Contact Name',
          required: true,
          controller: _emergencyName,
          enabled: !_saving,
          error: _errors['emergencyContactName'],
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientInput(
          label: 'Emergency Contact Phone',
          required: true,
          controller: _emergencyPhone,
          enabled: !_saving,
          keyboardType: TextInputType.phone,
          error: _errors['emergencyContactPhone'],
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientSelect(
          label: 'Relationship',
          value: _relationship,
          placeholder: 'Select relationship',
          options: [for (final r in _relationships) (r, r)],
          enabled: !_saving,
          onChanged: (v) => setState(() => _relationship = v),
        ),
        _gap,
        ClientInput(
          label: 'Alternative Contact',
          controller: _alternativeContact,
          enabled: !_saving,
          keyboardType: TextInputType.phone,
          placeholder: '(555) 123-4567',
          onChanged: (_) => _changed(),
        ),
      ],
    );
  }

  Widget _employment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _UserStep.employment.label,
          description: _UserStep.employment.description,
        ),
        _gap,
        clientFieldLabel(context, 'Staff Role', required: true),
        Text(
          'What the account may do — everything else is decided by these.',
          style: handoverText(context, 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in _roles)
              FilterChip(
                label: Text(r.name),
                selected: _roleIds.contains(r.id),
                selectedColor: AppColors.activeBackground,
                checkmarkColor: AppColors.secondaryTeal,
                onSelected: _saving
                    ? null
                    : (on) => setState(() {
                          if (on) {
                            _roleIds.add(r.id);
                          } else {
                            _roleIds.remove(r.id);
                          }
                          _errors.remove('roleIds');
                        }),
              ),
          ],
        ),
        clientFieldHelper(context, error: _errors['roleIds']),
        _gap,
        ClientSelect(
          label: 'Employment Type',
          required: true,
          value: _employmentType,
          placeholder: 'Select type',
          options: _employmentTypes,
          enabled: !_saving,
          onChanged: (v) => setState(() => _employmentType = v),
        ),
        _gap,
        ClientDateField(
          label: 'Hire Date',
          required: true,
          value: _hireDate,
          enabled: !_saving,
          error: _errors['hireDate'],
          onChanged: (v) => setState(() {
            _hireDate = v;
            _errors.remove('hireDate');
          }),
        ),
        _gap,
        ClientSelect(
          label: 'Status',
          required: true,
          value: _status,
          placeholder: 'Select status',
          options: _statuses,
          enabled: !_saving,
          onChanged: (v) => setState(() => _status = v),
        ),
        _gap,
        ClientSelect(
          label: 'Payment Duration',
          required: true,
          value: _paymentDuration,
          placeholder: 'Select duration',
          options: _paymentDurations,
          enabled: !_saving,
          onChanged: (v) => setState(() => _paymentDuration = v),
        ),
        _gap,
        ClientSwitchTile(
          label: 'Can administer medicine',
          description:
              'Approved by this organisation to give and to witness medication.',
          value: _medAdminApproved,
          bordered: true,
          onChanged: _saving
              ? null
              : (v) => setState(() => _medAdminApproved = v),
        ),
        _gap,
        ClientSelect(
          label: 'Payment Basis',
          value: _paymentBasis,
          placeholder: 'Select how this person is paid',
          helper:
              'How the pay is worked out — separate from the contract type above.',
          options: _paymentBases,
          enabled: !_saving,
          onChanged: (v) => setState(() => _paymentBasis = v),
        ),
        _gap,
        ClientSwitchTile(
          label: 'Also add to QuickBooks',
          description:
              'Links them to their QuickBooks employee, or adds them there with their name, email, phone and start date.',
          value: _syncQuickBooks,
          bordered: true,
          onChanged:
              _saving ? null : (v) => setState(() => _syncQuickBooks = v),
        ),
      ],
    );
  }

  Widget _residence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _UserStep.residence.label,
          description: 'Assign this user to one or more residences.',
        ),
        _gap,
        clientFieldLabel(context, 'Assigned Residences', required: true),
        if (_residences.isEmpty)
          Text(
            'No residences available.',
            style: handoverText(context, 13, color: AppColors.textMuted),
          )
        else
          for (final r in _residences)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _residenceIds.contains(r.id),
              title: Text(r.name, style: handoverText(context, 13.5)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.secondaryTeal,
              onChanged: _saving
                  ? null
                  : (on) => setState(() {
                        if (on == true) {
                          _residenceIds.add(r.id);
                          if (_primaryResidenceId.isEmpty) {
                            _primaryResidenceId = r.id;
                          }
                        } else {
                          _residenceIds.remove(r.id);
                          if (_primaryResidenceId == r.id) {
                            _primaryResidenceId = _residenceIds.isEmpty
                                ? ''
                                : _residenceIds.first;
                          }
                        }
                        _errors.remove('residenceIds');
                        _errors.remove('primaryResidenceId');
                      }),
            ),
        clientFieldHelper(context, error: _errors['residenceIds']),
        _gap,
        ClientSelect(
          label: 'Primary Residence',
          required: true,
          value: _primaryResidenceId,
          placeholder: _residenceIds.isEmpty
              ? 'Assign a residence first'
              : 'Select primary',
          helper: 'Where they mainly work — used when a screen has to pick one.',
          options: [
            for (final r in _residences)
              if (_residenceIds.contains(r.id)) (r.id, r.name),
          ],
          enabled: !_saving && _residenceIds.isNotEmpty,
          error: _errors['primaryResidenceId'],
          onChanged: (v) => setState(() {
            _primaryResidenceId = v;
            _errors.remove('primaryResidenceId');
          }),
        ),
      ],
    );
  }

  Widget _compliance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _UserStep.compliance.label,
          description:
              'Upload required documents and certifications, and track their expiry dates.',
        ),
        _gap,
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.infoBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Badges update automatically from the entered dates. “Expiring Soon” is flagged within 30 days of the expiry date.',
            style: handoverText(context, 12, color: AppColors.infoBlue),
          ),
        ),
        _gap,
        if (_documents.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Center(
              child: Text(
                'No documents added yet.',
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
            ),
          )
        else
          for (final doc in _documents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(doc.name, style: handoverText(context, 13)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _saving
                    ? null
                    : () => setState(() => _documents.remove(doc)),
              ),
            ),
        const SizedBox(height: 8),
        HandoverButton(
          label: 'Add Document',
          icon: Icons.add,
          onPressed: _saving ? null : _pickDocument,
        ),
      ],
    );
  }

  Widget _account() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _UserStep.account.label,
          description: 'A login for this person, and what it may do.',
        ),
        _gap,
        ClientSwitchTile(
          label: 'Create a login',
          description:
              'Leave this off for an employee who does not use the system.',
          value: _createLogin,
          bordered: true,
          onChanged: _saving
              ? null
              : (v) => setState(() {
                    _createLogin = v;
                    if (!v) _sendInvite = false;
                  }),
        ),
        if (_createLogin) ...[
          _gap,
          ClientSwitchTile(
            label: 'Send an invitation',
            description: 'Emails a link so they set their own password.',
            value: _sendInvite,
            bordered: true,
            onChanged:
                _saving ? null : (v) => setState(() => _sendInvite = v),
          ),
          _gap,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Invite emails may take a few minutes to arrive. Please advise new staff to check their Spam/Junk folder if they do not see it in their inbox.',
              style: handoverText(context, 12, color: AppColors.infoBlue),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'The account is linked to the employee record created by this form, which is what lets the mobile app clock them in and attribute their medication rounds to a named carer rather than a login.',
              style: handoverText(context, 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Residence access follows the residences assigned in step four.',
              style: handoverText(context, 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}
