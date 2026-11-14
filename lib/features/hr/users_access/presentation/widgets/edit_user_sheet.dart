import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../clients/presentation/widgets/clients_common.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/users_access_repository.dart';
import '../../domain/users_access_models.dart';

/// Edit an existing directory person (staff + optional login).
Future<bool?> showEditUserSheet(
  BuildContext context, {
  required UsersAccessRepository repository,
  required DirectoryPerson person,
}) {
  return showClientSheet<bool>(
    context,
    _EditUserSheet(repository: repository, person: person),
  );
}

enum _EditStep { personal, emergency, employment, residence, account }

extension on _EditStep {
  String get label => switch (this) {
        _EditStep.personal => 'Personal Information',
        _EditStep.emergency => 'Emergency Contact',
        _EditStep.employment => 'Employment Information',
        _EditStep.residence => 'Residence Assignment',
        _EditStep.account => 'Account & Roles',
      };

  String get description => switch (this) {
        _EditStep.personal => 'Core identity details.',
        _EditStep.emergency => 'Who to contact in an emergency.',
        _EditStep.employment => 'Role, pay basis & compensation.',
        _EditStep.residence => 'Residences & payroll split.',
        _EditStep.account => 'Login roles and access.',
      };
}

class _EditUserSheet extends StatefulWidget {
  final UsersAccessRepository repository;
  final DirectoryPerson person;

  const _EditUserSheet({
    required this.repository,
    required this.person,
  });

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
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
  _EditStep _step = _EditStep.personal;
  bool _loading = true;
  bool _saving = false;
  String? _banner;
  Map<String, String> _errors = {};

  String? _existingPhotoUrl;
  String? _localPhotoPath;

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

  List<({String id, String name})> _residences = const [];
  final Set<String> _residenceIds = {};
  String _primaryResidenceId = '';

  List<({String id, String name, String code})> _roles = const [];

  String get _staffId => widget.person.staffId.trim();
  String get _userId => widget.person.userId.trim();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final residences = await widget.repository.fetchResidences();
    final roles = await widget.repository.fetchRoles();
    Map<String, dynamic> staff = {};
    Map<String, dynamic> user = {};

    if (_staffId.isNotEmpty) {
      final staffResult = await widget.repository.fetchStaff(_staffId);
      staffResult.when(
        success: (m) => staff = m,
        failure: (_) {},
      );
    }
    if (_userId.isNotEmpty) {
      final userResult = await widget.repository.fetchUser(_userId);
      userResult.when(
        success: (m) => user = m,
        failure: (_) {},
      );
    }

    if (!mounted) return;
    residences.when(
      success: (rows) => _residences = rows,
      failure: (_) {},
    );
    roles.when(
      success: (rows) => _roles = rows,
      failure: (_) {},
    );

    _applyLoaded(staff: staff, user: user);
    setState(() => _loading = false);
  }

  void _applyLoaded({
    required Map<String, dynamic> staff,
    required Map<String, dynamic> user,
  }) {
    final source = staff.isNotEmpty ? staff : user;
    final name = JsonCodec.stringOr(
      source['name'] ?? user['name'] ?? widget.person.name,
      widget.person.name,
    );
    final parts = name.trim().split(RegExp(r'\s+'));
    _firstName.text = JsonCodec.stringOr(
      source['firstName'],
      parts.isNotEmpty ? parts.first : '',
    );
    _middleName.text = JsonCodec.stringOr(
      source['middleName'] ?? user['middleName'],
      '',
    );
    _lastName.text = JsonCodec.stringOr(
      source['lastName'],
      parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
    _email.text = JsonCodec.stringOr(
      source['email'] ?? user['email'] ?? widget.person.email,
      widget.person.email,
    );
    _phone.text = JsonCodec.stringOr(
      source['phone'] ?? user['phone'] ?? widget.person.phone,
      widget.person.phone,
    );
    _address.text = JsonCodec.stringOr(source['address'], '');
    _dob = JsonCodec.stringOr(source['dateOfBirth'], '');
    if (_dob.length >= 10) _dob = _dob.substring(0, 10);
    _existingPhotoUrl = DirectoryPerson.fromJson({
      ...source,
      'photoUrl': source['photoUrl'] ?? widget.person.photoUrl,
      'id': widget.person.id,
      'staffId': _staffId,
      'userId': _userId,
      'name': name,
      'email': _email.text,
      'phone': _phone.text,
      'userType': widget.person.userType,
      'status': widget.person.status,
      'accountStatus': widget.person.accountStatus,
      'hasLogin': widget.person.hasLogin,
      'roles': const [],
      'residences': const [],
      'linkedClients': const [],
      'certificationStatus': '',
      'employeeCode': '',
    }).photoUrl;

    _emergencyName.text =
        JsonCodec.stringOr(source['emergencyContactName'], '');
    _emergencyPhone.text =
        JsonCodec.stringOr(source['emergencyContactPhone'], '');
    _alternativeContact.text = JsonCodec.stringOr(
      source['alternativeContactPhone'] ?? source['alternativeContact'],
      '',
    );
    _relationship = JsonCodec.stringOr(
      source['emergencyContactRelationship'] ?? source['relationship'],
      '',
    );

    _employmentType = JsonCodec.stringOr(
      source['employmentType'],
      'full_time',
    );
    final hire = JsonCodec.stringOr(source['hireDate'], '');
    _hireDate = hire.length >= 10 ? hire.substring(0, 10) : hire;
    _status = JsonCodec.stringOr(
      source['status'] ?? widget.person.status,
      'active',
    );
    _paymentDuration = JsonCodec.stringOr(
      source['paymentFrequency'] ?? source['paymentDuration'],
      'fortnightly',
    );
    _paymentBasis = JsonCodec.stringOr(
      source['paymentBasis'] ?? source['employmentBasis'],
      '',
    );
    _medAdminApproved =
        JsonCodec.boolean(source['medAdminApproved']) ?? false;

    _roleIds
      ..clear()
      ..addAll(widget.person.roleIds);
    final rawRoles = user['roles'] ?? source['roles'];
    if (rawRoles is List) {
      for (final item in rawRoles.whereType<Map>()) {
        final id = JsonCodec.stringOr(JsonCodec.asMap(item)['id'], '');
        if (id.isNotEmpty) _roleIds.add(id);
      }
    }

    _residenceIds.clear();
    final rawRes = source['residences'] ?? user['residences'];
    if (rawRes is List) {
      for (final item in rawRes) {
        if (item is Map) {
          final m = JsonCodec.asMap(item);
          final id = JsonCodec.stringOr(m['id'], '');
          if (id.isEmpty) continue;
          _residenceIds.add(id);
          if (JsonCodec.boolean(m['isPrimary']) == true) {
            _primaryResidenceId = id;
          }
        } else if (item is String && item.isNotEmpty) {
          _residenceIds.add(item);
        }
      }
    }
    _primaryResidenceId = JsonCodec.stringOr(
      source['primaryResidenceId'],
      _primaryResidenceId,
    );
    if (_primaryResidenceId.isEmpty && _residenceIds.isNotEmpty) {
      _primaryResidenceId = _residenceIds.first;
    }
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

  void _goTo(_EditStep step) {
    setState(() {
      _step = step;
      _banner = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  bool _stepComplete(_EditStep step) {
    switch (step) {
      case _EditStep.personal:
        return _firstName.text.trim().isNotEmpty &&
            _lastName.text.trim().isNotEmpty &&
            _email.text.trim().isNotEmpty;
      case _EditStep.emergency:
        return _emergencyName.text.trim().isNotEmpty &&
            _emergencyPhone.text.trim().isNotEmpty;
      case _EditStep.employment:
        return true;
      case _EditStep.residence:
        return _residenceIds.isNotEmpty && _primaryResidenceId.isNotEmpty;
      case _EditStep.account:
        return _userId.isEmpty || _roleIds.isNotEmpty;
    }
  }

  Map<String, String> _validateAll() {
    final errors = <String, String>{};
    if (_firstName.text.trim().isEmpty) {
      errors['firstName'] = 'First name is required.';
    }
    if (_lastName.text.trim().isEmpty) {
      errors['lastName'] = 'Last name is required.';
    }
    if (_email.text.trim().isEmpty) {
      errors['email'] = 'Email is required.';
    }
    if (_staffId.isNotEmpty) {
      if (_emergencyName.text.trim().isEmpty) {
        errors['emergencyContactName'] =
            'Emergency contact name is required.';
      }
      if (_emergencyPhone.text.trim().isEmpty) {
        errors['emergencyContactPhone'] =
            'Emergency contact phone is required.';
      }
      if (_residenceIds.isEmpty) {
        errors['residenceIds'] = 'Assign at least one residence.';
      }
      if (_primaryResidenceId.isEmpty) {
        errors['primaryResidenceId'] = 'Choose a primary residence.';
      }
    }
    if (_userId.isNotEmpty && _roleIds.isEmpty) {
      errors['roleIds'] = 'A login needs at least one role.';
    }
    return errors;
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
    setState(() => _localPhotoPath = path);
  }

  Future<void> _save() async {
    if (_saving) return;
    final errors = _validateAll();
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _banner =
            '${errors.length} field${errors.length == 1 ? '' : 's'} still need attention.';
        if (errors.containsKey('firstName') ||
            errors.containsKey('lastName') ||
            errors.containsKey('email')) {
          _step = _EditStep.personal;
        } else if (errors.containsKey('emergencyContactName') ||
            errors.containsKey('emergencyContactPhone')) {
          _step = _EditStep.emergency;
        } else if (errors.containsKey('residenceIds') ||
            errors.containsKey('primaryResidenceId')) {
          _step = _EditStep.residence;
        } else {
          _step = _EditStep.account;
        }
      });
      return;
    }

    setState(() {
      _saving = true;
      _banner = null;
      _errors = {};
    });

    String? photoUrl = _existingPhotoUrl;
    final local = _localPhotoPath;
    if (local != null && local.isNotEmpty) {
      final upload = await widget.repository.uploadFile(
        path: local,
        fileName: local.split('/').last,
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

    if (_staffId.isNotEmpty) {
      final staffBody = <String, dynamic>{
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'middleName': _middleName.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        if (_dob.isNotEmpty) 'dateOfBirth': _dob,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        'emergencyContactName': _emergencyName.text.trim(),
        'emergencyContactPhone': _emergencyPhone.text.trim(),
        if (_relationship.isNotEmpty)
          'emergencyContactRelationship': _relationship,
        'alternativeContactPhone': _alternativeContact.text.trim(),
        'employmentType': _employmentType,
        if (_hireDate.isNotEmpty) 'hireDate': _hireDate,
        'status': _status,
        'paymentFrequency': _paymentDuration,
        if (_paymentBasis.isNotEmpty) 'paymentBasis': _paymentBasis,
        'medAdminApproved': _medAdminApproved,
        'residenceIds': _residenceIds.toList(growable: false),
        'primaryResidenceId': _primaryResidenceId,
      };
      final patch = await widget.repository.patchStaff(_staffId, staffBody);
      if (!mounted) return;
      if (patch.isFailure) {
        setState(() {
          _saving = false;
          _banner = patch.error?.message ?? 'Could not save staff profile.';
        });
        return;
      }
    }

    if (_userId.isNotEmpty) {
      final userPatch = await widget.repository.patchUser(_userId, {
        'name':
            '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        if (_middleName.text.trim().isNotEmpty)
          'middleName': _middleName.text.trim(),
      });
      if (!mounted) return;
      if (userPatch.isFailure) {
        setState(() {
          _saving = false;
          _banner = userPatch.error?.message ?? 'Could not save login.';
        });
        return;
      }

      final roles = await widget.repository.replaceUserRoles(
        userId: _userId,
        roleIds: _roleIds.toList(growable: false),
      );
      if (!mounted) return;
      if (roles.isFailure) {
        setState(() {
          _saving = false;
          _banner = roles.error?.message ?? 'Could not update roles.';
        });
        return;
      }

      if (_residenceIds.isNotEmpty) {
        final residences = await widget.repository.replaceUserResidences(
          userId: _userId,
          residenceIds: _residenceIds.toList(growable: false),
          primaryResidenceId: _primaryResidenceId,
        );
        if (!mounted) return;
        if (residences.isFailure) {
          // Staff patch may already have residences; soft-warn only.
          AppSnackbar.show(
            'Residences',
            residences.error?.message ??
                'Profile saved, but residence sync failed.',
            force: true,
          );
        }
      }
    }

    if (!mounted) return;
    AppSnackbar.show(
      'Changes saved',
      '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
      force: true,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final index = _step.index;
    final total = _EditStep.values.length;
    final percent = (((index + 1) / total) * 100).round();

    return ClientSheetFrame(
      icon: Icons.manage_accounts_outlined,
      title: 'Edit User',
      description: widget.person.name,
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
            TextSpan(text: ' Required fields · Changes apply to this person.'),
          ],
        ),
      ),
      top: ClientStepChips(
        current: _step.name,
        onTap: (id) => _goTo(_EditStep.values.byName(id)),
        steps: [
          for (final s in _EditStep.values)
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
                : () => _goTo(_EditStep.values[index - 1]),
          ),
        if (_step != _EditStep.account)
          HandoverButton(
            label: 'Next',
            filled: true,
            onPressed: _saving
                ? null
                : () => _goTo(_EditStep.values[index + 1]),
          )
        else
          HandoverButton(
            label: _saving ? 'Saving…' : 'Save',
            filled: true,
            onPressed: _saving ? null : _save,
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
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          switch (_step) {
            _EditStep.personal => _personal(),
            _EditStep.emergency => _emergency(),
            _EditStep.employment => _employment(),
            _EditStep.residence => _residence(),
            _EditStep.account => _account(),
          },
      ],
    );
  }

  Widget _personal() {
    final photoName = _localPhotoPath?.split('/').last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _EditStep.personal.label,
          description: _EditStep.personal.description,
        ),
        _gap,
        ClientFileField(
          label: 'User Photo',
          hint: 'JPG, PNG, WebP or HEIC · up to 25MB',
          fileName: photoName,
          existingUrl: photoName == null ? _existingPhotoUrl : null,
          onPick: _saving ? null : _pickPhoto,
          onClear: (_localPhotoPath == null && _existingPhotoUrl == null)
              ? null
              : () => setState(() {
                    _localPhotoPath = null;
                    _existingPhotoUrl = null;
                  }),
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
          error: _errors['email'],
          onChanged: (_) => _changed(),
        ),
        _gap,
        ClientInput(
          label: 'Phone',
          controller: _phone,
          enabled: !_saving,
          keyboardType: TextInputType.phone,
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
          title: _EditStep.emergency.label,
          description: _EditStep.emergency.description,
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
          title: _EditStep.employment.label,
          description: _EditStep.employment.description,
        ),
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
          value: _hireDate,
          enabled: !_saving,
          onChanged: (v) => setState(() => _hireDate = v),
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
          value: _paymentDuration,
          placeholder: 'Select duration',
          options: _paymentDurations,
          enabled: !_saving,
          onChanged: (v) => setState(() => _paymentDuration = v),
        ),
        _gap,
        ClientSelect(
          label: 'Payment Basis',
          value: _paymentBasis,
          placeholder: 'Select how this person is paid',
          options: _paymentBases,
          enabled: !_saving,
          onChanged: (v) => setState(() => _paymentBasis = v),
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
      ],
    );
  }

  Widget _residence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _EditStep.residence.label,
          description: 'Assign this user to one or more residences.',
        ),
        _gap,
        clientFieldLabel(context, 'Assigned Residences', required: true),
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
                          _primaryResidenceId =
                              _residenceIds.isEmpty ? '' : _residenceIds.first;
                        }
                      }
                    }),
          ),
        clientFieldHelper(context, error: _errors['residenceIds']),
        _gap,
        ClientSelect(
          label: 'Primary Residence',
          required: true,
          value: _primaryResidenceId,
          placeholder: 'Select primary',
          options: [
            for (final r in _residences)
              if (_residenceIds.contains(r.id)) (r.id, r.name),
          ],
          enabled: !_saving && _residenceIds.isNotEmpty,
          error: _errors['primaryResidenceId'],
          onChanged: (v) => setState(() => _primaryResidenceId = v),
        ),
      ],
    );
  }

  Widget _account() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(
          title: _EditStep.account.label,
          description: _userId.isEmpty
              ? 'This person has no login yet.'
              : 'Roles decide what this login may do.',
        ),
        _gap,
        if (_userId.isEmpty)
          Text(
            'No login account is linked. Use the row menu to invite or create access later.',
            style: handoverText(context, 13, color: AppColors.textMuted),
          )
        else ...[
          clientFieldLabel(context, 'Staff Roles', required: true),
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
                          }),
                ),
            ],
          ),
          clientFieldHelper(context, error: _errors['roleIds']),
        ],
        _gap,
        HandoverButton(
          label: _saving ? 'Saving…' : 'Save changes',
          filled: true,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
