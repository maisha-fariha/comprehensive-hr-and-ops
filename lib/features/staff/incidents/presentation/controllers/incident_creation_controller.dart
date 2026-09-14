import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_incident_options.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../domain/repositories/staff_incidents_repository.dart';
import 'staff_incidents_controller.dart';

/// GetX controller for the Staff "Create Incident" form.
class IncidentCreationController extends GetxController {
  final StaffIncidentsRepository repository;

  IncidentCreationController({StaffIncidentsRepository? repository})
      : repository = repository ?? GetIt.instance<StaffIncidentsRepository>();

  static const List<String> detectedDuringOptions = [
    'Morning care',
    'Mealtime',
    'Medication round',
    'Activity',
    'Night check',
    'Handover',
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
  final RxnString detectedDuring = RxnString();

  // Section 2
  final Rx<IncidentSeverity> severity = IncidentSeverity.medium.obs;

  // Section 3
  final RxList<StaffIncidentClientOption> clients =
      <StaffIncidentClientOption>[].obs;
  final Rxn<StaffIncidentClientOption> selectedClient =
      Rxn<StaffIncidentClientOption>();
  final TextEditingController locationController = TextEditingController();
  final RxString reporterName = ''.obs;
  final RxString reporterMeta = ''.obs;
  final RxString reporterInitials = ''.obs;

  // Section 4
  final TextEditingController descriptionController = TextEditingController();

  // Section 5
  final RxList<StaffIncidentEvidenceFile> evidenceFiles =
      <StaffIncidentEvidenceFile>[].obs;

  // Section 6 — tri-state checklist (null = unanswered)
  final RxnBool residentChecked = RxnBool();
  final RxnBool supervisorNotified = RxnBool();
  final RxnBool familyNotified = RxnBool();
  final RxnBool carePlanReviewed = RxnBool();

  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingOptions = false.obs;

  String? get incidentCategoryLabel => selectedCategory.value?.name;
  String? get cirTemplateLabel => selectedCirTemplate.value?.name;
  String? get residentLabel => selectedClient.value?.name;

  @override
  void onInit() {
    super.onInit();
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
    final assigned = await repository.getClients(assignedToMe: true);
    isLoadingOptions.value = false;

    cats.when(
      success: categories.assignAll,
      failure: (_) {},
    );
    templates.when(
      success: cirTemplates.assignAll,
      failure: (_) {},
    );
    assigned.when(
      success: clients.assignAll,
      failure: (_) {},
    );
  }

  void selectSeverity(IncidentSeverity value) => severity.value = value;

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
    final selected = await _pickOption<StaffIncidentClientOption>(
      title: 'Resident / Client',
      options: clients.toList(),
      labelOf: (o) => o.name,
      subtitleOf: (o) => o.subtitle,
    );
    if (selected == null) return;
    selectedClient.value = selected;
    if (locationController.text.trim().isEmpty &&
        (selected.roomLabel?.isNotEmpty ?? false)) {
      locationController.text = selected.roomLabel!;
    }
  }

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

  /// Cycle null → true → false → null for inspector-safe tri-state.
  void cycleChecklist(RxnBool field) {
    final current = field.value;
    if (current == null) {
      field.value = true;
    } else if (current == true) {
      field.value = false;
    } else {
      field.value = null;
    }
  }

  Future<void> pickEvidence() async {
    final picked = await FilePicker.platform.pickFiles(
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
    final validation = _validate();
    if (validation != null) {
      AppErrorDialog.showPageError(
        title: 'Missing details',
        message: validation,
      );
      return;
    }

    final client = selectedClient.value!;
    final category = selectedCategory.value!;
    final residenceId = client.residenceId ??
        Get.find<UserSession>().residenceId ??
        '';
    if (residenceId.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Missing residence',
        message: 'This client has no residence linked for the report.',
      );
      return;
    }

    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    final occurredAt = _occurredAtIso();
    final payload = <String, dynamic>{
      'summary': description,
      'description': description,
      if (location.isNotEmpty) 'location': location,
      if (detectedDuring.value != null)
        'detectedDuring': detectedDuring.value,
    };

    isSubmitting.value = true;
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
      location: location.isEmpty ? null : location,
      residentChecked: residentChecked.value,
      supervisorNotified: supervisorNotified.value,
      familyNotified: familyNotified.value,
      carePlanReviewed: carePlanReviewed.value,
    );

    if (create.isFailure) {
      isSubmitting.value = false;
      AppErrorDialog.showResultError(
        create.error,
        fallbackTitle: 'Could not submit incident',
      );
      return;
    }

    final incidentId = create.value!;
    for (final file in evidenceFiles.where((f) => f.isReady)) {
      await repository.attachEvidence(
        incidentId: incidentId,
        fileUrl: file.fileUrl!,
        fileType: file.mimeType ?? _mimeForName(file.fileName),
      );
    }
    isSubmitting.value = false;

    try {
      if (Get.isRegistered<StaffIncidentsController>()) {
        Get.find<StaffIncidentsController>().refresh();
      }
    } catch (_) {}

    Get.snackbar(
      'Incident submitted',
      'The report is open for supervisor review.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
    Get.back();
  }

  String? _validate() {
    if (selectedCategory.value == null) {
      return 'Select an incident category.';
    }
    if (incidentTitleController.text.trim().isEmpty) {
      return 'Enter an incident title.';
    }
    if (incidentDateController.text.trim().isEmpty ||
        incidentTimeController.text.trim().isEmpty) {
      return 'Set the incident date and time.';
    }
    if (_occurredAtIso() == null) {
      return 'Incident date/time is invalid.';
    }
    if (detectedDuring.value == null || detectedDuring.value!.isEmpty) {
      return 'Select when the incident was detected.';
    }
    if (selectedClient.value == null) {
      return 'Select a resident / client.';
    }
    if (descriptionController.text.trim().isEmpty) {
      return 'Describe what happened.';
    }
    if (evidenceFiles.any((f) => f.isUploading)) {
      return 'Wait for evidence uploads to finish.';
    }
    return null;
  }

  Future<T?> _pickOption<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    String Function(T)? subtitleOf,
  }) async {
    if (options.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Nothing to choose',
        message: 'No options are available for $title yet.',
      );
      return null;
    }
    return showModalBottomSheet<T>(
      context: Get.context!,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(labelOf(option)),
                  subtitle: subtitleOf == null ||
                          subtitleOf(option).trim().isEmpty
                      ? null
                      : Text(subtitleOf(option)),
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
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
    incidentTitleController.dispose();
    incidentDateController.dispose();
    incidentTimeController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
