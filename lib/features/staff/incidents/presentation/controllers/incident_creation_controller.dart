import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_error_mapper.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/incident_detail.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_incident_options.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../domain/repositories/staff_incidents_repository.dart';
import 'staff_incidents_controller.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/media/app_file_picker.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/searchable_option_list.dart';

/// GetX controller for the Staff "Create Incident" form.
class IncidentCreationController extends GetxController {
  final StaffIncidentsRepository repository;
  final String? editIncidentId;

  IncidentCreationController({
    StaffIncidentsRepository? repository,
    this.editIncidentId,
  }) : repository = repository ?? GetIt.instance<StaffIncidentsRepository>();

  bool get isEditMode =>
      editIncidentId != null && editIncidentId!.trim().isNotEmpty;

  final RxBool isLoadingEdit = false.obs;
  bool _editApplied = false;
  final Set<String> _existingEvidenceUrls = {};

  /// 0-based wizard index matching web's 5-step create flow.
  final RxInt wizardStep = 0.obs;

  static const List<String> stepTitles = [
    'Incident Details',
    'Location & People',
    'Investigation',
    'Evidence & Submission',
    'Report Form',
  ];

  static const List<String> detectedDuringOptions = [
    'Medication Round',
    'Routine Check',
    'Family Visit',
    'Shift Handover',
    'Meal Time',
    'Community Outing',
    'Other',
  ];

  // Section 1
  final RxList<StaffIncidentCategoryOption> categories =
      <StaffIncidentCategoryOption>[].obs;
  final Rxn<StaffIncidentCategoryOption> selectedCategory =
      Rxn<StaffIncidentCategoryOption>();
  final RxList<StaffCirTemplateOption> cirTemplates =
      <StaffCirTemplateOption>[].obs;
  final Rxn<StaffCirTemplateOption> selectedCirTemplate =
      Rxn<StaffCirTemplateOption>();
  final TextEditingController incidentTitleController = TextEditingController();
  final TextEditingController incidentDateController = TextEditingController();
  final TextEditingController incidentTimeController = TextEditingController();
  final TextEditingController categoryDetailsController =
      TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final RxnString detectedDuring = RxnString();
  final Map<String, TextEditingController> _reportFormAnswers = {};

  // Section 2
  final Rx<IncidentSeverity> severity = IncidentSeverity.medium.obs;

  // Section 3 — Location & People (BUG_Report011–014, web parity)
  final RxList<StaffIncidentResidenceOption> residences =
      <StaffIncidentResidenceOption>[].obs;
  final Rxn<StaffIncidentResidenceOption> selectedResidence =
      Rxn<StaffIncidentResidenceOption>();
  final RxList<StaffIncidentClientOption> clients =
      <StaffIncidentClientOption>[].obs;
  final Rxn<StaffIncidentClientOption> selectedClient =
      Rxn<StaffIncidentClientOption>();
  final TextEditingController clientSearchController = TextEditingController();
  final RxList<StaffIncidentClientOption> clientSuggestions =
      <StaffIncidentClientOption>[].obs;
  final RxBool showClientSuggestions = false.obs;
  final RxBool isSearchingClients = false.obs;
  final RxList<StaffIncidentStaffOption> staffOptions =
      <StaffIncidentStaffOption>[].obs;
  final Rxn<StaffIncidentStaffOption> reportedByStaff =
      Rxn<StaffIncidentStaffOption>();
  final Rxn<StaffIncidentStaffOption> supervisorStaff =
      Rxn<StaffIncidentStaffOption>();
  final RxList<String> witnesses = <String>[].obs;
  final RxString reporterName = ''.obs;
  final RxString reporterMeta = ''.obs;
  final RxString reporterInitials = ''.obs;

  // CFS Details (optional) — web Location & People
  static const List<(String, String)> cfsStatusOptions = [
    ('ICO', 'ICO'),
    ('SFP', 'SFP'),
    ('CAY', 'CAY'),
    ('PGO', 'PGO'),
    ('CAG', 'CAG'),
    ('TGO', 'TGO'),
  ];
  final RxList<String> cfsStatuses = <String>[].obs;
  final TextEditingController childIdController = TextEditingController();
  final TextEditingController cipController = TextEditingController();
  final TextEditingController cipOfficeController = TextEditingController();
  final TextEditingController immediateActionController = TextEditingController();

  // Emergency + family (web Location & People)
  final RxBool emergencyServicesContacted = false.obs;
  final RxnString externalAgencyType = RxnString();
  final TextEditingController agencyReferenceController =
      TextEditingController();
  final TextEditingController agencyResponderController =
      TextEditingController();
  final RxBool familyGuardianNotified = false.obs;

  // Section 4
  final TextEditingController descriptionController = TextEditingController();

  // Investigation (BUG_Report015) — web parity
  static const List<(String, String)> investigationStatusOptions = [
    ('open', 'Open (awaiting investigation)'),
    ('investigating', 'Under investigation'),
    ('closed', 'Closed / resolved'),
  ];
  final RxnString investigationStatus = RxnString();
  final Rxn<StaffIncidentStaffOption> investigator =
      Rxn<StaffIncidentStaffOption>();
  final TextEditingController investigationNotesController =
      TextEditingController();
  final TextEditingController rootCauseController = TextEditingController();
  final TextEditingController correctiveActionController =
      TextEditingController();
  final RxBool followUpRequired = false.obs;
  final TextEditingController followUpDateController = TextEditingController();
  final Rxn<StaffIncidentStaffOption> assignedTo =
      Rxn<StaffIncidentStaffOption>();
  final RxBool debriefCompleted = false.obs;
  final TextEditingController debriefDetailsController =
      TextEditingController();
  final RxBool childInformedOfRights = false.obs;

  // Evidence & Submission (BUG_Report016)
  final RxList<StaffIncidentEvidenceFile> evidenceFiles =
      <StaffIncidentEvidenceFile>[].obs;
  final TextEditingController transcriptionController =
      TextEditingController();
  final RxList<StaffIncidentPartyNotification> partyNotifications =
      <StaffIncidentPartyNotification>[
    const StaffIncidentPartyNotification(
      party: 'Child Intervention Practitioner',
    ),
    const StaffIncidentPartyNotification(
      party: 'Child Intervention Intake and Response Team',
    ),
    const StaffIncidentPartyNotification(party: "Child's Family"),
    const StaffIncidentPartyNotification(party: "Child's Legal Guardian"),
    const StaffIncidentPartyNotification(party: 'Agency Director/Manager'),
    const StaffIncidentPartyNotification(party: 'Agency On Call'),
    const StaffIncidentPartyNotification(party: 'Licensing Officer'),
    const StaffIncidentPartyNotification(party: 'Police/RCMP'),
    const StaffIncidentPartyNotification(party: 'Medical Services'),
    const StaffIncidentPartyNotification(party: 'Therapist/Clinician'),
    const StaffIncidentPartyNotification(party: 'Probation'),
    const StaffIncidentPartyNotification(party: 'Other'),
  ].obs;

  // Report Form (BUG_Report017) — answers keyed by CIR field key
  // Controllers created lazily via [reportFormAnswerController].

  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingOptions = false.obs;

  /// Top-of-form banner (validation / submit errors). Cleared on step change.
  final RxnString formBannerMessage = RxnString();
  final RxBool formBannerIsError = true.obs;

  void clearFormBanner() => formBannerMessage.value = null;

  void showFormBanner(String message, {bool isError = true}) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    formBannerIsError.value = isError;
    formBannerMessage.value = trimmed;
  }

  String? get incidentCategoryLabel => selectedCategory.value?.name;
  String? get cirTemplateLabel {
    final template = selectedCirTemplate.value;
    if (template == null) return null;
    final version = template.version?.trim();
    if (version == null || version.isEmpty) return template.name;
    return '${template.name} · v$version';
  }

  TextEditingController reportFormAnswerController(String key) {
    return _reportFormAnswers.putIfAbsent(key, TextEditingController.new);
  }
  String? get residentLabel => selectedClient.value?.name;
  String? get residenceLabel => selectedResidence.value?.name;
  String? get reportedByStaffLabel => reportedByStaff.value?.name;
  String? get supervisorStaffLabel => supervisorStaff.value?.name;
  String? get investigatorLabel => investigator.value?.name;
  String? get assignedToLabel => assignedTo.value?.name;

  String? get investigationStatusLabel {
    final value = investigationStatus.value;
    if (value == null) return null;
    for (final option in investigationStatusOptions) {
      if (option.$1 == value) return option.$2;
    }
    return value;
  }

  String? get externalAgencyTypeLabel {
    switch (externalAgencyType.value) {
      case 'police':
        return 'Police';
      case 'ambulance':
        return 'Ambulance';
      case 'fire':
        return 'Fire';
      case 'cfs':
        return 'Child and Family Services';
      case 'other':
        return 'Other';
      default:
        return null;
    }
  }

  String get cfsStatusLabel {
    if (cfsStatuses.isEmpty) return '';
    return cfsStatuses.join(', ');
  }

  Timer? _clientSearchDebounce;
  int _clientSearchRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    if (isEditMode) {
      isLoadingEdit.value = true;
      loadOptions();
      return;
    }
    final now = DateTime.now();
    incidentDateController.text = _formatDate(now);
    incidentTimeController.text = _formatTime(TimeOfDay.fromDateTime(now));
    _hydrateReporterFromSession();
    loadOptions();
  }

  void _hydrateReporterFromSession() {
    try {
      final session = Get.find<UserSession>();
      final name = session.displayName.trim().isEmpty
          ? (session.email.trim().isEmpty ? 'You' : session.email.trim())
          : session.displayName.trim();
      reporterName.value = name;
      reporterInitials.value = IsoDateRange.initials(name);
      final role = session.roleRaw?.trim().isNotEmpty == true
          ? session.roleRaw!.replaceAll('_', ' ')
          : (session.staffKind?.name ?? 'Care Staff');
      final residence = session.residenceName?.trim();
      reporterMeta.value = [
        role,
        if (residence != null && residence.isNotEmpty) residence,
      ].join(' · ');
      if (session.avatarInitials.trim().isNotEmpty) {
        reporterInitials.value = session.avatarInitials.trim();
      }
      if (session.residenceId != null &&
          session.residenceId!.isNotEmpty &&
          session.residenceName != null &&
          session.residenceName!.isNotEmpty) {
        selectedResidence.value = StaffIncidentResidenceOption(
          id: session.residenceId!,
          name: session.residenceName!,
        );
      }
    } catch (_) {
      reporterName.value = 'You';
      reporterInitials.value = 'YO';
      reporterMeta.value = 'Care Staff';
    }
  }

  Future<void> loadOptions() async {
    isLoadingOptions.value = true;
    final cats = await repository.getCategories();
    final templates = await repository.getCirTemplates();
    final residenceResult = await repository.getResidences();
    final assigned = await repository.getClients(assignedToMe: true);
    final staff = await repository.getStaffOptions();
    isLoadingOptions.value = false;

    cats.when(
      success: categories.assignAll,
      failure: (_) {},
    );
    templates.when(
      success: cirTemplates.assignAll,
      failure: (_) {},
    );
    residenceResult.when(
      success: (list) {
        residences.assignAll(list);
        if (selectedResidence.value == null && list.length == 1) {
          selectedResidence.value = list.first;
        } else if (selectedResidence.value != null) {
          final match = list.where(
            (r) => r.id == selectedResidence.value!.id,
          );
          if (match.isNotEmpty) {
            selectedResidence.value = match.first;
          }
        }
      },
      failure: (_) {},
    );
    assigned.when(
      success: clients.assignAll,
      failure: (_) {},
    );
    staff.when(
      success: (list) {
        staffOptions.assignAll(list);
        if (!isEditMode && reportedByStaff.value == null && list.isNotEmpty) {
          final match = list.where(
            (s) =>
                s.name.toLowerCase() == reporterName.value.toLowerCase(),
          );
          if (match.isNotEmpty) reportedByStaff.value = match.first;
        }
      },
      failure: (_) {},
    );
    if (isEditMode && !_editApplied) {
      _editApplied = true;
      await _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final result = await repository.getIncidentDetail(editIncidentId!.trim());
    result.when(
      success: _applyDetail,
      failure: (error) {
        showFormBanner(
          error.message.trim().isEmpty
              ? 'Could not open this incident for editing.'
              : error.message,
        );
      },
    );
    if (!isClosed) isLoadingEdit.value = false;
  }

  void _applyDetail(IncidentDetail detail) {
    final json = detail.source;
    final payload = Map<String, dynamic>.from(
      JsonCodec.mapAt(json, 'payload') ??
          JsonCodec.mapAt(json, 'payloadJson') ??
          const {},
    );

    incidentTitleController.text = detail.title;
    descriptionController.text = detail.description;
    severity.value = detail.severity;
    categoryDetailsController.text = JsonCodec.stringOr(
      payload['categoryDetail'],
      '',
    );
    final during = JsonCodec.string(
      payload['detectedDuring'] ?? json['detectedDuring'],
    );
    if (during != null && during.isNotEmpty) detectedDuring.value = during;

    final categoryMap = JsonCodec.mapAt(json, 'category') ?? const {};
    final categoryId = JsonCodec.string(json['categoryId'] ?? categoryMap['id']);
    StaffIncidentCategoryOption? category;
    for (final option in categories) {
      if (option.id == categoryId || option.name == detail.categoryLabel) {
        category = option;
        break;
      }
    }
    if (category == null && categoryId != null && categoryId.isNotEmpty) {
      category = StaffIncidentCategoryOption(
        id: categoryId,
        name: detail.categoryLabel.isEmpty ? 'Incident' : detail.categoryLabel,
      );
    }
    selectedCategory.value = category;

    final occurred = JsonCodec.dateTime(
      json['occurredAt'] ?? json['reportedAt'] ?? json['createdAt'],
    );
    if (occurred != null) {
      final local = occurred.toLocal();
      incidentDateController.text = _formatDate(local);
      incidentTimeController.text = _formatTime(TimeOfDay.fromDateTime(local));
    }
    final end = JsonCodec.string(payload['endTime']);
    if (end != null && end.isNotEmpty) {
      final parsed = _parseTime(end);
      endTimeController.text = parsed == null ? end : _formatTime(parsed);
    }

    final residenceMap = JsonCodec.mapAt(json, 'residence') ?? const {};
    final residenceId = JsonCodec.string(
      json['residenceId'] ?? residenceMap['id'],
    );
    if (residenceId != null && residenceId.isNotEmpty) {
      StaffIncidentResidenceOption? residence;
      for (final option in residences) {
        if (option.id == residenceId) {
          residence = option;
          break;
        }
      }
      selectedResidence.value = residence ??
          StaffIncidentResidenceOption(
            id: residenceId,
            name: detail.residenceName.isEmpty ? 'Residence' : detail.residenceName,
          );
    }

    final clientMap = JsonCodec.mapAt(json, 'client') ??
        JsonCodec.mapAt(json, 'resident') ??
        const {};
    final clientId = JsonCodec.string(json['clientId'] ?? clientMap['id']);
    if (clientId != null && clientId.isNotEmpty) {
      final client = StaffIncidentClientOption(
        id: clientId,
        name: detail.residentName.isEmpty ? 'Client' : detail.residentName,
        residenceId: residenceId,
        residenceName: detail.residenceName,
      );
      selectedClient.value = client;
      clientSearchController.text = client.name;
    }

    childIdController.text = JsonCodec.stringOr(payload['childIdNumber'], '');
    cipController.text = JsonCodec.stringOr(
      payload['cipName'] ??
          payload['cip'] ??
          payload['childInterventionPractitioner'],
      '',
    );
    cipOfficeController.text = JsonCodec.stringOr(payload['cipOffice'], '');
    final allowedCfs = {for (final option in cfsStatusOptions) option.$1};
    final cfsRaw = payload['cfsStatus'];
    cfsStatuses.assignAll(
      (cfsRaw is List ? cfsRaw : [?cfsRaw])
          .map((item) => item.toString().trim().toUpperCase())
          .where(allowedCfs.contains)
          .toSet(),
    );
    witnesses.assignAll(_witnessNames(payload['witnesses'] ?? json['witnesses']));

    immediateActionController.text = JsonCodec.stringOr(
      json['immediateAction'] ?? payload['immediateAction'],
      '',
    );
    emergencyServicesContacted.value =
        json['emergencyServicesContacted'] == true ||
            payload['emergencyServicesContacted'] == true;
    externalAgencyType.value = JsonCodec.string(
      json['externalAgencyType'] ?? payload['externalAgencyType'],
    );
    agencyReferenceController.text = JsonCodec.stringOr(
      json['externalAgencyReference'] ?? payload['externalAgencyReference'],
      '',
    );
    agencyResponderController.text = JsonCodec.stringOr(
      json['externalAgencyResponder'] ?? payload['externalAgencyResponder'],
      '',
    );
    familyGuardianNotified.value =
        json['familyNotified'] == true || payload['familyNotified'] == true;

    final reporterMap = JsonCodec.mapAt(json, 'reporter') ??
        JsonCodec.mapAt(json, 'reportedBy') ??
        const {};
    final reporterId = JsonCodec.string(
      json['reportedByStaffId'] ?? reporterMap['id'] ?? payload['reportedByStaffId'],
    );
    if (reporterId != null && reporterId.isNotEmpty) {
      reportedByStaff.value = _staffOption(
        reporterId,
        detail.reportedByName.isEmpty ? 'Staff' : detail.reportedByName,
      );
    }
    final supervisorId = JsonCodec.string(
      payload['supervisorId'] ?? json['supervisorId'],
    );
    if (supervisorId != null && supervisorId.isNotEmpty) {
      supervisorStaff.value = _staffOption(
        supervisorId,
        JsonCodec.stringOr(payload['supervisorName'], 'Supervisor'),
      );
    }

    final status = JsonCodec.string(
      payload['investigationStatus'] ??
          JsonCodec.mapAt(json, 'investigation')?['status'],
    );
    if (status != null && status.isNotEmpty) {
      investigationStatus.value = status.toLowerCase();
    }
    final investigatorId = JsonCodec.string(payload['investigatorId']);
    if (investigatorId != null && investigatorId.isNotEmpty) {
      investigator.value = _staffOption(
        investigatorId,
        JsonCodec.stringOr(payload['investigatorName'], 'Investigator'),
      );
    }
    investigationNotesController.text = JsonCodec.stringOr(
      payload['investigationNotes'] ?? detail.investigationFindings,
      '',
    );
    rootCauseController.text = JsonCodec.stringOr(
      payload['rootCause'] ?? detail.investigationRootCause,
      '',
    );
    correctiveActionController.text = JsonCodec.stringOr(
      payload['correctiveAction'] ?? detail.investigationCorrectiveAction,
      '',
    );
    followUpRequired.value = payload['followUpRequired'] == true;
    followUpDateController.text = JsonCodec.stringOr(payload['followUpDueDate'], '');
    final assignedId = JsonCodec.string(payload['assignedToId']);
    if (assignedId != null && assignedId.isNotEmpty) {
      assignedTo.value = _staffOption(
        assignedId,
        JsonCodec.stringOr(payload['assignedToName'], 'Staff'),
      );
    }
    debriefCompleted.value = payload['debriefCompleted'] == true;
    debriefDetailsController.text = JsonCodec.stringOr(payload['debriefDetails'], '');
    childInformedOfRights.value = payload['childInformedOfRights'] == true;
    transcriptionController.text = JsonCodec.stringOr(payload['transcription'], '');
    _applyParties(payload['notifications']);

    final templateId = JsonCodec.string(
      json['cirTemplateId'] ?? payload['cirTemplateId'],
    );
    if (templateId != null && templateId.isNotEmpty) {
      for (final template in cirTemplates) {
        if (template.id == templateId) {
          selectedCirTemplate.value = template;
          for (final section in template.sections) {
            for (final field in section.fields) {
              final value = payload[field.key];
              if (value == null) continue;
              reportFormAnswerController(field.key).text = value.toString();
            }
          }
          break;
        }
      }
    }

    final files = <StaffIncidentEvidenceFile>[];
    for (final item in detail.evidence) {
      if (item.fileUrl.trim().isEmpty) continue;
      files.add(
        StaffIncidentEvidenceFile(
          localPath: '',
          fileName: item.displayName,
          mimeType: item.fileType,
          fileUrl: item.fileUrl,
        ),
      );
      _existingEvidenceUrls.add(item.fileUrl);
    }
    if (files.isNotEmpty) evidenceFiles.assignAll(files);
  }

  StaffIncidentStaffOption _staffOption(String id, String name) {
    for (final option in staffOptions) {
      if (option.id == id) return option;
    }
    return StaffIncidentStaffOption(id: id, name: name);
  }

  List<String> _witnessNames(dynamic raw) {
    if (raw is! List) return const [];
    final names = <String>[];
    for (final item in raw) {
      if (item is String && item.trim().isNotEmpty) {
        names.add(item.trim());
      } else if (item is Map) {
        final name = JsonCodec.string(item['name'] ?? item['witnessName']);
        if (name != null && name.isNotEmpty) names.add(name);
      }
    }
    return names;
  }

  void _applyParties(dynamic raw) {
    if (raw is! List) return;
    for (var index = 0; index < partyNotifications.length; index++) {
      final party = partyNotifications[index].party;
      Map<String, dynamic>? match;
      for (final item in raw) {
        if (item is! Map) continue;
        final row = JsonCodec.asMap(item);
        if (JsonCodec.stringOr(row['party'], '') == party) {
          match = row;
          break;
        }
      }
      if (match == null) continue;
      partyNotifications[index] = partyNotifications[index].copyWith(
        notified: match['notified'] == true,
        contactName: JsonCodec.stringOr(match['contactName'], ''),
        dateNotified: JsonCodec.stringOr(match['dateNotified'], ''),
      );
    }
  }

  void selectSeverity(IncidentSeverity value) => severity.value = value;

  void goToStep(int step) {
    if (step < 0 || step >= stepTitles.length) return;
    clearFormBanner();
    wizardStep.value = step;
  }

  /// Advances to the next wizard step when not already on the last.
  /// Soft-validates step 0 fields with a top banner but does not block.
  bool nextStep() {
    if (wizardStep.value >= stepTitles.length - 1) return false;
    final softWarning =
        wizardStep.value == 0 ? _softValidateDetailsStep() : null;
    if (softWarning != null) {
      showFormBanner(softWarning);
    } else {
      clearFormBanner();
    }
    wizardStep.value++;
    return true;
  }

  void previousStep() {
    if (wizardStep.value <= 0) return;
    clearFormBanner();
    wizardStep.value--;
  }

  /// Draft status is not an API-supported value — keep form progress on-screen.
  void saveDraft() {
    showFormBanner(
      'Draft status is not supported by the API '
      '(open, investigating, or closed only). '
      'Your progress stays on screen until you Submit.',
      isError: false,
    );
  }

  /// Returns a soft warning for incomplete details, or null when OK.
  String? _softValidateDetailsStep() {
    final missing = <String>[];
    if (selectedCategory.value == null) missing.add('category');
    if (incidentTitleController.text.trim().isEmpty) missing.add('title');
    if (incidentDateController.text.trim().isEmpty) missing.add('date');
    if (incidentTimeController.text.trim().isEmpty) missing.add('time');
    if (descriptionController.text.trim().isEmpty) missing.add('description');
    if (missing.isEmpty) return null;
    return 'Consider filling: ${missing.join(', ')} before continuing.';
  }

  Future<void> pickCategory() async {
    if (categories.isEmpty) {
      await loadOptions();
    }
    final selected = await _pickOption<StaffIncidentCategoryOption>(
      title: 'Incident Category',
      options: categories.toList(),
      labelOf: (o) => o.name,
    );
    if (selected != null) selectedCategory.value = selected;
  }

  Future<void> pickCirTemplate() async {
    if (cirTemplates.isEmpty) return;
    final selected = await _pickOption<StaffCirTemplateOption>(
      title: 'CIR Template',
      options: cirTemplates.toList(),
      labelOf: (o) => o.name,
    );
    if (selected != null) selectedCirTemplate.value = selected;
  }

  Future<void> pickDetectedDuring() async {
    final selected = await _pickOption<String>(
      title: 'Detected During',
      options: detectedDuringOptions,
      labelOf: (o) => o,
    );
    if (selected != null) detectedDuring.value = selected;
  }

  Future<void> pickResidence() async {
    if (residences.isEmpty) {
      final result = await repository.getResidences();
      result.when(
        success: residences.assignAll,
        failure: (error) => AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not load residences',
        ),
      );
    }
    final selected = await _pickOption<StaffIncidentResidenceOption>(
      title: 'Residence',
      options: residences.toList(),
      labelOf: (o) => o.name,
    );
    if (selected == null) return;
    selectedResidence.value = selected;
    if (selectedClient.value != null &&
        selectedClient.value!.residenceId != null &&
        selectedClient.value!.residenceId != selected.id) {
      selectedClient.value = null;
      clientSearchController.clear();
    }
  }

  void onClientQueryChanged(String query) {
    final selected = selectedClient.value;
    if (selected != null && query.trim() != selected.name) {
      selectedClient.value = null;
    }
    _clientSearchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _clientSearchRequestId++;
      isSearchingClients.value = false;
      clientSuggestions.clear();
      showClientSuggestions.value = false;
      return;
    }
    showClientSuggestions.value = true;
    _clientSearchDebounce = Timer(
      const Duration(milliseconds: 320),
      () => _searchClients(trimmed),
    );
  }

  Future<void> _searchClients(String query) async {
    final requestId = ++_clientSearchRequestId;
    isSearchingClients.value = true;
    // Match web: search all tenants clients (optionally scoped by residence
    // via API), then show results — do not drop rows client-side when the
    // selected residence id differs (user can still pick; selecting a client
    // syncs residence).
    final result = await repository.getClients(
      search: query,
      residenceId: selectedResidence.value?.id,
      assignedToMe: false,
    );
    if (requestId != _clientSearchRequestId) return;
    isSearchingClients.value = false;
    result.when(
      success: (list) {
        // If residence-scoped search returned nothing, fall back to unscoped
        // search so options still appear (web lists Mala Box clients even
        // before residence is chosen).
        if (list.isEmpty && selectedResidence.value?.id != null) {
          _searchClientsUnscoped(query, requestId);
          return;
        }
        clientSuggestions.assignAll(list);
      },
      failure: (_) => clientSuggestions.clear(),
    );
  }

  Future<void> _searchClientsUnscoped(String query, int requestId) async {
    final result = await repository.getClients(
      search: query,
      assignedToMe: false,
    );
    if (requestId != _clientSearchRequestId) return;
    result.when(
      success: clientSuggestions.assignAll,
      failure: (_) => clientSuggestions.clear(),
    );
  }

  void selectClientFromSearch(StaffIncidentClientOption client) {
    _clientSearchDebounce?.cancel();
    _clientSearchRequestId++;
    selectedClient.value = client;
    clientSearchController.text = client.name;
    showClientSuggestions.value = false;
    clientSuggestions.clear();
    isSearchingClients.value = false;
    if (client.residenceId != null &&
        client.residenceId!.isNotEmpty &&
        client.residenceName != null &&
        client.residenceName!.isNotEmpty) {
      selectedResidence.value = StaffIncidentResidenceOption(
        id: client.residenceId!,
        name: client.residenceName!,
      );
    }
  }

  Future<void> pickResident() async {
    if (clients.isEmpty) {
      final result = await repository.getClients(assignedToMe: true);
      result.when(
        success: (list) => clients.assignAll(list),
        failure: (error) => AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not load clients',
        ),
      );
    }
    var options = clients.toList();
    final residenceId = selectedResidence.value?.id;
    if (residenceId != null) {
      final scoped = options
          .where(
            (c) =>
                c.residenceId == null ||
                c.residenceId == residenceId ||
                c.residenceId!.isEmpty,
          )
          .toList();
      if (scoped.isNotEmpty) options = scoped;
    }
    final selected = await _pickOption<StaffIncidentClientOption>(
      title: 'Resident / Client',
      options: options,
      labelOf: (o) => o.name,
      subtitleOf: (o) => o.subtitle,
      showInitials: true,
      searchHint: 'Search client...',
    );
    if (selected == null) return;
    selectClientFromSearch(selected);
  }

  Future<void> pickCfsStatus() async {
    final selected = await _pickOption<(String, String)>(
      title: 'CFS Status',
      options: cfsStatusOptions,
      labelOf: (o) => o.$2,
    );
    if (selected == null) return;
    if (cfsStatuses.contains(selected.$1)) {
      cfsStatuses.remove(selected.$1);
    } else {
      cfsStatuses.add(selected.$1);
    }
  }

  void toggleCfsStatus(String value) {
    if (cfsStatuses.contains(value)) {
      cfsStatuses.remove(value);
    } else {
      cfsStatuses.add(value);
    }
  }

  Future<void> _ensureStaffLoaded() async {
    if (staffOptions.isNotEmpty) return;
    final result = await repository.getStaffOptions();
    result.when(
      success: staffOptions.assignAll,
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not load staff',
      ),
    );
  }

  Future<void> pickReportedByStaff() async {
    await _ensureStaffLoaded();
    final selected = await _pickOption<StaffIncidentStaffOption>(
      title: 'Reported By Staff',
      options: staffOptions.toList(),
      labelOf: (o) => o.name,
      subtitleOf: (o) => o.subtitle,
      showInitials: true,
      searchHint: 'Search reported by staff...',
    );
    if (selected != null) reportedByStaff.value = selected;
  }

  Future<void> pickSupervisorStaff() async {
    await _ensureStaffLoaded();
    final selected = await _pickOption<StaffIncidentStaffOption>(
      title: 'Supervisor',
      options: staffOptions.toList(),
      labelOf: (o) => o.name,
      subtitleOf: (o) => o.subtitle,
      showInitials: true,
      searchHint: 'Search supervisor...',
    );
    if (selected != null) supervisorStaff.value = selected;
  }

  Future<void> pickInvestigator() async {
    await _ensureStaffLoaded();
    final selected = await _pickOption<StaffIncidentStaffOption>(
      title: 'Investigator',
      options: staffOptions.toList(),
      labelOf: (o) => o.name,
      subtitleOf: (o) => o.subtitle,
      showInitials: true,
      searchHint: 'Search investigator...',
    );
    if (selected != null) investigator.value = selected;
  }

  Future<void> pickAssignedTo() async {
    await _ensureStaffLoaded();
    final selected = await _pickOption<StaffIncidentStaffOption>(
      title: 'Assigned To',
      options: staffOptions.toList(),
      labelOf: (o) => o.name,
      subtitleOf: (o) => o.subtitle,
      showInitials: true,
      searchHint: 'Search staff...',
    );
    if (selected != null) assignedTo.value = selected;
  }

  Future<void> pickInvestigationStatus() async {
    final selected = await _pickOption<(String, String)>(
      title: 'Investigation Status',
      options: investigationStatusOptions,
      labelOf: (o) => o.$2,
    );
    if (selected != null) investigationStatus.value = selected.$1;
  }

  Future<void> pickExternalAgencyType() async {
    const options = <(String, String)>[
      ('police', 'Police'),
      ('ambulance', 'Ambulance'),
      ('fire', 'Fire'),
      ('cfs', 'Child and Family Services'),
      ('other', 'Other'),
    ];
    final selected = await _pickOption<(String, String)>(
      title: 'Which service',
      options: options,
      labelOf: (o) => o.$2,
    );
    if (selected != null) externalAgencyType.value = selected.$1;
  }

  void updatePartyNotification(
    int index, {
    bool? notified,
    String? contactName,
    String? dateNotified,
  }) {
    if (index < 0 || index >= partyNotifications.length) return;
    partyNotifications[index] = partyNotifications[index].copyWith(
      notified: notified,
      contactName: contactName,
      dateNotified: dateNotified,
    );
  }

  Future<void> promptAddWitness() async {
    final context = Get.context;
    if (context == null || !context.mounted) return;

    final name = await showAppPopup<String>(
      context: context,
      builder: (dialogContext) => const _AddWitnessDialog(),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    if (!witnesses.contains(trimmed)) witnesses.add(trimmed);
  }

  void removeWitness(String name) => witnesses.remove(name);

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _parseDate(incidentDateController.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      incidentDateController.text = _formatDate(picked);
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final initial = _parseTime(incidentTimeController.text) ??
        TimeOfDay.fromDateTime(DateTime.now());
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      incidentTimeController.text = _formatTime(picked);
    }
  }

  Future<void> pickEndTime(BuildContext context) async {
    final initial = _parseTime(endTimeController.text) ??
        _parseTime(incidentTimeController.text) ??
        TimeOfDay.fromDateTime(DateTime.now());
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      endTimeController.text = _formatTime(picked);
    }
  }

  Future<void> pickEvidence() async {
    final picked = await AppFilePicker.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) return;

    for (final file in picked.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;
      var pending = StaffIncidentEvidenceFile(
        localPath: path,
        fileName: file.name,
        mimeType: _mimeForName(file.name),
        isUploading: true,
      );
      evidenceFiles.add(pending);
      final index = evidenceFiles.length - 1;
      final upload = await repository.uploadEvidenceFile(pending);
      if (upload.isFailure) {
        evidenceFiles[index] = pending.copyWith(
          isUploading: false,
          uploadError: upload.error?.message ?? 'Upload failed',
        );
        AppErrorDialog.showResultError(
          upload.error,
          fallbackTitle: 'Could not upload ${file.name}',
        );
        continue;
      }
      evidenceFiles[index] = upload.value!;
    }
  }

  void removeEvidence(StaffIncidentEvidenceFile file) {
    evidenceFiles.remove(file);
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    final validation = _validate();
    if (validation != null) {
      wizardStep.value = validation.step;
      showFormBanner(validation.message);
      return;
    }

    final client = selectedClient.value!;
    final category = selectedCategory.value!;
    final residenceId = selectedResidence.value?.id ??
        client.residenceId ??
        Get.find<UserSession>().residenceId ??
        '';
    if (residenceId.isEmpty) {
      wizardStep.value = 1;
      showFormBanner('Select a residence for this incident report.');
      return;
    }

    final description = descriptionController.text.trim();
    final occurredAt = _occurredAtIso();
    final payload = <String, dynamic>{
      'summary': description,
      'description': description,
      if (detectedDuring.value != null)
        'detectedDuring': detectedDuring.value,
      if (witnesses.isNotEmpty) 'witnesses': witnesses.toList(),
      if (cfsStatuses.isNotEmpty) 'cfsStatus': cfsStatuses.toList(),
      if (childIdController.text.trim().isNotEmpty)
        'childIdNumber': childIdController.text.trim(),
      if (cipController.text.trim().isNotEmpty)
        'childInterventionPractitioner': cipController.text.trim(),
      if (cipOfficeController.text.trim().isNotEmpty)
        'cipOffice': cipOfficeController.text.trim(),
      if (supervisorStaff.value != null) ...{
        'supervisorId': supervisorStaff.value!.id,
        'supervisorName': supervisorStaff.value!.name,
      },
      if (investigationStatus.value != null)
        'investigationStatus': investigationStatus.value,
      if (investigator.value != null) ...{
        'investigatorId': investigator.value!.id,
        'investigatorName': investigator.value!.name,
      },
      if (investigationNotesController.text.trim().isNotEmpty)
        'investigationNotes': investigationNotesController.text.trim(),
      if (rootCauseController.text.trim().isNotEmpty)
        'rootCause': rootCauseController.text.trim(),
      if (correctiveActionController.text.trim().isNotEmpty)
        'correctiveAction': correctiveActionController.text.trim(),
      'followUpRequired': followUpRequired.value,
      if (followUpDateController.text.trim().isNotEmpty)
        'followUpDueDate': followUpDateController.text.trim(),
      if (assignedTo.value != null) ...{
        'assignedToId': assignedTo.value!.id,
        'assignedToName': assignedTo.value!.name,
      },
      'debriefCompleted': debriefCompleted.value,
      if (debriefDetailsController.text.trim().isNotEmpty)
        'debriefDetails': debriefDetailsController.text.trim(),
      'childInformedOfRights': childInformedOfRights.value,
      if (transcriptionController.text.trim().isNotEmpty)
        'transcription': transcriptionController.text.trim(),
      'notifications':
          partyNotifications.map((item) => item.toJson()).toList(),
      'partiesNotified': {
        for (final item in partyNotifications)
          _partySlug(item.party): {
            'notified': item.notified,
            if (item.contactName.trim().isNotEmpty)
              'contactName': item.contactName.trim(),
            if (item.dateNotified.trim().isNotEmpty)
              'dateNotified': item.dateNotified.trim(),
          },
      },
      if (categoryDetailsController.text.trim().isNotEmpty)
        'categoryDetail': categoryDetailsController.text.trim(),
      if (endTimeController.text.trim().isNotEmpty)
        'endTime': endTimeController.text.trim(),
      for (final entry in _reportFormAnswers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };

    isSubmitting.value = true;
    clearFormBanner();

    final immediateAction = immediateActionController.text.trim().isEmpty
        ? null
        : immediateActionController.text.trim();
    final agencyReference = agencyReferenceController.text.trim().isEmpty
        ? null
        : agencyReferenceController.text.trim();
    final agencyResponder = agencyResponderController.text.trim().isEmpty
        ? null
        : agencyResponderController.text.trim();

    try {
      late final String incidentId;
      if (isEditMode) {
        final update = await repository.updateIncident(
          incidentId: editIncidentId!.trim(),
          residenceId: residenceId,
          clientId: client.id,
          categoryId: category.id,
          title: incidentTitleController.text.trim(),
          severity: severity.value.name,
          payload: payload,
          cirTemplateId: selectedCirTemplate.value?.id,
          occurredAt: occurredAt,
          description: description,
          familyNotified: familyGuardianNotified.value,
          immediateAction: immediateAction,
          emergencyServicesContacted: emergencyServicesContacted.value,
          externalAgencyType: emergencyServicesContacted.value
              ? externalAgencyType.value
              : null,
          externalAgencyReference: agencyReference,
          externalAgencyResponder: agencyResponder,
          reportedByStaffId: reportedByStaff.value?.id,
        );
        if (update.isFailure) {
          final info = AppErrorMapper.from(
            update.error,
            fallbackTitle: 'Could not save incident',
          );
          showFormBanner(info.message);
          AppErrorDialog.showResultError(
            update.error,
            fallbackTitle: 'Could not save incident',
          );
          return;
        }
        incidentId = editIncidentId!.trim();
      } else {
        final create = await repository.createIncident(
          residenceId: residenceId,
          clientId: client.id,
          categoryId: category.id,
          title: incidentTitleController.text.trim(),
          severity: severity.value.name,
          payload: payload,
          cirTemplateId: selectedCirTemplate.value?.id,
          occurredAt: occurredAt,
          description: description,
          familyNotified: familyGuardianNotified.value,
          immediateAction: immediateAction,
          emergencyServicesContacted: emergencyServicesContacted.value,
          externalAgencyType: emergencyServicesContacted.value
              ? externalAgencyType.value
              : null,
          externalAgencyReference: agencyReference,
          externalAgencyResponder: agencyResponder,
          reportedByStaffId: reportedByStaff.value?.id,
        );

        if (create.isFailure) {
          final info = AppErrorMapper.from(
            create.error,
            fallbackTitle: 'Could not submit incident',
          );
          showFormBanner(info.message);
          AppErrorDialog.showResultError(
            create.error,
            fallbackTitle: 'Could not submit incident',
          );
          return;
        }
        incidentId = create.value!;
      }
      var evidenceFailed = false;
      for (final file in evidenceFiles.where(
        (f) => f.isReady && !_existingEvidenceUrls.contains(f.fileUrl),
      )) {
        final attached = await repository.attachEvidence(
          incidentId: incidentId,
          fileUrl: file.fileUrl!,
          fileType: file.mimeType ?? _mimeForName(file.fileName),
        );
        if (attached.isFailure) evidenceFailed = true;
      }

      try {
        if (Get.isRegistered<StaffIncidentsController>()) {
          Get.find<StaffIncidentsController>().refresh();
        }
      } catch (_) {}

      final successTitle =
          isEditMode ? 'Incident updated' : 'Incident submitted';
      final successMessage = evidenceFailed
          ? 'Report saved for supervisor review. Some evidence failed to attach.'
          : (isEditMode
              ? 'The report was saved.'
              : 'The report is open for supervisor review.');

      Get.back(result: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.show(
          successTitle,
          successMessage,
          position: SnackPosition.TOP,
          force: true,
        );
      });
    } catch (error) {
      showFormBanner(
        'Could not submit incident. ${error.toString()}',
      );
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }

  /// Returns the failing wizard step + message, or null when valid.
  ({int step, String message})? _validate() {
    if (selectedCategory.value == null) {
      return (step: 0, message: 'Select an incident category.');
    }
    if (incidentTitleController.text.trim().isEmpty) {
      return (step: 0, message: 'Enter an incident title.');
    }
    if (incidentDateController.text.trim().isEmpty ||
        incidentTimeController.text.trim().isEmpty) {
      return (step: 0, message: 'Set the incident date and time.');
    }
    if (_occurredAtIso() == null) {
      return (step: 0, message: 'Incident date/time is invalid.');
    }
    if (descriptionController.text.trim().isEmpty) {
      return (step: 0, message: 'Describe what happened.');
    }
    if (selectedResidence.value == null &&
        (selectedClient.value?.residenceId == null ||
            selectedClient.value!.residenceId!.isEmpty)) {
      return (step: 1, message: 'Select a residence.');
    }
    if (selectedClient.value == null) {
      return (step: 1, message: 'Select a related client.');
    }
    if (evidenceFiles.any((f) => f.isUploading)) {
      return (step: 3, message: 'Wait for evidence uploads to finish.');
    }
    return null;
  }

  Future<T?> _pickOption<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    String Function(T)? subtitleOf,
    bool showInitials = false,
    String? searchHint,
  }) async {
    if (options.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Nothing to choose',
        message: 'No options are available for $title yet.',
      );
      return null;
    }
    final context = Get.context;
    if (context == null) return null;
    return showAppBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
              ),
              child: SearchableOptionList<T>(
                title: title,
                options: options,
                labelOf: labelOf,
                subtitleOf: subtitleOf,
                showInitials: showInitials,
                searchHint: searchHint ?? 'Search $title',
                onSelected: (option) => Navigator.of(sheetContext).pop(option),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _occurredAtIso() {
    final date = _parseDate(incidentDateController.text);
    final time = _parseTime(incidentTimeController.text);
    if (date == null) return null;
    final hour = time?.hour ?? 0;
    final minute = time?.minute ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute)
        .toUtc()
        .toIso8601String();
  }

  static String _partySlug(String party) {
    return party
        .trim()
        .toLowerCase()
        .replaceAll("'", '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  DateTime? _parseDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parts = text.split(RegExp(r'[/-]'));
    if (parts.length == 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(text);
  }

  TimeOfDay? _parseTime(String raw) {
    final text = raw.trim().toUpperCase();
    if (text.isEmpty) return null;
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
    ).firstMatch(text);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final meridiem = match.group(3);
    if (hour == null || minute == null) return null;
    if (meridiem != null) {
      if (meridiem == 'PM' && hour < 12) hour += 12;
      if (meridiem == 'AM' && hour == 12) hour = 0;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final meridiem = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $meridiem';
  }

  String _mimeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'application/octet-stream';
  }

  @override
  void onClose() {
    _clientSearchDebounce?.cancel();
    incidentTitleController.dispose();
    incidentDateController.dispose();
    incidentTimeController.dispose();
    categoryDetailsController.dispose();
    endTimeController.dispose();
    clientSearchController.dispose();
    childIdController.dispose();
    cipController.dispose();
    cipOfficeController.dispose();
    descriptionController.dispose();
    immediateActionController.dispose();
    investigationNotesController.dispose();
    rootCauseController.dispose();
    correctiveActionController.dispose();
    followUpDateController.dispose();
    debriefDetailsController.dispose();
    transcriptionController.dispose();
    agencyReferenceController.dispose();
    agencyResponderController.dispose();
    for (final controller in _reportFormAnswers.values) {
      controller.dispose();
    }
    _reportFormAnswers.clear();
    super.onClose();
  }
}

/// Owns its [TextEditingController] so dismiss/back never disposes a still-mounted field.
class _AddWitnessDialog extends StatefulWidget {
  const _AddWitnessDialog();

  @override
  State<_AddWitnessDialog> createState() => _AddWitnessDialogState();
}

class _AddWitnessDialogState extends State<_AddWitnessDialog> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_input.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetDialog(
      title: const Text('Add witness'),
      content: TextField(
        controller: _input,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Witness name'),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

