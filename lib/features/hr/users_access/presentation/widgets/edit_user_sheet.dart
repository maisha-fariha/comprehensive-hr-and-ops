import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const _relationships = <(String, String)>[
    ('spouse', 'Spouse'),
    ('parent', 'Parent'),
    ('child', 'Child'),
    ('sibling', 'Sibling'),
    ('friend', 'Friend'),
    ('caseworker', 'Caseworker'),
    ('other', 'Other'),
  ];

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

  static const _paymentDurations = <(String, String)>[
    ('weekly', 'Weekly'),
    ('bi_weekly', 'Fortnightly'),
    ('semi_monthly', 'Twice a month'),
    ('monthly', 'Monthly'),
  ];

  static const _paymentBases = <(String, String)>[
    ('hourly_based', 'Hourly based'),
    ('salary_based', 'Salary based'),
    ('shift_based', 'Shift based'),
  ];

  static const _shiftTypes = <(String, String)>[
    ('any', 'Any shift'),
    ('day', 'Day'),
    ('evening', 'Evening'),
    ('night', 'Night'),
    ('weekend', 'Weekend'),
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
  String _paymentDuration = 'bi_weekly';
  String _paymentBasis = '';
  bool _medAdminApproved = false;

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
    _address.text = JsonCodec.stringOr(
      source['addressLine1'] ?? source['address'],
      '',
    );
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

    final emergency = JsonCodec.mapAt(source, 'emergencyContact') ?? const {};
    _emergencyName.text = JsonCodec.stringOr(
      emergency['name'] ?? source['emergencyContactName'],
      '',
    );
    _emergencyPhone.text = JsonCodec.stringOr(
      emergency['phone'] ?? source['emergencyContactPhone'],
      '',
    );
    _alternativeContact.text = JsonCodec.stringOr(
      emergency['altPhone'] ??
          source['alternativeContactPhone'] ??
          source['alternativeContact'],
      '',
    );
    var relationship = JsonCodec.stringOr(
      emergency['relationship'] ??
          source['emergencyContactRelationship'] ??
          source['relationship'],
      '',
    ).toLowerCase();
    if (relationship == 'case worker') relationship = 'caseworker';
    _relationship = relationship;

    _employmentType = JsonCodec.stringOr(
      source['employmentType'],
      'full_time',
    );
    if (_employmentType == 'casual') _employmentType = 'prn';
    final hire = JsonCodec.stringOr(source['hireDate'], '');
    _hireDate = hire.length >= 10 ? hire.substring(0, 10) : hire;
    _status = JsonCodec.stringOr(
      source['status'] ?? widget.person.status,
      'active',
    );
    var duration = JsonCodec.stringOr(
      source['paymentDuration'] ?? source['paymentFrequency'],
      'bi_weekly',
    );
    if (duration == 'fortnightly') duration = 'bi_weekly';
    _paymentDuration = duration;
    var basis = JsonCodec.stringOr(
      source['employmentBasis'] ?? source['paymentBasis'],
      '',
    );
    if (basis == 'hourly') basis = 'hourly_based';
    if (basis == 'contract') basis = 'shift_based';
    _paymentBasis = basis;
    _medAdminApproved =
        JsonCodec.boolean(source['medAdminApproved']) ?? false;

    final cfg = JsonCodec.mapAt(source, 'employmentConfig') ?? const {};
    String money(dynamic v) {
      final n = JsonCodec.number(v);
      if (n == null) return '';
      return n == n.roundToDouble() ? '${n.toInt()}' : '$n';
    }

    _hourlyRate.text = money(cfg['hourlyRate'] ?? source['hourlyRate']);
    _overtimeRate.text = money(cfg['overtimeRate']);
    _attendanceRequired =
        JsonCodec.boolean(cfg['attendanceRequired']) ?? true;
    _monthlySalary.text = money(cfg['monthlySalary']);
    _allowances.text = money(cfg['allowances']);
    _deductions.text = money(cfg['deductions']);
    _shiftRate.text = money(cfg['shiftRate']);
    _shiftType = JsonCodec.stringOr(cfg['shiftType'], 'any');
    if (_shiftType.isEmpty) _shiftType = 'any';
    _overtimeAfterHours.text = money(cfg['overtimeAfterHours']);

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
      _hourlyRate,
      _overtimeRate,
      _monthlySalary,
      _allowances,
      _deductions,
      _shiftRate,
      _overtimeAfterHours,
    ]) {
      c.dispose();
    }
    super.dispose();
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

  void _goTo(_EditStep step) {
    setState(() {
      _step = step;
      _banner = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  bool _rateValidForBasis() {
    switch (_paymentBasis) {
      case 'hourly_based':
        return _numOrNull(_hourlyRate.text) != null;
      case 'salary_based':
        return _numOrNull(_monthlySalary.text) != null;
      case 'shift_based':
        return _numOrNull(_shiftRate.text) != null;
      default:
        return true;
    }
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
        return _rateValidForBasis();
      case _EditStep.residence:
        return _residenceIds.isNotEmpty && _primaryResidenceId.isNotEmpty;
      case _EditStep.account:
        return _userId.isEmpty || _roleIds.isNotEmpty;
    }
  }

  Map<String, String> _validateStep(_EditStep step) {
    final errors = <String, String>{};
    switch (step) {
      case _EditStep.personal:
        if (_firstName.text.trim().isEmpty) {
          errors['firstName'] = 'First name is required.';
        }
        if (_lastName.text.trim().isEmpty) {
          errors['lastName'] = 'Last name is required.';
        }
        if (_email.text.trim().isEmpty) {
          errors['email'] = 'Email is required.';
        }
      case _EditStep.emergency:
        if (_staffId.isNotEmpty) {
          if (_emergencyName.text.trim().isEmpty) {
            errors['emergencyContactName'] =
                'Emergency contact name is required.';
          }
          if (_emergencyPhone.text.trim().isEmpty) {
            errors['emergencyContactPhone'] =
                'Emergency contact phone is required.';
          }
        }
      case _EditStep.employment:
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
      case _EditStep.residence:
        if (_staffId.isNotEmpty) {
          if (_residenceIds.isEmpty) {
            errors['residenceIds'] = 'Assign at least one residence.';
          }
          if (_primaryResidenceId.isEmpty) {
            errors['primaryResidenceId'] = 'Choose a primary residence.';
          }
        }
      case _EditStep.account:
        if (_userId.isNotEmpty && _roleIds.isEmpty) {
          errors['roleIds'] = 'A login needs at least one role.';
        }
    }
    return errors;
  }

  _EditStep _stepOf(String field) => switch (field) {
        'firstName' || 'lastName' || 'email' => _EditStep.personal,
        'emergencyContactName' ||
        'emergencyContactPhone' =>
          _EditStep.emergency,
        'hourlyRate' || 'monthlySalary' || 'shiftRate' => _EditStep.employment,
        'residenceIds' || 'primaryResidenceId' => _EditStep.residence,
        _ => _EditStep.account,
      };

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

  void _jump(_EditStep step) {
    if (step.index > _step.index && !_stepValid()) return;
    _goTo(step);
  }

  void _next() {
    if (!_stepValid()) return;
    if (_step.index < _EditStep.values.length - 1) {
      _goTo(_EditStep.values[_step.index + 1]);
      return;
    }
    _save();
  }

  Map<String, String> _validateAll() {
    final errors = <String, String>{};
    for (final step in _EditStep.values) {
      errors.addAll(_validateStep(step));
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
        } else if (errors.containsKey('hourlyRate') ||
            errors.containsKey('monthlySalary') ||
            errors.containsKey('shiftRate')) {
          _step = _EditStep.employment;
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
      final config = _employmentConfig();
      final staffBody = <String, dynamic>{
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'middleName': _middleName.text.trim(),
        'phone': _phone.text.trim(),
        'addressLine1': _address.text.trim(),
        if (_dob.isNotEmpty) 'dateOfBirth': _dob,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        'emergencyContact': {
          'name': _emergencyName.text.trim(),
          'phone': _emergencyPhone.text.trim(),
          if (_relationship.isNotEmpty) 'relationship': _relationship,
          if (_alternativeContact.text.trim().isNotEmpty)
            'altPhone': _alternativeContact.text.trim(),
        },
        'employmentType': _employmentType,
        if (_hireDate.isNotEmpty) 'hireDate': _hireDate,
        'status': _status,
        'paymentDuration': _paymentDuration,
        if (_paymentBasis.isNotEmpty) 'employmentBasis': _paymentBasis,
        if (config != null) 'employmentConfig': config,
        if (_paymentBasis == 'hourly_based' &&
            _numOrNull(_hourlyRate.text) != null)
          'hourlyRate': _numOrNull(_hourlyRate.text),
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
        onTap: (id) => _jump(_EditStep.values.byName(id)),
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
            onPressed: _saving ? null : _next,
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
        ),
        _gap,
        ClientInput(
          label: 'Middle Name',
          controller: _middleName,
          enabled: !_saving,
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
          error: _errors['email'],
        ),
        _gap,
        ClientInput(
          label: 'Phone',
          controller: _phone,
          enabled: !_saving,
          keyboardType: TextInputType.phone,
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
