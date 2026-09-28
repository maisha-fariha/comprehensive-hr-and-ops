import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/staff_residence.dart';
import '../../domain/repositories/staff_extras_repository.dart';

/// Web-matched 5-step Edit Residence wizard (Residences Management).
class StaffResidenceEditPage extends StatefulWidget {
  final StaffResidence residence;

  const StaffResidenceEditPage({super.key, required this.residence});

  @override
  State<StaffResidenceEditPage> createState() => _StaffResidenceEditPageState();
}

class _StaffResidenceEditPageState extends State<StaffResidenceEditPage> {
  static const _steps = [
    ('Basic Information', 'Name, type & status'),
    ('Address & Location', 'Address & GPS geofence'),
    ('Capacity & Operations', 'Beds & operating hours'),
    ('Management & Staff', 'Managers & care team'),
    ('Review & Create', 'Confirm and register'),
  ];

  static const _typeOptions = [
    'assisted_living_nursing_homes',
    'group_home',
  ];

  static const _countries = [
    'United States',
    'Bangladesh',
    'United Kingdom',
    'Canada',
    'Australia',
  ];

  static const _timezones = [
    'America/Los_Angeles',
    'America/New_York',
    'Asia/Dhaka',
    'Europe/London',
    'UTC',
  ];

  static const _serviceTypes = [
    'Residential Care',
    'Residential care',
    'Assisted Living',
    'Nursing Care',
  ];

  late final StaffExtrasRepository _repository;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _emergency;
  late final TextEditingController _address1;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postal;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _gpsRadius;
  late final TextEditingController _capacity;
  late final TextEditingController _operatingHours;
  late final TextEditingController _notes;
  late final TextEditingController _managementPhone;
  late final TextEditingController _managementEmail;

  late String _residenceType;
  late String _status;
  late String _country;
  late String _timezone;
  late String _serviceType;
  late bool _gpsEnabled;
  String? _primaryManagerId;
  String? _assistantManagerId;
  late List<StaffResidencePerson> _assignedStaff;
  late List<StaffResidencePerson> _careTeam;
  List<StaffResidencePerson> _directory = const [];
  int _step = 0;
  bool _saving = false;
  bool _loadingDirectory = true;

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    final r = widget.residence;
    _name = TextEditingController(text: r.name.trim());
    _phone = TextEditingController(text: r.phone ?? '');
    _emergency = TextEditingController(text: r.emergencyPhone ?? '');
    _address1 = TextEditingController(text: r.addressLine1 ?? '');
    _city = TextEditingController(text: r.city ?? '');
    _state = TextEditingController(text: r.stateProvince ?? '');
    _postal = TextEditingController(text: r.postalCode ?? '');
    _latitude = TextEditingController(
      text: r.latitude?.toString() ?? '',
    );
    _longitude = TextEditingController(
      text: r.longitude?.toString() ?? '',
    );
    _gpsRadius = TextEditingController(
      text: r.geofenceRadiusMeters?.toString() ?? '',
    );
    _capacity = TextEditingController(text: r.bedCapacity?.toString() ?? '');
    _operatingHours = TextEditingController(text: r.operatingHours ?? '');
    _notes = TextEditingController(text: r.notes ?? '');
    _managementPhone = TextEditingController(text: r.managementPhone ?? '');
    _managementEmail = TextEditingController(text: r.managementEmail ?? '');

    _residenceType = _normalizeType(r.residenceType);
    _status = r.status.trim().isEmpty ? 'active' : r.status.trim().toLowerCase();
    if (_status == 'archived') _status = 'inactive';
    _country = (r.country ?? '').trim().isEmpty
        ? 'United States'
        : r.country!.trim();
    if (!_countries.contains(_country)) {
      _countries; // keep custom via dropdown items below
    }
    _timezone = (r.timezone ?? '').trim().isEmpty
        ? 'America/Los_Angeles'
        : r.timezone!.trim();
    _serviceType = r.serviceType.trim().isEmpty
        ? 'Residential Care'
        : r.serviceType.trim();
    _gpsEnabled = r.gpsTrackingEnabled || (r.geofenceRadiusMeters ?? 0) > 0;
    _primaryManagerId = r.primaryManager?.id;
    _assistantManagerId = r.assistantManager?.id;
    _assignedStaff = List.of(r.assignedStaff);
    _careTeam = List.of(r.careTeam);
    _loadDirectory();
  }

  String _normalizeType(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('group')) return 'group_home';
    if (value.contains('nursing') || value.contains('assisted')) {
      return 'assisted_living_nursing_homes';
    }
    return value.isEmpty ? 'assisted_living_nursing_homes' : raw.trim();
  }

  String get _apiResidenceType {
    if (_residenceType == 'assisted_living_nursing_homes') return 'nursing_home';
    if (_residenceType == 'group_home') return 'group_home';
    return _residenceType;
  }

  Future<void> _loadDirectory() async {
    final result = await _repository.getStaffDirectoryOptions();
    if (!mounted) return;
    result.when(
      success: (people) => setState(() {
        _directory = people;
        _loadingDirectory = false;
      }),
      failure: (_) => setState(() => _loadingDirectory = false),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _emergency.dispose();
    _address1.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _gpsRadius.dispose();
    _capacity.dispose();
    _operatingHours.dispose();
    _notes.dispose();
    _managementPhone.dispose();
    _managementEmail.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final capacity = int.tryParse(_capacity.text.trim());
    final radius = int.tryParse(_gpsRadius.text.trim());
    final lat = double.tryParse(_latitude.text.trim());
    final lng = double.tryParse(_longitude.text.trim());
    return {
      'name': _name.text.trim(),
      'phone': _nullIfEmpty(_phone.text),
      'emergencyPhone': _nullIfEmpty(_emergency.text),
      'residenceType': _apiResidenceType,
      'status': _status == 'inactive' ? 'inactive' : _status,
      'addressLine1': _nullIfEmpty(_address1.text),
      'city': _nullIfEmpty(_city.text),
      'stateProvince': _nullIfEmpty(_state.text),
      'postalCode': _nullIfEmpty(_postal.text),
      'country': _nullIfEmpty(_country),
      'timezone': _nullIfEmpty(_timezone),
      'serviceType': _nullIfEmpty(_serviceType),
      'operatingHours': _nullIfEmpty(_operatingHours.text),
      'notes': _nullIfEmpty(_notes.text),
      'managementPhone': _nullIfEmpty(_managementPhone.text),
      'managementEmail': _nullIfEmpty(_managementEmail.text),
      if (capacity != null) 'bedCapacity': capacity,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
      'geofence': _gpsEnabled
          ? {
              'radiusMeters': radius ?? 0,
              'enabled': true,
            }
          : {
              'radiusMeters': radius,
              'enabled': false,
            },
      'primaryManagerId': _primaryManagerId,
      'assistantManagerId': _assistantManagerId,
      'assignedStaffIds': _assignedStaff.map((e) => e.id).toList(),
      'careTeamIds': _careTeam.map((e) => e.id).toList(),
    };
  }

  String? _nullIfEmpty(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save({bool closeAfter = true}) async {
    if (_name.text.trim().isEmpty) {
      Get.snackbar(
        'Name required',
        'Enter a residence name.',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() => _step = 0);
      return;
    }
    setState(() => _saving = true);
    final result = await _repository.updateResidence(
      residenceId: widget.residence.id,
      fields: _payload(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        Get.snackbar(
          'Residence updated',
          'Changes were saved.',
          snackPosition: SnackPosition.BOTTOM,
        );
        if (closeAfter) Get.back(result: true);
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not update residence',
      ),
    );
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step += 1);
      return;
    }
    _save();
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  String? _personName(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final person in _directory) {
      if (person.id == id) return person.name;
    }
    if (widget.residence.primaryManager?.id == id) {
      return widget.residence.primaryManager!.name;
    }
    if (widget.residence.assistantManager?.id == id) {
      return widget.residence.assistantManager!.name;
    }
    return id;
  }

  int get _availableBeds {
    final capacity = int.tryParse(_capacity.text.trim()) ??
        widget.residence.bedCapacity ??
        0;
    final occupied = widget.residence.occupiedBeds ?? 0;
    final free = capacity - occupied;
    return free < 0 ? 0 : free;
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((_step + 1) / _steps.length * 100).round();
    return Scaffold(
      key: const Key('staff-residence-edit-page'),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              residenceId: widget.residence.id,
              onClose: () => Get.back(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _StepRail(
                    steps: _steps,
                    current: _step,
                    progress: progress,
                    onSelect: (i) => setState(() => _step = i),
                    tip: _stepTip(_step),
                  ),
                  const SizedBox(height: 12),
                  _LivePreview(
                    name: _name.text.trim().isEmpty
                        ? 'Residence'
                        : _name.text.trim(),
                    typeBadge: _apiResidenceType.toUpperCase(),
                    type: _apiResidenceType,
                    status: _status,
                    location: [
                      _city.text.trim(),
                      _state.text.trim(),
                    ].where((e) => e.isNotEmpty).join(', '),
                    phone: _phone.text.trim(),
                    capacity:
                        '${widget.residence.occupiedBeds ?? 0} / ${_capacity.text.trim().isEmpty ? (widget.residence.bedCapacity ?? '—') : _capacity.text.trim()}',
                    completedSteps: _step,
                  ),
                  const SizedBox(height: 12),
                  _buildStep(),
                ],
              ),
            ),
            _Footer(
              step: _step,
              total: _steps.length,
              saving: _saving,
              onCancel: () => Get.back(),
              onBack: _step == 0 ? null : _back,
              onSave: () => _save(closeAfter: true),
              onNext: _step == _steps.length - 1 ? null : _next,
              onFinish: _step == _steps.length - 1 ? () => _save() : null,
            ),
          ],
        ),
      ),
    );
  }

  String _stepTip(int step) {
    switch (step) {
      case 0:
        return 'Residences created as Pending stay hidden from staff until an admin activates them.';
      case 1:
        return 'Accurate GPS coordinates enable staff geofenced clock-in and location verification.';
      case 2:
        return 'Availability is calculated on the server as (Total − Occupied).';
      case 3:
        return 'The Primary Manager receives all escalations and compliance alerts for this residence.';
      default:
        return 'Once created, the residence appears in the directory and can accept client assignments.';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _BasicStep(
          name: _name,
          phone: _phone,
          emergency: _emergency,
          residenceType: _residenceType,
          status: _status,
          typeOptions: _typeOptions,
          onType: (v) => setState(() => _residenceType = v),
          onStatus: (v) => setState(() => _status = v),
          onChanged: () => setState(() {}),
        );
      case 1:
        return _AddressStep(
          address1: _address1,
          city: _city,
          state: _state,
          postal: _postal,
          country: _country,
          countries: {
            ..._countries,
            if (_country.isNotEmpty) _country,
          }.toList(),
          latitude: _latitude,
          longitude: _longitude,
          timezone: _timezone,
          timezones: {
            ..._timezones,
            if (_timezone.isNotEmpty) _timezone,
          }.toList(),
          gpsRadius: _gpsRadius,
          gpsEnabled: _gpsEnabled,
          onCountry: (v) => setState(() => _country = v),
          onTimezone: (v) => setState(() => _timezone = v),
          onGpsEnabled: (v) => setState(() => _gpsEnabled = v),
          onChanged: () => setState(() {}),
        );
      case 2:
        return _CapacityStep(
          capacity: _capacity,
          availableBeds: _availableBeds,
          occupiedBeds: widget.residence.occupiedBeds ?? 0,
          operatingHours: _operatingHours,
          serviceType: _serviceType,
          serviceTypes: {
            ..._serviceTypes,
            if (_serviceType.isNotEmpty) _serviceType,
          }.toList(),
          notes: _notes,
          onServiceType: (v) => setState(() => _serviceType = v),
          onChanged: () => setState(() {}),
        );
      case 3:
        return _ManagementStep(
          loadingDirectory: _loadingDirectory,
          directory: _directory,
          primaryManagerId: _primaryManagerId,
          assistantManagerId: _assistantManagerId,
          assignedStaff: _assignedStaff,
          careTeam: _careTeam,
          managementPhone: _managementPhone,
          managementEmail: _managementEmail,
          personName: _personName,
          onPrimary: (id) => setState(() => _primaryManagerId = id),
          onAssistant: (id) => setState(() => _assistantManagerId = id),
          onAddAssigned: (person) => setState(() {
            if (_assignedStaff.any((e) => e.id == person.id)) return;
            _assignedStaff = [..._assignedStaff, person];
          }),
          onRemoveAssigned: (id) => setState(() {
            _assignedStaff =
                _assignedStaff.where((e) => e.id != id).toList();
          }),
          onAddCare: (person) => setState(() {
            if (_careTeam.any((e) => e.id == person.id)) return;
            _careTeam = [..._careTeam, person];
          }),
          onRemoveCare: (id) => setState(() {
            _careTeam = _careTeam.where((e) => e.id != id).toList();
          }),
          onChanged: () => setState(() {}),
        );
      default:
        return _ReviewStep(
          name: _name.text.trim(),
          type: _apiResidenceType,
          status: _status,
          emergency: _emergency.text.trim(),
          address: _address1.text.trim(),
          cityRegion: [
            _city.text.trim(),
            _state.text.trim(),
          ].where((e) => e.isNotEmpty).join(', '),
          country: _country,
          coordinates: [
            _latitude.text.trim(),
            _longitude.text.trim(),
          ].where((e) => e.isNotEmpty).join(', '),
          geofence:
              '${_gpsRadius.text.trim().isEmpty ? '—' : '${_gpsRadius.text.trim()} m'} · GPS tracking ${_gpsEnabled ? 'on' : 'off'}',
          capacity: _capacity.text.trim(),
          operatingHours: _operatingHours.text.trim(),
          serviceType: _serviceType,
          notes: _notes.text.trim(),
          primaryManager: _personName(_primaryManagerId) ?? '—',
          assistantManager: _personName(_assistantManagerId) ?? '—',
          onEditStep: (step) => setState(() => _step = step),
        );
    }
  }
}

// ── Shared chrome ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String residenceId;
  final VoidCallback onClose;

  const _Header({required this.residenceId, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Residence',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 18),
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Residence Setup · #${residenceId.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Register a new residence, set its address, capacity and leadership.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  final List<(String, String)> steps;
  final int current;
  final int progress;
  final ValueChanged<int> onSelect;
  final String tip;

  const _StepRail({
    required this.steps,
    required this.current,
    required this.progress,
    required this.onSelect,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    _StepDot(
                      index: i,
                      current: current,
                      done: i < current,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: i == current
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textHeading,
                            ),
                          ),
                          Text(
                            steps[i].$2,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'FORM COMPLETION  STEP ${current + 1} OF ${steps.length}',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 7,
              backgroundColor: AppColors.filterButtonBackground,
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$progress% complete',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.infoBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      color: AppColors.infoBlue,
                      height: 1.35,
                    ),
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

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final bool done;

  const _StepDot({
    required this.index,
    required this.current,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.activeGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    final active = index == current;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryNavy : AppColors.filterButtonBackground,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: active ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final String name;
  final String typeBadge;
  final String type;
  final String status;
  final String location;
  final String phone;
  final String capacity;
  final int completedSteps;

  const _LivePreview({
    required this.name,
    required this.typeBadge,
    required this.type,
    required this.status,
    required this.location,
    required this.phone,
    required this.capacity,
    required this.completedSteps,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = status.isEmpty
        ? '—'
        : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Residence Preview',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        typeBadge,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _previewRow('Type', type),
                Row(
                  children: [
                    const SizedBox(
                      width: 72,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.activeBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.activeGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _previewRow('Phone', phone.isEmpty ? '—' : phone),
                _previewRow('Capacity', capacity),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Setup Progress',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    i < completedSteps
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: i < completedSteps
                        ? AppColors.activeGreen
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    [
                      'Basic information',
                      'Address & location',
                      'Capacity & operations',
                      'Management & staff',
                    ][i],
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.urgentBackgroundSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.star_rounded, size: 16, color: AppColors.urgentAmber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Almost there — Complete all 5 steps to register the residence into the directory.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      color: AppColors.urgentAmber,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int step;
  final int total;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final VoidCallback onSave;
  final VoidCallback? onNext;
  final VoidCallback? onFinish;

  const _Footer({
    required this.step,
    required this.total,
    required this.saving,
    required this.onCancel,
    required this.onBack,
    required this.onSave,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step ${step + 1} of $total',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onBack != null)
                OutlinedButton(onPressed: onBack, child: const Text('Back'))
              else
                OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              OutlinedButton(
                key: const Key('staff-residence-edit-save'),
                onPressed: saving ? null : onSave,
                child: const Text('Save Changes'),
              ),
              FilledButton(
                onPressed: saving ? null : (isLast ? onFinish : onNext),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                ),
                child: Text(isLast ? 'Save Changes' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Steps ────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const _Card({required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final IconData? icon;
  final int maxLines;
  final String? helper;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
    this.icon,
    this.maxLines = 1,
    this.helper,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textHeading,
            ),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon:
                  icon == null ? null : Icon(icon, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryTeal),
              ),
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                helper!,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = items.contains(value) ? value : (items.isEmpty ? value : items.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surfaceWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: safeValue,
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

class _BasicStep extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController emergency;
  final String residenceType;
  final String status;
  final List<String> typeOptions;
  final ValueChanged<String> onType;
  final ValueChanged<String> onStatus;
  final VoidCallback onChanged;

  const _BasicStep({
    required this.name,
    required this.phone,
    required this.emergency,
    required this.residenceType,
    required this.status,
    required this.typeOptions,
    required this.onType,
    required this.onStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          title: 'Basic Information',
          children: [
            _Field(
              label: 'Residence Name *',
              controller: name,
              onChanged: (_) => onChanged(),
            ),
            _Field(
              label: 'Phone Number',
              controller: phone,
              keyboard: TextInputType.phone,
              icon: Icons.phone_outlined,
              onChanged: (_) => onChanged(),
            ),
            _Field(
              label: 'Emergency Contact Number',
              controller: emergency,
              keyboard: TextInputType.phone,
              icon: Icons.phone_outlined,
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
        _Card(
          title: 'Residence Type',
          children: [
            for (final option in typeOptions) ...[
              _SelectTile(
                label: option,
                selected: residenceType == option,
                onTap: () => onType(option),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
        _Card(
          title: 'Status',
          children: [
            _StatusTile(
              label: 'Active',
              icon: Icons.check_circle,
              color: AppColors.activeGreen,
              selected: status == 'active',
              onTap: () => onStatus('active'),
            ),
            const SizedBox(height: 8),
            _StatusTile(
              label: 'Pending',
              icon: Icons.schedule,
              color: AppColors.urgentAmber,
              selected: status == 'pending',
              onTap: () => onStatus('pending'),
            ),
            const SizedBox(height: 8),
            _StatusTile(
              label: 'Inactive',
              icon: Icons.cancel,
              color: AppColors.criticalRed,
              selected: status == 'inactive',
              onTap: () => onStatus('inactive'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.infoBlue : AppColors.cardBorder,
            width: selected ? 1.6 : 1,
          ),
          color: selected ? AppColors.infoBackground : AppColors.surfaceWhite,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.infoBlue : AppColors.textHeading,
          ),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.cardBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressStep extends StatelessWidget {
  final TextEditingController address1;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController postal;
  final String country;
  final List<String> countries;
  final TextEditingController latitude;
  final TextEditingController longitude;
  final String timezone;
  final List<String> timezones;
  final TextEditingController gpsRadius;
  final bool gpsEnabled;
  final ValueChanged<String> onCountry;
  final ValueChanged<String> onTimezone;
  final ValueChanged<bool> onGpsEnabled;
  final VoidCallback onChanged;

  const _AddressStep({
    required this.address1,
    required this.city,
    required this.state,
    required this.postal,
    required this.country,
    required this.countries,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.timezones,
    required this.gpsRadius,
    required this.gpsEnabled,
    required this.onCountry,
    required this.onTimezone,
    required this.onGpsEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          title: 'Address Details',
          children: [
            _Field(
              label: 'Street Address',
              controller: address1,
              onChanged: (_) => onChanged(),
            ),
            _Field(label: 'City', controller: city, onChanged: (_) => onChanged()),
            _Field(
              label: 'State / Region',
              controller: state,
              onChanged: (_) => onChanged(),
            ),
            _Field(
              label: 'Postal Code',
              controller: postal,
              onChanged: (_) => onChanged(),
            ),
            _DropdownField(
              label: 'Country',
              value: country,
              items: countries,
              onChanged: onCountry,
            ),
          ],
        ),
        _Card(
          title: 'GPS Coordinates & Geofence',
          children: [
            _Field(
              label: 'Latitude',
              controller: latitude,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onChanged(),
            ),
            _Field(
              label: 'Longitude',
              controller: longitude,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onChanged(),
            ),
            _DropdownField(
              label: 'Time Zone',
              value: timezone,
              items: timezones,
              onChanged: onTimezone,
            ),
            _Field(
              label: 'Geofence Radius (meters)',
              controller: gpsRadius,
              keyboard: TextInputType.number,
              helper: 'Radius used to validate staff clock-in proximity.',
              onChanged: (_) => onChanged(),
            ),
            // Avoid SwitchListTile inside DecoratedBox (Material ink assertion).
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Enable GPS Tracking',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: gpsEnabled,
                    activeThumbColor: AppColors.secondaryTeal,
                    onChanged: onGpsEnabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CapacityStep extends StatelessWidget {
  final TextEditingController capacity;
  final int availableBeds;
  final int occupiedBeds;
  final TextEditingController operatingHours;
  final String serviceType;
  final List<String> serviceTypes;
  final TextEditingController notes;
  final ValueChanged<String> onServiceType;
  final VoidCallback onChanged;

  const _CapacityStep({
    required this.capacity,
    required this.availableBeds,
    required this.occupiedBeds,
    required this.operatingHours,
    required this.serviceType,
    required this.serviceTypes,
    required this.notes,
    required this.onServiceType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          title: 'Bed Capacity',
          children: [
            _Field(
              label: 'Total Capacity / Beds',
              controller: capacity,
              keyboard: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
            _ReadValue(
              label: 'Available Beds',
              value: '$availableBeds calculated',
            ),
            _ReadValue(
              label: 'Occupied Beds',
              value: '$occupiedBeds in use',
            ),
            const Text(
              'Availability is calculated on the server as (Total − Occupied).',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        _Card(
          title: 'Operations',
          children: [
            _Field(
              label: 'Operating Hours',
              controller: operatingHours,
              onChanged: (_) => onChanged(),
            ),
            _DropdownField(
              label: 'Service Type',
              value: serviceType,
              items: serviceTypes,
              onChanged: onServiceType,
            ),
            _Field(
              label: 'Notes',
              controller: notes,
              maxLines: 4,
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadValue extends StatelessWidget {
  final String label;
  final String value;

  const _ReadValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementStep extends StatelessWidget {
  final bool loadingDirectory;
  final List<StaffResidencePerson> directory;
  final String? primaryManagerId;
  final String? assistantManagerId;
  final List<StaffResidencePerson> assignedStaff;
  final List<StaffResidencePerson> careTeam;
  final TextEditingController managementPhone;
  final TextEditingController managementEmail;
  final String? Function(String? id) personName;
  final ValueChanged<String?> onPrimary;
  final ValueChanged<String?> onAssistant;
  final ValueChanged<StaffResidencePerson> onAddAssigned;
  final ValueChanged<String> onRemoveAssigned;
  final ValueChanged<StaffResidencePerson> onAddCare;
  final ValueChanged<String> onRemoveCare;
  final VoidCallback onChanged;

  const _ManagementStep({
    required this.loadingDirectory,
    required this.directory,
    required this.primaryManagerId,
    required this.assistantManagerId,
    required this.assignedStaff,
    required this.careTeam,
    required this.managementPhone,
    required this.managementEmail,
    required this.personName,
    required this.onPrimary,
    required this.onAssistant,
    required this.onAddAssigned,
    required this.onRemoveAssigned,
    required this.onAddCare,
    required this.onRemoveCare,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          title: 'Management',
          children: [
            if (loadingDirectory)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondaryTeal,
                  ),
                ),
              )
            else ...[
              _PersonDropdown(
                label: 'Primary Manager',
                valueId: primaryManagerId,
                people: directory,
                onChanged: onPrimary,
              ),
              _PersonDropdown(
                label: 'Assistant Manager',
                valueId: assistantManagerId,
                people: directory,
                onChanged: onAssistant,
              ),
            ],
          ],
        ),
        _Card(
          title: 'Assigned Staff & Care Team',
          children: [
            const Text(
              'Assigned Staff',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            _ChipGroup(
              people: assignedStaff,
              onRemove: onRemoveAssigned,
            ),
            _AddPersonButton(
              label: 'Add staff…',
              people: directory,
              excludeIds: assignedStaff.map((e) => e.id).toSet(),
              onAdd: onAddAssigned,
            ),
            const SizedBox(height: 14),
            const Text(
              'Care Team',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            _ChipGroup(
              people: careTeam,
              onRemove: onRemoveCare,
            ),
            _AddPersonButton(
              label: 'Add care team…',
              people: directory,
              excludeIds: careTeam.map((e) => e.id).toSet(),
              onAdd: onAddCare,
            ),
          ],
        ),
        _Card(
          title: 'Contact Information',
          children: [
            _Field(
              label: 'Management Phone',
              controller: managementPhone,
              keyboard: TextInputType.phone,
              onChanged: (_) => onChanged(),
            ),
            _Field(
              label: 'Management Email',
              controller: managementEmail,
              keyboard: TextInputType.emailAddress,
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonDropdown extends StatelessWidget {
  final String label;
  final String? valueId;
  final List<StaffResidencePerson> people;
  final ValueChanged<String?> onChanged;

  const _PersonDropdown({
    required this.label,
    required this.valueId,
    required this.people,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ids = people.map((e) => e.id).toSet();
    final value = valueId != null && ids.contains(valueId) ? valueId : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surfaceWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            isExpanded: true,
            value: value,
            hint: const Text(
              'Select…',
              style: TextStyle(fontFamily: 'Outfit'),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('—', style: TextStyle(fontFamily: 'Outfit')),
              ),
              ...people.map(
                (person) => DropdownMenuItem<String?>(
                  value: person.id,
                  child: Text(
                    person.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Outfit'),
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<StaffResidencePerson> people;
  final ValueChanged<String> onRemove;

  const _ChipGroup({required this.people, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'None selected',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.textMuted,
            fontSize: 12.5,
          ),
        ),
      );
    }
    final visible = people.take(3).toList();
    final more = people.length - visible.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final person in visible)
            InputChip(
              label: Text(
                person.name,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
              ),
              onDeleted: () => onRemove(person.id),
              deleteIconColor: AppColors.textMuted,
              backgroundColor: AppColors.filterButtonBackground,
              side: const BorderSide(color: AppColors.cardBorder),
            ),
          if (more > 0)
            Chip(
              label: Text(
                '+$more more',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
              ),
              backgroundColor: AppColors.infoBackground,
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }
}

class _AddPersonButton extends StatelessWidget {
  final String label;
  final List<StaffResidencePerson> people;
  final Set<String> excludeIds;
  final ValueChanged<StaffResidencePerson> onAdd;

  const _AddPersonButton({
    required this.label,
    required this.people,
    required this.excludeIds,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final options =
        people.where((p) => !excludeIds.contains(p.id)).toList(growable: false);
    return PopupMenuButton<StaffResidencePerson>(
      enabled: options.isNotEmpty,
      onSelected: onAdd,
      itemBuilder: (context) => [
        for (final person in options.take(30))
          PopupMenuItem(
            value: person,
            child: Text(
              person.name,
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
          ),
      ],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: options.isEmpty
                      ? AppColors.textMuted
                      : AppColors.textHeading,
                ),
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final String name;
  final String type;
  final String status;
  final String emergency;
  final String address;
  final String cityRegion;
  final String country;
  final String coordinates;
  final String geofence;
  final String capacity;
  final String operatingHours;
  final String serviceType;
  final String notes;
  final String primaryManager;
  final String assistantManager;
  final ValueChanged<int> onEditStep;

  const _ReviewStep({
    required this.name,
    required this.type,
    required this.status,
    required this.emergency,
    required this.address,
    required this.cityRegion,
    required this.country,
    required this.coordinates,
    required this.geofence,
    required this.capacity,
    required this.operatingHours,
    required this.serviceType,
    required this.notes,
    required this.primaryManager,
    required this.assistantManager,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Review before creating — Confirm the details below. You can edit any section before the residence is registered.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              color: AppColors.secondaryTealDeep,
              height: 1.35,
            ),
          ),
        ),
        _Card(
          title: 'Residence Information',
          trailing: TextButton.icon(
            onPressed: () => onEditStep(0),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
          children: [
            _kv('Residence Name', name.isEmpty ? '—' : name),
            _kv('Type', type),
            _kv(
              'Status',
              status.isEmpty
                  ? '—'
                  : status[0].toUpperCase() + status.substring(1),
            ),
            _kv('Emergency Contact', emergency.isEmpty ? '—' : emergency),
          ],
        ),
        _Card(
          title: 'Address',
          trailing: TextButton.icon(
            onPressed: () => onEditStep(1),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
          children: [
            _kv('Street Address', address.isEmpty ? '—' : address),
            _kv('City / Region', cityRegion.isEmpty ? '—' : cityRegion),
            _kv('Country', country.isEmpty ? '—' : country),
            _kv('Coordinates', coordinates.isEmpty ? '—' : coordinates),
            _kv('Geofence', geofence),
          ],
        ),
        _Card(
          title: 'Capacity & Operations',
          trailing: TextButton.icon(
            onPressed: () => onEditStep(2),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
          children: [
            _kv('Licensed beds', capacity.isEmpty ? '—' : capacity),
            _kv(
              'Operating hours',
              operatingHours.isEmpty ? '—' : operatingHours,
            ),
            _kv('Service type', serviceType.isEmpty ? '—' : serviceType),
            _kv('Notes', notes.isEmpty ? '—' : notes),
          ],
        ),
        _Card(
          title: 'Management & Staff',
          trailing: TextButton.icon(
            onPressed: () => onEditStep(3),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
          children: [
            _kv('Primary manager', primaryManager),
            _kv('Assistant manager', assistantManager),
          ],
        ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
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
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
