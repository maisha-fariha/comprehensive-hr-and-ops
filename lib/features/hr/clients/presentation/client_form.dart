import 'package:flutter/widgets.dart';

import '../domain/entities/client_extras.dart';
import '../domain/entities/client_summary.dart';
import 'clients_labels.dart';

/// One switch on the web's "Family Portal Visibility" card.
class PortalVisibilityItem {
  final String key;
  final String title;
  final String description;
  final String? note;

  const PortalVisibilityItem(this.key, this.title, this.description, [this.note]);
}

class PortalVisibilityGroup {
  final String label;
  final List<PortalVisibilityItem> items;

  const PortalVisibilityGroup(this.label, this.items);
}

const portalVisibilityGroups = [
  PortalVisibilityGroup('Daily Care & Activity', [
    PortalVisibilityItem(
      'dailyLogs',
      'Daily Logs',
      'Allow family members to view daily care notes, observations, and routine updates.',
    ),
    PortalVisibilityItem(
      'activities',
      'Activities & Progress',
      'Share completed activities, engagement updates, and progress tracking.',
    ),
    PortalVisibilityItem(
      'shiftUpdates',
      'Shift Updates',
      'Show which shifts are covering the home, and when cover changes.',
      'Shift cover only. Which individual staff are assigned is the separate switch below.',
    ),
  ]),
  PortalVisibilityGroup('Health Information', [
    PortalVisibilityItem(
      'medications',
      'Medication Information',
      'Share current medication information and medication updates.',
      'Medication administration details are only visible based on organization policy.',
    ),
    PortalVisibilityItem(
      'medicalConditions',
      'Medical Conditions',
      'Share diagnoses and standing medical conditions.',
    ),
    PortalVisibilityItem(
      'carePlan',
      'Care Plan',
      'Share the care plan itself, as opposed to the notes written against it.',
    ),
  ]),
  PortalVisibilityGroup('Care Team Information', [
    PortalVisibilityItem(
      'messages',
      'Staff Messages',
      'Allow communication between family members and authorized staff.',
    ),
    PortalVisibilityItem(
      'assignedStaff',
      'Assigned Staff',
      'Show which staff are assigned to this resident.',
    ),
  ]),
  PortalVisibilityGroup('Appointments & Documents', [
    PortalVisibilityItem(
      'appointments',
      'Appointments',
      'Show upcoming and completed appointments.',
    ),
    PortalVisibilityItem(
      'documents',
      'Documents',
      'Allow access to approved client documents and files.',
    ),
    PortalVisibilityItem(
      'incidents',
      'Incident Updates',
      'Share approved incident summaries and important notifications.',
    ),
  ]),
];

const _defaultPortalVisibility = {
  'dailyLogs': true,
  'activities': true,
  'incidents': false,
  'medications': false,
  'documents': true,
  'appointments': true,
  'messages': false,
  'shiftUpdates': false,
  'medicalConditions': false,
  'carePlan': false,
  'assignedStaff': false,
};

/// The web client form steps, in order.
enum ClientStep { basic, residence, family, medical, care }

extension ClientStepLabels on ClientStep {
  String get label => switch (this) {
        ClientStep.basic => 'Basic Information',
        ClientStep.residence => 'Residence Assignment',
        ClientStep.family => 'Family / Guardian',
        ClientStep.medical => 'Medical Information',
        ClientStep.care => 'Care Planning',
      };

  String get description => switch (this) {
        ClientStep.basic => 'Personal details',
        ClientStep.residence => 'Assignment details',
        ClientStep.family => 'Family / contact',
        ClientStep.medical => 'Health information',
        ClientStep.care => 'Goals & progress',
      };
}

final _nameRule = RegExp(r"^[A-Za-z][A-Za-z\s'.-]*$");
final _phoneRule = RegExp(r'^\+?[\d\s().-]{7,20}$');
final _emailRule = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// The web `requiredNameSchema(label)`.
String? requiredNameError(String value, String label) {
  final v = value.trim();
  if (v.isEmpty) return '$label is required';
  if (v.length > 80) return '$label must be 80 characters or fewer';
  if (!_nameRule.hasMatch(v)) return '$label can only contain letters';
  return null;
}

/// The web `optionalNameSchema(label)`.
String? optionalNameError(String value, String label) {
  if (value.isEmpty) return null;
  if (value.length > 80) return '$label must be 80 characters or fewer';
  if (!_nameRule.hasMatch(value)) return '$label can only contain letters';
  return null;
}

/// The web `optionalPhoneSchema()`.
String? optionalPhoneError(String value) =>
    value.isEmpty || _phoneRule.hasMatch(value) ? null : 'Enter a valid phone number';

/// The web `optionalEmailSchema()`.
String? optionalEmailError(String value) =>
    value.isEmpty || _emailRule.hasMatch(value) ? null : 'Enter a valid email';

/// State of the "Add New Client" wizard and the client record editor
/// (the web zod schema `Z`, defaults `J()` and payload builder `_()`).
class ClientForm {
  final firstName = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  final roomNumber = TextEditingController();
  final assignmentNotes = TextEditingController();
  final guardianName = TextEditingController();
  final guardianMiddleName = TextEditingController();
  final guardianPhone = TextEditingController();
  final guardianEmail = TextEditingController();
  final secondaryName = TextEditingController();
  final secondaryPhone = TextEditingController();
  final secondaryEmail = TextEditingController();
  final contactNotes = TextEditingController();
  final doctorName = TextEditingController();
  final pharmacyName = TextEditingController();
  final behavioralTriggers = TextEditingController();
  final safetyPlanNotes = TextEditingController();
  final servicePlan = TextEditingController();
  final progressNotes = TextEditingController();

  String dob = '';
  String gender = '';
  String careLevel = 'Low';
  String status = 'Active';
  String currentResidence = '';
  String admissionDate = '';
  String roomId = '';
  String fundingSource = '';
  String relationship = '';
  String secondaryRelationship = '';
  bool emergencyContact = true;
  bool familyPortalAccess = true;
  bool receiveNotifications = true;
  bool emergencyAlerts = true;
  Map<String, bool> portalVisibility = Map.of(_defaultPortalVisibility);
  List<String> allergies = [];
  List<String> diagnoses = [];
  List<String> currentMedications = [];
  final List<TextEditingController> goals = [];
  final List<TextEditingController> outcomes = [];

  /// New-client goals: standard category keys and custom goal titles, each
  /// created with `POST /clients/{id}/goals` once the client exists.
  List<String> goalCategories = [];
  final List<TextEditingController> customGoals = [];
  String photoUrl = '';
  ClientPickedFile? photo;
  ClientPickedFile? carePlanDocument;

  /// Web `visibleUpdates` default — always non-empty, so the wizard's
  /// Family step counts as complete.
  final List<String> visibleUpdates = const [
    'Daily Logs & Activities',
    'Medications & Health Updates',
    'Incident Reports',
    'Appointments',
    'Messages',
  ];

  ClientForm();

  /// The web `X(client)`: the editor prefilled from a record.
  factory ClientForm.fromClient(ClientSummary c) {
    final form = ClientForm()
      ..photoUrl = c.photoUrl ?? ''
      ..dob = ClientsLabels.dateInput(c.dateOfBirth)
      ..gender = c.gender ?? ''
      ..careLevel = ClientsLabels.matchOption(c.careLevel, ClientsLabels.careLevels)
      ..status = ClientsLabels.matchOption(c.status, ClientsLabels.statuses)
      ..currentResidence = c.residenceId ?? ''
      ..admissionDate = ClientsLabels.dateInput(c.admissionDate)
      ..roomId = c.roomId ?? ''
      ..fundingSource = c.fundingSource ?? ''
      ..portalVisibility = {..._defaultPortalVisibility, ...c.portalVisibility}
      ..allergies = List.of(c.allergies)
      ..diagnoses = List.of(c.diagnoses)
      ..currentMedications = List.of(c.currentMedications);
    form.firstName.text = c.firstName;
    form.middleName.text = c.middleName ?? '';
    form.lastName.text = c.lastName;
    form.roomNumber.text = c.roomNumber ?? '';
    form.assignmentNotes.text = c.assignmentNotes;
    form.contactNotes.text = c.contactNotes;
    form.doctorName.text = c.doctorName;
    form.pharmacyName.text = c.pharmacyName;
    form.behavioralTriggers.text = c.behavioralTriggers;
    form.safetyPlanNotes.text = c.safetyPlanNotes;
    form.servicePlan.text = c.servicePlan;
    form.progressNotes.text = c.progressNotes;
    for (final g in c.carePlanGoals) {
      form.goals.add(TextEditingController(text: g));
    }
    for (final o in c.outcomes) {
      form.outcomes.add(TextEditingController(text: o));
    }
    return form;
  }

  static bool _filled(String v) => v.trim().isNotEmpty;

  bool get basicComplete => [
        firstName.text,
        lastName.text,
        dob,
        careLevel,
        status,
      ].every(_filled);

  bool get residenceComplete =>
      _filled(currentResidence) && _filled(admissionDate);

  bool get medicalFilled =>
      allergies.isNotEmpty ||
      diagnoses.isNotEmpty ||
      currentMedications.isNotEmpty ||
      _filled(doctorName.text) ||
      _filled(pharmacyName.text) ||
      _filled(behavioralTriggers.text) ||
      _filled(safetyPlanNotes.text);

  bool get careFilled =>
      _filled(servicePlan.text) ||
      carePlanDocument != null ||
      goals.isNotEmpty ||
      goalCategories.isNotEmpty ||
      customGoals.isNotEmpty ||
      outcomes.isNotEmpty ||
      _filled(progressNotes.text);

  bool get familyFilled =>
      _filled(guardianName.text) ||
      _filled(relationship) ||
      _filled(guardianPhone.text) ||
      _filled(guardianEmail.text) ||
      _filled(secondaryName.text) ||
      visibleUpdates.isNotEmpty ||
      _filled(contactNotes.text);

  /// The web's required-field rules are skipped while the status is Draft.
  bool get isDraft => status.trim().toLowerCase() == 'draft';

  /// Wizard step tick: every required field, or any field on optional steps.
  bool stepComplete(ClientStep step) => switch (step) {
        ClientStep.basic => basicComplete,
        ClientStep.residence => residenceComplete,
        ClientStep.family => familyFilled,
        ClientStep.medical => medicalFilled,
        ClientStep.care => careFilled,
      };

  /// Required-field errors for one step (the web "Next" trigger).
  Map<String, String> validateStep(ClientStep step) {
    final errors = <String, String>{};
    void put(String key, String? message) {
      if (message != null) errors[key] = message;
    }

    final draft = isDraft;
    switch (step) {
      case ClientStep.basic:
        put('firstName', requiredNameError(firstName.text, 'First name'));
        put('middleName', optionalNameError(middleName.text.trim(), 'Middle name'));
        put('lastName', requiredNameError(lastName.text, 'Last name'));
        if (dob.isEmpty && !draft) put('dob', 'Date of birth is required');
        if (careLevel.isEmpty) put('careLevel', 'Select a care level');
        if (status.isEmpty) put('status', 'Select a status');
      case ClientStep.residence:
        if (currentResidence.isEmpty && !draft) {
          put('currentResidence', 'Select a residence');
        }
        if (admissionDate.isEmpty && !draft) {
          put('admissionDate', 'Admission date is required');
        }
      case ClientStep.family:
        const primary = 'Primary emergency contact name';
        put(
          'guardianName',
          draft
              ? optionalNameError(guardianName.text.trim(), primary)
              : requiredNameError(guardianName.text, primary),
        );
        put(
          'guardianMiddleName',
          optionalNameError(guardianMiddleName.text.trim(), 'Middle name'),
        );
        if (relationship.trim().isEmpty && !draft) {
          put('relationship', 'Relationship is required');
        }
        final phone = guardianPhone.text.trim();
        put(
          'guardianPhone',
          phone.isEmpty && !draft ? 'Phone number is required' : optionalPhoneError(phone),
        );
        put('guardianEmail', guardianEmailError());
        put(
          'secondaryName',
          optionalNameError(secondaryName.text.trim(), 'Secondary contact name'),
        );
        put('secondaryPhone', optionalPhoneError(secondaryPhone.text.trim()));
        put('secondaryEmail', optionalEmailError(secondaryEmail.text.trim()));
      case ClientStep.medical:
      case ClientStep.care:
        break;
    }
    return errors;
  }

  /// Email format, plus the web rule that a family portal login needs one.
  String? guardianEmailError() {
    final email = guardianEmail.text.trim();
    if (email.isEmpty && familyPortalAccess && _filled(guardianName.text)) {
      return 'Add an email for the family portal login, or turn portal access off';
    }
    return optionalEmailError(email);
  }

  /// Whole-schema errors (the web submit).
  Map<String, String> validateAll() => {
        for (final step in ClientStep.values) ...validateStep(step),
      };

  /// The web "Save Draft" check: a name, and a usable family email.
  Map<String, String> validateDraft() {
    final errors = <String, String>{};
    final first = requiredNameError(firstName.text, 'First name');
    final last = requiredNameError(lastName.text, 'Last name');
    final email = guardianEmailError();
    if (first != null) errors['firstName'] = first;
    if (last != null) errors['lastName'] = last;
    if (email != null) errors['guardianEmail'] = email;
    return errors;
  }

  /// Widget key of the input for [field] (`guardianPhone` ->
  /// `client-guardian-phone`).
  static Key fieldKey(String field) => ValueKey(
        field == 'currentResidence'
            ? 'client-residence'
            : 'client-${field.replaceAllMapped(RegExp('[A-Z]'), (m) => '-${m[0]!.toLowerCase()}')}',
      );

  static ClientStep stepOf(String field) => switch (field) {
        'firstName' ||
        'middleName' ||
        'lastName' ||
        'dob' ||
        'careLevel' ||
        'status' =>
          ClientStep.basic,
        'currentResidence' || 'admissionDate' => ClientStep.residence,
        _ => ClientStep.family,
      };

  static String? _opt(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _lines(List<TextEditingController> list) => list
      .map((c) => c.text.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  /// The web `eN(form, photoUrl)` — `POST /clients` body. [draft] is the
  /// web "Save Draft", which saves with status `draft`.
  Map<String, dynamic> toCreateBody({String? uploadedPhotoUrl, bool draft = false}) {
    final photo = uploadedPhotoUrl ?? _opt(photoUrl);
    return {
      'firstName': firstName.text,
      'middleName': _opt(middleName.text),
      'lastName': lastName.text,
      'photoUrl': ?photo,
      'residenceId': currentResidence,
      'level': ?_opt(careLevel),
      'status': ?(draft ? 'draft' : _opt(status)?.toLowerCase()),
      'dateOfBirth': ?_opt(dob),
      'gender': ?_opt(gender),
      'admissionDate': ?_opt(admissionDate),
      'roomId': ?_opt(roomId),
      'roomNumber': ?_opt(roomNumber.text),
      'fundingSource': ?_opt(fundingSource),
      'portalVisibility': Map.of(portalVisibility),
      'carePlan': {
        'servicePlan': servicePlan.text,
        'goals': _lines(goals),
        'outcomes': _lines(outcomes),
        'progressNotes': progressNotes.text,
        'assignmentNotes': assignmentNotes.text,
        'contactNotes': contactNotes.text,
      },
      'medicalInfo': {
        'allergies': List.of(allergies),
        'diagnoses': List.of(diagnoses),
        'currentMedications': List.of(currentMedications),
        'doctorName': doctorName.text,
        'pharmacyName': pharmacyName.text,
        'behavioralTriggers': behavioralTriggers.text,
        'safetyPlanNotes': safetyPlanNotes.text,
      },
    };
  }

  /// `PATCH /clients/{id}` body: the create body without `residenceId`
  /// (moves go through the transfer dialog) and `roomId` cleared explicitly.
  Map<String, dynamic> toUpdateBody({String? uploadedPhotoUrl}) {
    final body = toCreateBody(uploadedPhotoUrl: uploadedPhotoUrl)
      ..remove('residenceId');
    body['roomId'] = roomId.isEmpty ? null : roomId;
    return body;
  }

  /// `POST /clients/{id}/family` body for the wizard's guardian, or `null`
  /// when no guardian name was entered.
  Map<String, dynamic>? guardianBody() {
    final name = guardianName.text.trim();
    if (name.isEmpty) return null;
    return {
      'name': name,
      'middleName': _opt(guardianMiddleName.text),
      'relationship': ?_opt(relationship),
      'email': ?_opt(guardianEmail.text),
      'phone': ?_opt(guardianPhone.text),
      'isPrimaryGuardian': true,
      'createPortalUser': familyPortalAccess,
      'isEmergencyContact': emergencyContact,
      'receiveNotifications': receiveNotifications,
      'emergencyAlerts': emergencyAlerts,
    };
  }

  /// `POST /clients/{id}/family` body for the optional secondary emergency
  /// contact, or `null` when no name was entered.
  Map<String, dynamic>? secondaryContactBody() {
    final name = secondaryName.text.trim();
    if (name.isEmpty) return null;
    return {
      'name': name,
      'relationship': ?_opt(secondaryRelationship),
      'email': ?_opt(secondaryEmail.text),
      'phone': ?_opt(secondaryPhone.text),
      'isPrimaryGuardian': false,
      'createPortalUser': false,
      'isEmergencyContact': true,
      'receiveNotifications': false,
      'emergencyAlerts': true,
    };
  }

  /// `POST /clients/{id}/goals` bodies: one per ticked category, then one
  /// per custom goal title.
  List<Map<String, dynamic>> goalBodies() => [
        for (final key in goalCategories) {'category': key},
        for (final title in _lines(customGoals)) {'category': 'custom', 'title': title},
      ];

  void dispose() {
    for (final c in [
      firstName,
      middleName,
      lastName,
      roomNumber,
      assignmentNotes,
      guardianName,
      guardianMiddleName,
      guardianPhone,
      guardianEmail,
      secondaryName,
      secondaryPhone,
      secondaryEmail,
      contactNotes,
      doctorName,
      pharmacyName,
      behavioralTriggers,
      safetyPlanNotes,
      servicePlan,
      progressNotes,
      ...goals,
      ...outcomes,
      ...customGoals,
    ]) {
      c.dispose();
    }
  }
}
