import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Web relationship values (lowercase).
  static const _relationships = <(String, String)>[
    ('spouse', 'Spouse'),
    ('parent', 'Parent'),
    ('child', 'Child'),
    ('sibling', 'Sibling'),
    ('friend', 'Friend'),
    ('caseworker', 'Caseworker'),
    ('other', 'Other'),
  ];

  /// Web `eD` employment types.
  static const _employmentTypes = <(String, String)>[
    ('full_time', 'Full-time'),
    ('part_time', 'Part-time'),
    ('contract', 'Contract'),
    ('prn', 'As needed (PRN)'),
  ];

  static const _statuses = <(String, String)>[
    ('active', 'Active'),
    ('on_leave', 'On leave'),
    ('inactive', 'Inactive'),
  ];

  /// Web `eP` — API values; Fortnightly maps to `bi_weekly`.
  static const _paymentDurations = <(String, String)>[
    ('weekly', 'Weekly'),
    ('bi_weekly', 'Fortnightly'),
    ('semi_monthly', 'Twice a month'),
    ('monthly', 'Monthly'),
  ];

  /// Web `ez` payment bases.
  static const _paymentBases = <(String, String)>[
    ('hourly_based', 'Hourly based'),
    ('salary_based', 'Salary based'),
    ('shift_based', 'Shift based'),
  ];

  /// Web `eR` shift types.
  static const _shiftTypes = <(String, String)>[
    ('any', 'Any shift'),
    ('day', 'Day'),
    ('evening', 'Evening'),
    ('night', 'Night'),
    ('weekend', 'Weekend'),
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
  String _paymentDuration = 'bi_weekly';
  String _paymentBasis = '';
  bool _medAdminApproved = false;
  bool _addToQuickBooks = true;

  final _hourlyRate = TextEditingController();
  final _overtimeRate = TextEditingController();
  bool _attendanceRequired = true;
  final _monthlySalary = TextEditingController();
  final _allowances = TextEditingController();
  final _deductions = TextEditingController();
  final _shiftRate = TextEditingController();
  String _shiftType = 'any';
  final _overtimeAfterHours = TextEditingController();

  List<({String id, String name})> _residences = const [];
  final Set<String> _residenceIds = {};
  String _primaryResidenceId = '';

  final List<({String name, String path})> _documents = [];

  List<({String id, String name, String code})> _roles = const [];
  bool _createLogin = true;
  bool _sendInvite = true;
  final _temporaryPassword = TextEditingController();

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
      _hourlyRate,
      _overtimeRate,
      _monthlySalary,
      _allowances,
      _deductions,
      _shiftRate,
      _overtimeAfterHours,
      _temporaryPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

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

  double? _numOrNull(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Map<String, dynamic>? _employmentConfig() {
    switch (_paymentBasis) {
      case 'hourly_based':
        return {
          if (_numOrNull(_hourlyRate.text) != null)
            'hourlyRate': _numOrNull(_hourlyRate.text),
          if (_numOrNull(_overtimeRate.text) != null)
            'overtimeRate': _numOrNull(_overtimeRate.text),
          'attendanceRequired': _attendanceRequired,
        };
      case 'salary_based':
        return {
          if (_numOrNull(_monthlySalary.text) != null)
            'monthlySalary': _numOrNull(_monthlySalary.text),
          if (_numOrNull(_allowances.text) != null)
            'allowances': _numOrNull(_allowances.text),
          if (_numOrNull(_deductions.text) != null)
            'deductions': _numOrNull(_deductions.text),
        };
      case 'shift_based':
        return {
          if (_numOrNull(_shiftRate.text) != null)
            'shiftRate': _numOrNull(_shiftRate.text),
          if (_shiftType.isNotEmpty) 'shiftType': _shiftType,
          if (_numOrNull(_overtimeAfterHours.text) != null)
            'overtimeAfterHours': _numOrNull(_overtimeAfterHours.text),
          if (_numOrNull(_overtimeRate.text) != null)
            'overtimeRate': _numOrNull(_overtimeRate.text),
        };
      default:
        return null;
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
        if (_paymentBasis == 'hourly_based' &&
            _numOrNull(_hourlyRate.text) == null) {
          errors['hourlyRate'] = 'Hourly rate is required.';
        }
        if (_paymentBasis == 'salary_based' &&
            _numOrNull(_monthlySalary.text) == null) {
          errors['monthlySalary'] = 'Monthly salary is required.';
        }
        if (_paymentBasis == 'shift_based' &&
            _numOrNull(_shiftRate.text) == null) {
          errors['shiftRate'] = 'Shift rate is required.';
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
        if (_createLogin &&
            !_sendInvite &&
            _temporaryPassword.text.trim().length < 8) {
          errors['temporaryPassword'] =
              'Temporary password must be at least 8 characters.';
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
        'paymentBasis' ||
        'monthlySalary' ||
        'hourlyRate' ||
        'shiftRate' =>
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

  /// Web `POST /users/onboard` body (`staff` + top-level `employmentConfig` +
  /// `account` with `sendInvitationEmail`). Legacy `createLogin`/`sendInvite`
  /// creates a staff row but never a login or invite email.
  Map<String, dynamic> _buildBody({String? photoUrl}) {
    final email = _email.text.trim();
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final phone = _phone.text.trim();
    final residences = _residenceIds.toList(growable: false);
    final roles = _roleIds.toList(growable: false);

    final staff = <String, dynamic>{
      'firstName': first,
      'lastName': last,
      'email': email,
      'middleName':
          _middleName.text.trim().isEmpty ? null : _middleName.text.trim(),
      if (phone.isNotEmpty) 'phone': phone,
      'status': _status,
      if (_hireDate.isNotEmpty) 'hireDate': _hireDate,
      if (residences.isNotEmpty) 'residenceIds': residences,
      'employmentType': _employmentType,
      if (_paymentBasis.isNotEmpty) 'employmentBasis': _paymentBasis,
      'paymentDuration': _paymentDuration,
      if (_dob.isNotEmpty) 'dateOfBirth': _dob,
      if (_address.text.trim().isNotEmpty)
        'addressLine1': _address.text.trim(),
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      'emergencyContact': {
        'name': _emergencyName.text.trim(),
        'phone': _emergencyPhone.text.trim(),
        if (_relationship.isNotEmpty) 'relationship': _relationship,
        if (_alternativeContact.text.trim().isNotEmpty)
          'altPhone': _alternativeContact.text.trim(),
      },
      if (_paymentBasis == 'hourly_based' &&
          _numOrNull(_hourlyRate.text) != null)
        'hourlyRate': _numOrNull(_hourlyRate.text),
    };

    final config = _employmentConfig();
    final body = <String, dynamic>{
      'staff': staff,
      if (_addToQuickBooks) 'addToQuickBooks': true,
      if (config != null) 'employmentConfig': config,
      if (_documents.isNotEmpty)
        'documents': [
          for (final d in _documents) {'name': d.name},
        ],
    };

    if (_createLogin) {
      body['account'] = {
        'email': email,
        'name': '$first $last'.trim(),
        'middleName':
            _middleName.text.trim().isEmpty ? null : _middleName.text.trim(),
        if (phone.isNotEmpty) 'phone': phone,
        'roleIds': roles,
        if (residences.isNotEmpty) 'residenceIds': residences,
        if (_primaryResidenceId.isNotEmpty)
          'primaryResidenceId': _primaryResidenceId,
        if (_sendInvite)
          'sendInvitationEmail': true
        else ...{
          'sendInvitationEmail': false,
          'password': _temporaryPassword.text.trim(),
        },
      };
    }

    return body;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_stepValid()) return;
    setState(() {
      _saving = true;
      _banner = null;
    });

    String? photoUrl;
    final localPhoto = _photoPath;
    if (localPhoto != null && localPhoto.isNotEmpty) {
      final upload = await widget.repository.uploadFile(
        path: localPhoto,
        fileName: localPhoto.split('/').last,
        category: 'avatars',
      );
      if (!mounted) return;
      if (upload.isFailure) {
        setState(() {
          _saving = false;
          _banner = upload.error?.message ?? 'Photo upload failed.';
        });
        return;
      }
      photoUrl = upload.value;
    }

    final result = await widget.repository.onboardUser(
      _buildBody(photoUrl: photoUrl),
    );
    if (!mounted) return;
    if (result.isFailure) {
      setState(() {
        _saving = false;
        _banner = result.error?.message ?? 'Could not add person.';
      });
      return;
    }
    final data = result.value ?? const <String, dynamic>{};
    final staffId = (data['staffId'] ?? '').toString().trim();
    final userId = (data['userId'] ?? '').toString().trim();
    final inviteSent = data['invitationEmailSent'] == true;

    if (photoUrl != null && photoUrl.isNotEmpty && staffId.isNotEmpty) {
      await widget.repository.patchStaff(staffId, {'photoUrl': photoUrl});
    }
    if (_medAdminApproved && staffId.isNotEmpty) {
      await widget.repository.patchStaff(staffId, {
        'medAdminApproved': true,
      });
    }
    if (!mounted) return;

    final name = '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
    if (_createLogin && userId.isEmpty) {
      AppSnackbar.show(
        'Person added',
        '$name was saved, but a login was not created. Assign a role and invite again from the directory.',
        force: true,
      );
    } else if (_createLogin && _sendInvite && !inviteSent) {
      AppSnackbar.show(
        'Login created',
        'Invitation email did not send — share sign-in details another way, or invite again from the list.',
        force: true,
      );
    } else if (_createLogin && _sendInvite) {
      AppSnackbar.show(
        'Person added',
        'Invitation sent to ${_email.text.trim()}. Advise them to check Spam/Junk if needed.',
        force: true,
      );
    } else {
      AppSnackbar.show('Person added', name, force: true);
    }
    if (_documents.isNotEmpty) {
      AppSnackbar.show(
        'Documents',
        'Attach compliance files from the staff profile after create.',
        force: true,
      );
    }
    Navigator.of(context).pop(true);
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
            label: 'Previous',
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
        ),
        _gap,
        ClientInput(
          label: 'Middle Name',
          controller: _middleName,
          enabled: !_saving,
          placeholder: 'Optional',
        ),
        _gap,
        ClientInput(
          label: 'Last Name',
          required: true,
          controller: _lastName,
          enabled: !_saving,
          error: _errors['lastName'],
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
        ),
        _gap,
        ClientInput(
          label: 'Phone',
          controller: _phone,
          enabled: !_saving,
          keyboardType: TextInputType.phone,
          placeholder: '(555) 123-4567',
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
        ),
        _gap,
        ClientInput(
          label: 'Emergency Contact Phone',
          required: true,
          controller: _emergencyPhone,
          enabled: !_saving,
          keyboardType: TextInputType.phone,
          error: _errors['emergencyContactPhone'],
        ),
        _gap,
        ClientSelect(
          label: 'Relationship',
          value: _relationship,
          placeholder: 'Select relationship',
          options: _relationships,
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
          onChanged: (v) => setState(() {
            _paymentBasis = v;
            _errors.remove('hourlyRate');
            _errors.remove('monthlySalary');
            _errors.remove('shiftRate');
          }),
        ),
        if (_paymentBasis.isNotEmpty) ...[
          _gap,
          _employmentConfigPanel(),
        ],
        _gap,
        ClientSwitchTile(
          label: 'Also add to QuickBooks',
          description:
              'Links them to their QuickBooks employee, or adds them there with their name, email, phone and start date. Their pay rate, tax and bank details are set up in QuickBooks.',
          value: _addToQuickBooks,
          bordered: true,
          onChanged:
              _saving ? null : (v) => setState(() => _addToQuickBooks = v),
        ),
      ],
    );
  }

  Widget _employmentConfigPanel() {
    final (subtitle, fields) = switch (_paymentBasis) {
      'hourly_based' => (
          'Approved hours × hourly rate + overtime',
          <Widget>[
            ClientInput(
              label: 'Hourly Rate (\$)',
              required: true,
              controller: _hourlyRate,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 28.50',
              error: _errors['hourlyRate'],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            _gap,
            ClientInput(
              label: 'Overtime Rate (\$/hour)',
              controller: _overtimeRate,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 42.75',
              helper: 'An amount per hour, not a multiplier.',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            _gap,
            ClientSwitchTile(
              label: 'Attendance required',
              description:
                  'Hours must be clocked and approved before they are paid.',
              value: _attendanceRequired,
              bordered: true,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _attendanceRequired = v),
            ),
          ],
        ),
      'salary_based' => (
          'Fixed salary + allowances − deductions',
          <Widget>[
            ClientInput(
              label: 'Monthly Salary (\$)',
              required: true,
              controller: _monthlySalary,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 3000',
              error: _errors['monthlySalary'],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            _gap,
            ClientInput(
              label: 'Allowances (\$)',
              controller: _allowances,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 200',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            _gap,
            ClientInput(
              label: 'Deductions (\$)',
              controller: _deductions,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 150',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ],
        ),
      'shift_based' => (
          'Completed shifts × shift rate + overtime',
          <Widget>[
            ClientInput(
              label: 'Shift Rate (\$)',
              required: true,
              controller: _shiftRate,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 150',
              error: _errors['shiftRate'],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            _gap,
            ClientSelect(
              label: 'Shift Type',
              value: _shiftType,
              placeholder: 'Select shift type',
              options: _shiftTypes,
              enabled: !_saving,
              onChanged: (v) => setState(() => _shiftType = v),
            ),
            _gap,
            ClientInput(
              label: 'Overtime After (hours)',
              controller: _overtimeAfterHours,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 8',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            _gap,
            ClientInput(
              label: 'Overtime Rate (\$/hour)',
              controller: _overtimeRate,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g., 30',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ],
        ),
      _ => ('', <Widget>[]),
    };

    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Employment Configuration',
            style: handoverText(
              context,
              14,
              weight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          ...fields,
        ],
      ),
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
          if (_roleIds.isEmpty)
            ClientBanner(
              'Pick at least one staff role in Employment Information — a login cannot be created without a role.',
              warning: true,
            ),
          if (_roleIds.isEmpty) _gap,
          ClientSwitchTile(
            label: 'Send an invitation',
            description: 'Emails a link so they set their own password.',
            value: _sendInvite,
            bordered: true,
            onChanged:
                _saving ? null : (v) => setState(() => _sendInvite = v),
          ),
          if (!_sendInvite) ...[
            _gap,
            ClientInput(
              label: 'Temporary password',
              required: true,
              controller: _temporaryPassword,
              enabled: !_saving,
              helper: 'At least 8 characters. Share this with them securely.',
              error: _errors['temporaryPassword'],
            ),
          ],
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
