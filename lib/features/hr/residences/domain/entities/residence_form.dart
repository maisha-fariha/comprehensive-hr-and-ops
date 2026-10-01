import 'residence_summary.dart';

/// Wizard steps of the web "Add New Residence" / "Edit Residence" modal.
enum ResidenceFormStep { basic, address, capacity, management, review }

/// `{ staffId, role }` row of `PUT /residences/{id}/assignments`.
typedef ResidenceAssignment = ({String staffId, String role});

/// Web `residenceFormSchema` values. Text fields stay strings until
/// [toBody] converts them, exactly like the web form.
class ResidenceFormValues {
  String name;
  String phone;
  String emergencyContact;
  String email;
  String type;
  String lifecycleStatus;
  String streetAddress;
  String city;
  String state;
  String postalCode;
  String country;
  String latitude;
  String longitude;
  String timeZone;
  String geofenceRadius;
  bool enableGpsTracking;
  String totalBeds;
  String availableBeds;
  String initialOccupiedBeds;
  String occupancySource;
  String operatingHours;
  String serviceType;
  String operationsNotes;
  String primaryManager;
  String assistantManager;
  List<String> assignedStaff;
  List<String> careTeam;
  String managementPhone;
  String managementEmail;

  ResidenceFormValues({
    this.name = '',
    this.phone = '',
    this.emergencyContact = '',
    this.email = '',
    this.type = '',
    this.lifecycleStatus = 'Pending',
    this.streetAddress = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'United States',
    this.latitude = '',
    this.longitude = '',
    this.timeZone = 'America/Los_Angeles',
    this.geofenceRadius = '150',
    this.enableGpsTracking = true,
    this.totalBeds = '',
    this.availableBeds = '',
    this.initialOccupiedBeds = '',
    this.occupancySource = 'declared',
    this.operatingHours = '',
    this.serviceType = 'Residential Care',
    this.operationsNotes = '',
    this.primaryManager = '',
    this.assistantManager = '',
    List<String>? assignedStaff,
    List<String>? careTeam,
    this.managementPhone = '',
    this.managementEmail = '',
  })  : assignedStaff = assignedStaff ?? [],
        careTeam = careTeam ?? [];

  /// Web `residenceToFormValues`.
  factory ResidenceFormValues.fromResidence(ResidenceSummary r) {
    final empty = ResidenceFormValues();
    String text(Object? v) => v == null ? '' : '$v';
    return ResidenceFormValues(
      name: r.name,
      phone: r.phone ?? '',
      emergencyContact: r.emergencyPhone ?? '',
      email: r.email ?? '',
      type: r.residenceType ?? empty.type,
      lifecycleStatus:
          r.status.isEmpty ? empty.lifecycleStatus : _humanise(r.status),
      streetAddress: r.addressLine1 ?? '',
      city: r.city ?? '',
      state: r.stateProvince ?? '',
      postalCode: r.postalCode ?? '',
      country: r.country ?? empty.country,
      latitude: text(_plain(r.latitude)),
      longitude: text(_plain(r.longitude)),
      timeZone: r.timezone ?? empty.timeZone,
      geofenceRadius: text(r.gpsRadiusMeters),
      totalBeds: text(r.bedCapacity),
      availableBeds: text(r.availableBeds),
      initialOccupiedBeds: text(r.initialOccupiedBeds),
      occupancySource: r.occupancySource ?? 'declared',
      operatingHours: r.operatingHours ?? '',
      serviceType: r.serviceType ?? empty.serviceType,
      operationsNotes: r.notes ?? '',
      primaryManager: r.primaryManager?.id ?? '',
      assistantManager: r.assistantManager?.id ?? '',
      careTeam: [for (final p in r.careTeam) p.id],
      assignedStaff: [
        for (final p in r.assignedStaff)
          if (p.role == 'staff') p.id,
      ],
      managementPhone: r.managementPhone ?? '',
      managementEmail: r.managementEmail ?? '',
    );
  }

  ResidenceFormValues copy() => ResidenceFormValues(
        name: name,
        phone: phone,
        emergencyContact: emergencyContact,
        email: email,
        type: type,
        lifecycleStatus: lifecycleStatus,
        streetAddress: streetAddress,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        latitude: latitude,
        longitude: longitude,
        timeZone: timeZone,
        geofenceRadius: geofenceRadius,
        enableGpsTracking: enableGpsTracking,
        totalBeds: totalBeds,
        availableBeds: availableBeds,
        initialOccupiedBeds: initialOccupiedBeds,
        occupancySource: occupancySource,
        operatingHours: operatingHours,
        serviceType: serviceType,
        operationsNotes: operationsNotes,
        primaryManager: primaryManager,
        assistantManager: assistantManager,
        assignedStaff: [...assignedStaff],
        careTeam: [...careTeam],
        managementPhone: managementPhone,
        managementEmail: managementEmail,
      );

  bool get isDeclaredOccupancy => occupancySource == 'declared';

  /// "Available Beds" read-only tile of the Capacity step.
  int get calculatedAvailableBeds {
    final total = int.tryParse(totalBeds.trim()) ?? 0;
    return (total - calculatedOccupiedBeds).clamp(0, 1 << 31);
  }

  /// "Occupied Beds" tile of the Capacity step.
  int get calculatedOccupiedBeds {
    final total = int.tryParse(totalBeds.trim()) ?? 0;
    if (isDeclaredOccupancy) {
      final declared =
          (int.tryParse(initialOccupiedBeds.trim()) ?? 0).clamp(0, 1 << 31);
      final cap = total == 0 ? declared : total;
      return declared < cap ? declared : cap;
    }
    final available = availableBeds.trim();
    if (available.isEmpty) return 0;
    final free = (int.tryParse(available) ?? 0).clamp(0, 1 << 31);
    return (total - free).clamp(0, 1 << 31);
  }

  /// Web `toResidenceBody`.
  Map<String, dynamic> toBody() {
    final radius = _number(geofenceRadius);
    return {
      'name': name,
      'phone': ?_trim(phone),
      'emergencyPhone': ?_trim(emergencyContact),
      'email': ?_trim(email),
      'residenceType': type,
      'status': lifecycleStatus.toLowerCase(),
      'addressLine1': ?_trim(streetAddress),
      'city': ?_trim(city),
      'stateProvince': ?_trim(state),
      'postalCode': ?_trim(postalCode),
      'country': ?_trim(country),
      'latitude': ?_number(latitude),
      'longitude': ?_number(longitude),
      'timezone': _trim(timeZone) ?? 'UTC',
      if (radius != null) 'geofence': {'radiusMeters': radius},
      'bedCapacity': ?_number(totalBeds),
      'initialOccupiedBeds': ?_number(initialOccupiedBeds),
      'operatingHours': ?_trim(operatingHours),
      'serviceType': ?_trim(serviceType),
      'notes': ?_trim(operationsNotes),
      'managementPhone': ?_trim(managementPhone),
      'managementEmail': ?_trim(managementEmail),
    };
  }

  /// Web `toResidenceAssignments`: the first role a staff member gets wins.
  List<ResidenceAssignment> toAssignments() {
    final roles = <String, String>{};
    void add(String id, String role) {
      if (id.isEmpty || roles.containsKey(id)) return;
      roles[id] = role;
    }

    add(primaryManager, 'primary_manager');
    add(assistantManager, 'assistant_manager');
    for (final id in careTeam) {
      add(id, 'care_team');
    }
    for (final id in assignedStaff) {
      add(id, 'staff');
    }
    return [for (final e in roles.entries) (staffId: e.key, role: e.value)];
  }

  /// Web `sameAssignments`.
  static bool sameAssignments(
    List<ResidenceAssignment> a,
    List<ResidenceAssignment> b,
  ) {
    if (a.length != b.length) return false;
    String key(List<ResidenceAssignment> list) =>
        (list.map((e) => '${e.staffId}:${e.role}').toList()..sort()).join('|');
    return key(a) == key(b);
  }

  /// Fields each step checks before "Next" (web `eB`).
  static const Map<ResidenceFormStep, List<String>> stepFields = {
    ResidenceFormStep.basic: ['name', 'type', 'lifecycleStatus'],
    ResidenceFormStep.address: [
      'streetAddress',
      'city',
      'state',
      'postalCode',
      'country',
    ],
    ResidenceFormStep.capacity: ['totalBeds'],
    ResidenceFormStep.management: [],
    ResidenceFormStep.review: [],
  };

  static final RegExp _phone = RegExp(r'^\+?[\d\s().-]{7,20}$');
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Web `residenceFormSchema` messages, keyed by field.
  Map<String, String> validate() {
    final errors = <String, String>{};
    void required(String field, String value, String message) {
      if (value.isEmpty) errors[field] = message;
    }

    void phoneField(String field, String value) {
      if (value.isNotEmpty && !_phone.hasMatch(value)) {
        errors[field] = 'Enter a valid phone number';
      }
    }

    void emailField(String field, String value) {
      if (value.isNotEmpty && !_email.hasMatch(value)) {
        errors[field] = 'Enter a valid email';
      }
    }

    required('name', name, 'Residence name is required');
    phoneField('phone', phone);
    phoneField('emergencyContact', emergencyContact);
    emailField('email', email);
    required('type', type, 'Select a residence type');
    required('lifecycleStatus', lifecycleStatus, 'Select a status');
    required('streetAddress', streetAddress, 'Street address is required');
    required('city', city, 'City is required');
    required('state', state, 'State / region is required');
    required('postalCode', postalCode, 'Postal code is required');
    required('country', country, 'Country is required');
    required('totalBeds', totalBeds, 'Total capacity is required');
    phoneField('managementPhone', managementPhone);
    emailField('managementEmail', managementEmail);
    return errors;
  }

  /// Errors limited to the fields of [step].
  Map<String, String> validateStep(ResidenceFormStep step) {
    final all = validate();
    final fields = stepFields[step] ?? const [];
    return {
      for (final f in fields)
        if (all.containsKey(f)) f: all[f]!,
    };
  }

  static String? _trim(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  static num? _number(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    final n = num.tryParse(t);
    return n == null || !n.isFinite ? null : n;
  }

  static num? _plain(double? v) {
    if (v == null) return null;
    return v == v.roundToDouble() ? v.toInt() : v;
  }

  static String _humanise(String value) {
    final spaced = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return value;
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
