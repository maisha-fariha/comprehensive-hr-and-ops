import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/incident_category_option.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/repositories/incidents_repository.dart';

/// GetX controller for the 4-step "Create Incident" wizard.
class IncidentCreationController extends GetxController {
  static const List<IncidentCreationStep> steps = IncidentCreationStep.values;

  final IncidentsRepository repository;
  final UserSession session;

  IncidentCreationController({
    IncidentsRepository? repository,
    UserSession? session,
  })  : repository = repository ?? GetIt.instance<IncidentsRepository>(),
        session = session ?? Get.find<UserSession>();

  final Rx<IncidentCreationStep> currentStep = IncidentCreationStep.details.obs;
  final RxBool isSubmitting = false.obs;
  final RxString draftId = ''.obs;
  final RxString submitError = ''.obs;

  int get currentStepIndex => steps.indexOf(currentStep.value);
  bool get isLastStep => currentStep.value == IncidentCreationStep.evidence;

  // Step 1 - Incident Details
  final RxList<IncidentCategoryOption> categories = <IncidentCategoryOption>[].obs;
  final RxBool isLoadingCategories = false.obs;
  final Rxn<IncidentCategoryOption> selectedCategory =
      Rxn<IncidentCategoryOption>();
  final TextEditingController incidentTitleController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final Rxn<IncidentClientOption> selectedClient = Rxn<IncidentClientOption>();
  final RxList<IncidentClientOption> clientSuggestions =
      <IncidentClientOption>[].obs;
  final RxBool isSearchingClients = false.obs;
  final RxBool showClientSuggestions = false.obs;
  final RxString clientSearchError = ''.obs;
  final RxList<IncidentResidenceOption> residences =
      <IncidentResidenceOption>[].obs;
  final RxBool isLoadingResidences = false.obs;
  final Rxn<IncidentResidenceOption> selectedResidence =
      Rxn<IncidentResidenceOption>();
  final Rx<String?> residence = Rx<String?>(null);
  final RxnString selectedResidenceId = RxnString();
  final TextEditingController incidentDateController = TextEditingController();
  final TextEditingController incidentTimeController = TextEditingController();
  final Rx<IncidentSeverity> severity = IncidentSeverity.high.obs;
  final Rx<String?> detectedDuring = Rx<String?>(null);

  static const Duration _clientSearchDebounce = Duration(milliseconds: 350);
  Timer? _clientSearchDebounceTimer;
  int _clientSearchRequestId = 0;

  String? get incidentCategory => selectedCategory.value?.name;

  // Step 2 - People & Location
  final TextEditingController involvedClientController = TextEditingController();
  final TextEditingController staffInvolvedController = TextEditingController();
  final Rx<String?> reportedBy = Rx<String?>(null);
  final TextEditingController locationController = TextEditingController();
  final RxList<String> witnesses = <String>[].obs;

  // Step 3 - Immediate Action & Investigation
  final TextEditingController immediateActionController = TextEditingController();
  final TextEditingController investigationNotesController =
      TextEditingController();
  final RxBool followUpRequired = false.obs;
  final TextEditingController followUpDateController = TextEditingController();
  final Rx<String?> supervisorAssignment = Rx<String?>(null);

  // Step 4 - Evidence & Submission
  final RxList<String> uploadedFileNames = <String>[].obs;
  final TextEditingController additionalNotesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final sessionResidenceName = session.residenceName;
    final sessionResidenceId = session.residenceId;
    if (sessionResidenceName != null && sessionResidenceName.isNotEmpty) {
      final seeded = IncidentResidenceOption(
        id: sessionResidenceId ?? sessionResidenceName,
        name: sessionResidenceName,
      );
      selectedResidence.value = seeded;
      residence.value = seeded.name;
      selectedResidenceId.value = seeded.id;
    }
    reportedBy.value = session.displayName;
    draftId.value = 'Draft';
    loadCategories();
    loadResidences();
  }

  /// Debounced typeahead for Client / Resident (`GET /clients?search=`).
  void onClientQueryChanged(String value) {
    final selected = selectedClient.value;
    if (selected != null && value.trim() != selected.name) {
      selectedClient.value = null;
    }

    _clientSearchDebounceTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _clientSearchRequestId++;
      isSearchingClients.value = false;
      clientSuggestions.clear();
      showClientSuggestions.value = false;
      clientSearchError.value = '';
      return;
    }

    showClientSuggestions.value = true;
    _clientSearchDebounceTimer = Timer(
      _clientSearchDebounce,
      () => _searchClients(trimmed),
    );
  }

  Future<void> _searchClients(String trimmed) async {
    final requestId = ++_clientSearchRequestId;
    isSearchingClients.value = true;
    clientSearchError.value = '';

    final result = await repository.searchClients(trimmed);
    if (requestId != _clientSearchRequestId) return;

    isSearchingClients.value = false;
    result.when(
      success: (options) {
        clientSuggestions.assignAll(options);
        showClientSuggestions.value = true;
      },
      failure: (error) {
        clientSuggestions.clear();
        clientSearchError.value = error.message;
        showClientSuggestions.value = true;
      },
    );
  }

  void selectClient(IncidentClientOption option) {
    _clientSearchDebounceTimer?.cancel();
    _clientSearchRequestId++;
    selectedClient.value = option;
    clientController.text = option.name;
    clientSuggestions.clear();
    showClientSuggestions.value = false;
    clientSearchError.value = '';
    isSearchingClients.value = false;

    if (option.residenceName != null && option.residenceName!.isNotEmpty) {
      selectResidence(
        IncidentResidenceOption(
          id: option.residenceId ?? option.residenceName!,
          name: option.residenceName!,
        ),
      );
    } else if (option.residenceId != null && option.residenceId!.isNotEmpty) {
      selectedResidenceId.value = option.residenceId;
    }
  }

  void dismissClientSuggestions() {
    showClientSuggestions.value = false;
  }

  Future<void> loadResidences() async {
    if (isLoadingResidences.value) return;
    isLoadingResidences.value = true;
    final result = await repository.getResidences();
    isLoadingResidences.value = false;
    result.when(
      success: (data) {
        residences.assignAll(data);
        final currentId = selectedResidenceId.value;
        if (currentId != null && currentId.isNotEmpty) {
          for (final option in data) {
            if (option.id == currentId) {
              selectResidence(option);
              break;
            }
          }
        }
      },
      failure: (error) {
        AppSnackbar.show('Could not load residences', error.message);
      },
    );
  }

  void selectResidence(IncidentResidenceOption option) {
    selectedResidence.value = option;
    residence.value = option.name;
    selectedResidenceId.value = option.id;
  }

  Future<void> pickResidence(BuildContext context) async {
    if (residences.isEmpty && !isLoadingResidences.value) {
      await loadResidences();
    }
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<IncidentResidenceOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Obx(() {
            if (isLoadingResidences.value && residences.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondaryTeal,
                  ),
                ),
              );
            }
            if (residences.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No residences available.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: loadResidences,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Select residence',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                for (final option in residences)
                  ListTile(
                    title: Text(
                      option.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHeading,
                      ),
                    ),
                    trailing: selectedResidenceId.value == option.id
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.secondaryTeal,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
              ],
            );
          }),
        );
      },
    );

    if (selected != null) selectResidence(selected);
  }

  Future<void> loadCategories() async {
    if (isLoadingCategories.value) return;
    isLoadingCategories.value = true;
    final result = await repository.getCategories();
    isLoadingCategories.value = false;
    result.when(
      success: (data) => categories.assignAll(data),
      failure: (error) {
        AppSnackbar.show('Could not load categories', error.message);
      },
    );
  }

  void selectCategory(IncidentCategoryOption option) {
    selectedCategory.value = option;
  }

  Future<void> pickCategory(BuildContext context) async {
    if (categories.isEmpty && !isLoadingCategories.value) {
      await loadCategories();
    }
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<IncidentCategoryOption>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Obx(() {
            if (isLoadingCategories.value && categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondaryTeal,
                  ),
                ),
              );
            }
            if (categories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No categories available.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: loadCategories,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Select category',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                for (final option in categories)
                  ListTile(
                    title: Text(
                      option.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHeading,
                      ),
                    ),
                    trailing: selectedCategory.value?.id == option.id
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.secondaryTeal,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
              ],
            );
          }),
        );
      },
    );

    if (selected != null) selectCategory(selected);
  }

  Future<void> pickIncidentDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _parseIncidentDate(incidentDateController.text) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime(now.year - 10))
          ? now
          : (initial.isAfter(now) ? now : initial),
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.secondaryTeal,
                ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null) return;
    incidentDateController.text = _formatIncidentDate(selected);
  }

  Future<void> pickIncidentTime(BuildContext context) async {
    final initial = _parseIncidentTime(incidentTimeController.text) ??
        TimeOfDay.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.secondaryTeal,
                ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null) return;
    incidentTimeController.text = _formatIncidentTime(selected);
  }

  DateTime? _parseIncidentDate(String raw) {
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

  TimeOfDay? _parseIncidentTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatIncidentDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  String _formatIncidentTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void goToStep(IncidentCreationStep step) => currentStep.value = step;

  void nextStep() {
    final index = currentStepIndex;
    if (index < steps.length - 1) {
      currentStep.value = steps[index + 1];
    }
  }

  void previousStep() {
    final index = currentStepIndex;
    if (index > 0) {
      currentStep.value = steps[index - 1];
    }
  }

  void addWitness(String name) {
    if (name.trim().isEmpty || witnesses.contains(name)) return;
    witnesses.add(name.trim());
  }

  void removeWitness(String name) => witnesses.remove(name);

  void removeUploadedFile(String name) => uploadedFileNames.remove(name);

  Future<bool> submit({bool asDraft = false}) async {
    final title = incidentTitleController.text.trim();
    if (title.isEmpty) {
      submitError.value = 'Please enter an incident title.';
      AppSnackbar.show('Missing details', submitError.value);
      return false;
    }

    isSubmitting.value = true;
    submitError.value = '';

    final category = selectedCategory.value;
    final client = selectedClient.value;
    final clientName = clientController.text.trim().isEmpty
        ? involvedClientController.text.trim()
        : clientController.text.trim();
    final payload = <String, dynamic>{
      'title': title,
      'category': category?.name,
      if (category != null && category.id.isNotEmpty) 'categoryId': category.id,
      'clientName': clientName,
      if (client != null && client.id.isNotEmpty) 'clientId': client.id,
      'residenceId': selectedResidenceId.value ?? session.residenceId,
      'residenceName': residence.value ?? session.residenceName,
      'incidentDate': incidentDateController.text.trim(),
      'incidentTime': incidentTimeController.text.trim(),
      'severity': severity.value.name,
      'detectedDuring': detectedDuring.value,
      'involvedClient': involvedClientController.text.trim(),
      'staffInvolved': staffInvolvedController.text.trim(),
      'reportedBy': reportedBy.value,
      'location': locationController.text.trim(),
      'witnesses': witnesses.toList(),
      'immediateAction': immediateActionController.text.trim(),
      'investigationNotes': investigationNotesController.text.trim(),
      'followUpRequired': followUpRequired.value,
      'followUpDate': followUpDateController.text.trim(),
      'supervisorAssignment': supervisorAssignment.value,
      'additionalNotes': additionalNotesController.text.trim(),
      'evidenceFileNames': uploadedFileNames.toList(),
      'status': asDraft ? 'draft' : 'open',
      'isDraft': asDraft,
    };

    final result = await repository.createIncident(payload);
    isSubmitting.value = false;

    return result.when(
      success: (id) {
        if (id.isNotEmpty) draftId.value = id.startsWith('#') ? id : '#$id';
        AppSnackbar.show(
          asDraft ? 'Draft saved' : 'Incident submitted',
          asDraft
              ? 'Your draft was saved on the care home.'
              : 'The incident was created successfully.',
        );
        return true;
      },
      failure: (error) {
        submitError.value = error.message;
        AppSnackbar.show(
          asDraft ? 'Could not save draft' : 'Could not submit',
          error.message,
        );
        return false;
      },
    );
  }

  @override
  void onClose() {
    _clientSearchDebounceTimer?.cancel();
    incidentTitleController.dispose();
    clientController.dispose();
    incidentDateController.dispose();
    incidentTimeController.dispose();
    involvedClientController.dispose();
    staffInvolvedController.dispose();
    locationController.dispose();
    immediateActionController.dispose();
    investigationNotesController.dispose();
    followUpDateController.dispose();
    additionalNotesController.dispose();
    super.onClose();
  }
}
