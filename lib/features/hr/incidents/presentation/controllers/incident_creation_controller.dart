import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/incident_category_option.dart';
import '../../domain/entities/incident_cir_template_option.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_evidence_file.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incident_staff_option.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/repositories/incidents_repository.dart';

/// GetX controller for the 4-step "Create Incident" wizard.
class IncidentCreationController extends GetxController {
  static const List<IncidentCreationStep> steps = IncidentCreationStep.values;

  static const List<String> detectedDuringOptions = [
    'Day shift',
    'Evening shift',
    'Night shift',
    'Medication round',
    'Personal care',
    'Meal time',
    'Activity / outing',
    'Handover',
    'Other',
  ];

  final IncidentsRepository repository;
  final UserSession session;
  final String? editIncidentId;

  IncidentCreationController({
    IncidentsRepository? repository,
    UserSession? session,
    this.editIncidentId,
  })  : repository = repository ?? GetIt.instance<IncidentsRepository>(),
        session = session ?? Get.find<UserSession>();

  final Rx<IncidentCreationStep> currentStep = IncidentCreationStep.details.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingEdit = false.obs;
  final RxString draftId = ''.obs;
  final RxString submitError = ''.obs;
  final RxnString existingStatus = RxnString();

  bool get isEditMode =>
      editIncidentId != null && editIncidentId!.trim().isNotEmpty;

  int get currentStepIndex => steps.indexOf(currentStep.value);
  bool get isLastStep => currentStep.value == IncidentCreationStep.evidence;

  // Step 1 - Incident Details
  final RxList<IncidentCategoryOption> categories = <IncidentCategoryOption>[].obs;
  final RxBool isLoadingCategories = false.obs;
  final Rxn<IncidentCategoryOption> selectedCategory =
      Rxn<IncidentCategoryOption>();

  final RxList<IncidentCirTemplateOption> cirTemplates =
      <IncidentCirTemplateOption>[].obs;
  final RxBool isLoadingCirTemplates = false.obs;
  final Rxn<IncidentCirTemplateOption> selectedCirTemplate =
      Rxn<IncidentCirTemplateOption>();

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
  final RxnString detectedDuring = RxnString();

  static const Duration _clientSearchDebounce = Duration(milliseconds: 350);
  Timer? _clientSearchDebounceTimer;
  int _clientSearchRequestId = 0;

  String? get incidentCategory => selectedCategory.value?.name;
  String? get cirTemplateLabel => selectedCirTemplate.value?.name;

  // Step 2 - People & Location
  final TextEditingController involvedClientController = TextEditingController();
  final Rxn<IncidentClientOption> selectedInvolvedClient =
      Rxn<IncidentClientOption>();
  final RxList<IncidentClientOption> involvedClientSuggestions =
      <IncidentClientOption>[].obs;
  final RxBool isSearchingInvolvedClients = false.obs;
  final RxBool showInvolvedClientSuggestions = false.obs;
  Timer? _involvedClientDebounce;
  int _involvedClientRequestId = 0;

  final TextEditingController staffInvolvedController = TextEditingController();
  final RxList<IncidentStaffOption> staffOptions = <IncidentStaffOption>[].obs;
  final RxBool isLoadingStaff = false.obs;
  final Rxn<IncidentStaffOption> selectedStaffInvolved =
      Rxn<IncidentStaffOption>();
  final Rxn<IncidentStaffOption> selectedReporter = Rxn<IncidentStaffOption>();
  final RxnString reportedBy = RxnString();
  final TextEditingController locationController = TextEditingController();
  final RxList<String> witnesses = <String>[].obs;

  // Step 3 - Immediate Action & Investigation
  final TextEditingController immediateActionController = TextEditingController();
  final TextEditingController investigationNotesController =
      TextEditingController();
  final RxBool followUpRequired = false.obs;
  final TextEditingController followUpDateController = TextEditingController();
  final Rxn<IncidentStaffOption> selectedSupervisor = Rxn<IncidentStaffOption>();
  final RxnString supervisorAssignment = RxnString();

  // Step 4 - Evidence & Submission
  final RxList<IncidentEvidenceFile> evidenceFiles =
      <IncidentEvidenceFile>[].obs;
  final TextEditingController additionalNotesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    if (!isEditMode) {
      final now = DateTime.now();
      incidentDateController.text = _formatIncidentDate(now);
      incidentTimeController.text = _formatIncidentTime(
        TimeOfDay(hour: now.hour, minute: now.minute),
      );

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
    } else {
      final id = editIncidentId!.trim();
      draftId.value = '#${id.length > 8 ? id.substring(0, 8) : id}';
    }

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      loadCategories(),
      loadCirTemplates(),
      loadResidences(),
      loadStaff(),
    ]);
    if (isEditMode) {
      await loadForEdit(editIncidentId!.trim());
    }
  }

  // ── Lookups ────────────────────────────────────────────────────────────

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

  Future<void> loadCirTemplates() async {
    if (isLoadingCirTemplates.value) return;
    isLoadingCirTemplates.value = true;
    final result = await repository.getCirTemplates();
    isLoadingCirTemplates.value = false;
    result.when(
      success: (data) {
        cirTemplates.assignAll(data);
        if (!isEditMode &&
            selectedCirTemplate.value == null &&
            data.isNotEmpty) {
          selectedCirTemplate.value = data.first;
        }
      },
      failure: (error) {
        AppSnackbar.show('Could not load CIR templates', error.message);
      },
    );
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

  Future<void> loadStaff() async {
    if (isLoadingStaff.value) return;
    isLoadingStaff.value = true;
    final result = await repository.getStaff();
    isLoadingStaff.value = false;
    result.when(
      success: (data) {
        staffOptions.assignAll(data);
        final display = session.displayName.trim().toLowerCase();
        final email = session.email.trim().toLowerCase();
        for (final option in data) {
          final matchesName =
              display.isNotEmpty && option.name.toLowerCase() == display;
          final matchesEmail = email.isNotEmpty &&
              (option.email ?? '').toLowerCase() == email;
          if (matchesName || matchesEmail) {
            selectReporter(option);
            break;
          }
        }
      },
      failure: (error) {
        AppSnackbar.show('Could not load staff', error.message);
      },
    );
  }

  // ── Client search ──────────────────────────────────────────────────────

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

    // Keep Step 2 involved client in sync when empty / same client.
    if (selectedInvolvedClient.value == null ||
        involvedClientController.text.trim().isEmpty ||
        selectedInvolvedClient.value?.id == option.id) {
      selectInvolvedClient(option);
    }

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

  void onInvolvedClientQueryChanged(String value) {
    final selected = selectedInvolvedClient.value;
    if (selected != null && value.trim() != selected.name) {
      selectedInvolvedClient.value = null;
    }
    _involvedClientDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _involvedClientRequestId++;
      isSearchingInvolvedClients.value = false;
      involvedClientSuggestions.clear();
      showInvolvedClientSuggestions.value = false;
      return;
    }
    showInvolvedClientSuggestions.value = true;
    _involvedClientDebounce = Timer(_clientSearchDebounce, () async {
      final requestId = ++_involvedClientRequestId;
      isSearchingInvolvedClients.value = true;
      final result = await repository.searchClients(trimmed);
      if (requestId != _involvedClientRequestId) return;
      isSearchingInvolvedClients.value = false;
      result.when(
        success: (options) {
          involvedClientSuggestions.assignAll(options);
          showInvolvedClientSuggestions.value = true;
        },
        failure: (_) {
          involvedClientSuggestions.clear();
          showInvolvedClientSuggestions.value = true;
        },
      );
    });
  }

  void selectInvolvedClient(IncidentClientOption option) {
    _involvedClientDebounce?.cancel();
    _involvedClientRequestId++;
    selectedInvolvedClient.value = option;
    involvedClientController.text = option.name;
    involvedClientSuggestions.clear();
    showInvolvedClientSuggestions.value = false;
    isSearchingInvolvedClients.value = false;
  }

  // ── Pickers ────────────────────────────────────────────────────────────

  void selectCategory(IncidentCategoryOption option) {
    selectedCategory.value = option;
    if (incidentTitleController.text.trim().isEmpty) {
      incidentTitleController.text = option.name;
    }
  }

  void selectCirTemplate(IncidentCirTemplateOption option) {
    selectedCirTemplate.value = option;
  }

  void selectResidence(IncidentResidenceOption option) {
    selectedResidence.value = option;
    residence.value = option.name;
    selectedResidenceId.value = option.id;
  }

  void selectStaffInvolved(IncidentStaffOption option) {
    selectedStaffInvolved.value = option;
    staffInvolvedController.text = option.name;
  }

  void selectReporter(IncidentStaffOption option) {
    selectedReporter.value = option;
    reportedBy.value = option.name;
  }

  void selectSupervisor(IncidentStaffOption option) {
    selectedSupervisor.value = option;
    supervisorAssignment.value = option.name;
  }

  Future<void> pickCategory(BuildContext context) async {
    if (categories.isEmpty && !isLoadingCategories.value) {
      await loadCategories();
    }
    if (!context.mounted) return;
    final selected = await _showOptionsSheet<IncidentCategoryOption>(
      context: context,
      title: 'Select category',
      isLoading: isLoadingCategories,
      options: categories,
      labelOf: (option) => option.name,
      selectedId: selectedCategory.value?.id,
      idOf: (option) => option.id,
      onRetry: loadCategories,
    );
    if (selected != null) selectCategory(selected);
  }

  Future<void> pickCirTemplate(BuildContext context) async {
    if (cirTemplates.isEmpty && !isLoadingCirTemplates.value) {
      await loadCirTemplates();
    }
    if (!context.mounted) return;
    final selected = await _showOptionsSheet<IncidentCirTemplateOption>(
      context: context,
      title: 'Select CIR template',
      isLoading: isLoadingCirTemplates,
      options: cirTemplates,
      labelOf: (option) => option.name,
      subtitleOf: (option) => option.subtitle,
      selectedId: selectedCirTemplate.value?.id,
      idOf: (option) => option.id,
      onRetry: loadCirTemplates,
    );
    if (selected != null) selectCirTemplate(selected);
  }

  Future<void> pickResidence(BuildContext context) async {
    if (residences.isEmpty && !isLoadingResidences.value) {
      await loadResidences();
    }
    if (!context.mounted) return;
    final selected = await _showOptionsSheet<IncidentResidenceOption>(
      context: context,
      title: 'Select residence',
      isLoading: isLoadingResidences,
      options: residences,
      labelOf: (option) => option.name,
      selectedId: selectedResidenceId.value,
      idOf: (option) => option.id,
      onRetry: loadResidences,
    );
    if (selected != null) selectResidence(selected);
  }

  Future<void> pickDetectedDuring(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Detected during',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              for (final option in detectedDuringOptions)
                ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  trailing: detectedDuring.value == option
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) detectedDuring.value = selected;
  }

  Future<void> pickStaffInvolved(BuildContext context) async {
    final selected = await _pickStaff(context, title: 'Staff involved');
    if (selected != null) selectStaffInvolved(selected);
  }

  Future<void> pickReporter(BuildContext context) async {
    final selected = await _pickStaff(context, title: 'Reported by');
    if (selected != null) selectReporter(selected);
  }

  Future<void> pickSupervisor(BuildContext context) async {
    final selected = await _pickStaff(
      context,
      title: 'Assign supervisor',
    );
    if (selected != null) selectSupervisor(selected);
  }

  Future<IncidentStaffOption?> _pickStaff(
    BuildContext context, {
    required String title,
  }) async {
    if (staffOptions.isEmpty && !isLoadingStaff.value) {
      await loadStaff();
    }
    if (!context.mounted) return null;
    return _showOptionsSheet<IncidentStaffOption>(
      context: context,
      title: title,
      isLoading: isLoadingStaff,
      options: staffOptions,
      labelOf: (option) => option.name,
      subtitleOf: (option) => option.subtitle ?? '',
      selectedId: null,
      idOf: (option) => option.id,
      onRetry: loadStaff,
    );
  }

  Future<T?> _showOptionsSheet<T>({
    required BuildContext context,
    required String title,
    required RxBool isLoading,
    required RxList<T> options,
    required String Function(T) labelOf,
    required String Function(T) idOf,
    required Future<void> Function() onRetry,
    String? selectedId,
    String Function(T)? subtitleOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Obx(() {
            if (isLoading.value && options.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondaryTeal,
                  ),
                ),
              );
            }
            if (options.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No options available.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
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
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                for (final option in options)
                  ListTile(
                    title: Text(
                      labelOf(option),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHeading,
                      ),
                    ),
                    subtitle: subtitleOf == null ||
                            subtitleOf(option).trim().isEmpty
                        ? null
                        : Text(
                            subtitleOf(option),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textSecondary,
                            ),
                          ),
                    trailing: selectedId != null && idOf(option) == selectedId
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
  }

  Future<void> pickIncidentDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _parseIncidentDate(incidentDateController.text) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      builder: _pickerTheme,
    );
    if (selected == null) return;
    incidentDateController.text = _formatIncidentDate(selected);
  }

  Future<void> pickIncidentTime(BuildContext context) async {
    final initial =
        _parseIncidentTime(incidentTimeController.text) ?? TimeOfDay.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: _pickerTheme,
    );
    if (selected == null) return;
    incidentTimeController.text = _formatIncidentTime(selected);
  }

  Future<void> pickFollowUpDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _parseIncidentDate(followUpDateController.text) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: _pickerTheme,
    );
    if (selected == null) return;
    followUpDateController.text = _formatIncidentDate(selected);
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.secondaryTeal,
            ),
      ),
      child: child!,
    );
  }

  // ── Witnesses & evidence ───────────────────────────────────────────────

  Future<void> promptAddWitness(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _AddWitnessDialog(),
    );
    if (name == null) return;
    addWitness(name);
  }

  void addWitness(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || witnesses.contains(trimmed)) return;
    witnesses.add(trimmed);
  }

  void removeWitness(String name) => witnesses.remove(name);

  Future<void> pickEvidenceFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
      );
      if (result == null) return;

      const allowed = {
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'heic',
        'webp',
      };

      for (final file in result.files) {
        final path = file.path;
        if (path == null || path.isEmpty) continue;
        final ext = file.extension?.toLowerCase() ??
            file.name.split('.').last.toLowerCase();
        if (!allowed.contains(ext)) {
          AppSnackbar.show(
            'Unsupported file',
            '${file.name} is not an allowed evidence type.',
          );
          continue;
        }
        final pending = IncidentEvidenceFile(
          localPath: path,
          fileName: file.name,
          mimeType: _mimeForName(file.name),
          isUploading: true,
        );
        evidenceFiles.add(pending);
        await _uploadEvidenceAt(evidenceFiles.length - 1);
      }
    } on MissingPluginException {
      AppSnackbar.show(
        'Restart required',
        'Stop the app completely and run it again so file picking can load.',
      );
    } catch (error) {
      AppSnackbar.show('Could not open files', error.toString());
    }
  }

  Future<void> _uploadEvidenceAt(int index) async {
    if (index < 0 || index >= evidenceFiles.length) return;
    final current = evidenceFiles[index];
    evidenceFiles[index] = current.copyWith(isUploading: true, clearError: true);
    final result = await repository.uploadEvidenceFile(current);
    if (index >= evidenceFiles.length) return;
    result.when(
      success: (uploaded) {
        evidenceFiles[index] = uploaded;
      },
      failure: (error) {
        evidenceFiles[index] = current.copyWith(
          isUploading: false,
          uploadError: error.message,
        );
        AppSnackbar.show('Upload failed', error.message);
      },
    );
  }

  void removeEvidenceFile(IncidentEvidenceFile file) {
    evidenceFiles.removeWhere(
      (item) =>
          item.localPath == file.localPath && item.fileName == file.fileName,
    );
  }

  String _mimeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  // ── Edit mode ──────────────────────────────────────────────────────────

  Future<void> loadForEdit(String incidentId) async {
    isLoadingEdit.value = true;
    final result = await repository.getIncidentDetail(incidentId);
    isLoadingEdit.value = false;
    result.when(
      success: _applyIncidentDetail,
      failure: (error) {
        AppSnackbar.show('Could not load incident', error.message);
      },
    );
  }

  void _applyIncidentDetail(Map<String, dynamic> json) {
    final id = JsonCodec.stringOr(json['id'], editIncidentId ?? 'incident');
    draftId.value = '#${id.length > 8 ? id.substring(0, 8) : id}';
    existingStatus.value = JsonCodec.string(json['status']);

    incidentTitleController.text = JsonCodec.stringOr(json['title'], '');

    final categoryMap = JsonCodec.mapAt(json, 'category') ?? const {};
    final categoryId = JsonCodec.string(json['categoryId'] ?? categoryMap['id']);
    final categoryName = JsonCodec.string(categoryMap['name'] ?? json['category']);
    if (categoryId != null && categoryId.isNotEmpty) {
      IncidentCategoryOption? matched;
      for (final option in categories) {
        if (option.id == categoryId) {
          matched = option;
          break;
        }
      }
      selectedCategory.value = matched ??
          IncidentCategoryOption(
            id: categoryId,
            name: categoryName ?? 'Category',
          );
    }

    final cirTemplateId = JsonCodec.string(json['cirTemplateId']);
    if (cirTemplateId != null && cirTemplateId.isNotEmpty) {
      IncidentCirTemplateOption? matched;
      for (final option in cirTemplates) {
        if (option.id == cirTemplateId) {
          matched = option;
          break;
        }
      }
      if (matched != null) selectedCirTemplate.value = matched;
    }

    final clientMap = JsonCodec.mapAt(json, 'client') ??
        JsonCodec.mapAt(json, 'resident') ??
        const {};
    final clientId = JsonCodec.string(json['clientId'] ?? clientMap['id']);
    final clientName = JsonCodec.string(
          clientMap['name'] ??
              clientMap['fullName'] ??
              json['clientName'] ??
              json['residentName'],
        ) ??
        '';
    if (clientId != null && clientId.isNotEmpty) {
      final client = IncidentClientOption(
        id: clientId,
        name: clientName.isEmpty ? 'Client' : clientName,
      );
      selectedClient.value = client;
      clientController.text = client.name;
    }

    final residenceMap = JsonCodec.mapAt(json, 'residence') ?? const {};
    final residenceId = JsonCodec.string(
      json['residenceId'] ?? residenceMap['id'],
    );
    final residenceName = JsonCodec.string(
          residenceMap['name'] ?? json['residenceName'],
        ) ??
        '';
    if (residenceId != null && residenceId.isNotEmpty) {
      IncidentResidenceOption? matched;
      for (final option in residences) {
        if (option.id == residenceId) {
          matched = option;
          break;
        }
      }
      final option = matched ??
          IncidentResidenceOption(
            id: residenceId,
            name: residenceName.isEmpty ? 'Residence' : residenceName,
          );
      selectedResidence.value = option;
      residence.value = option.name;
      selectedResidenceId.value = option.id;
    }

    final reportedAt = JsonCodec.dateTime(json['reportedAt'] ?? json['createdAt']);
    if (reportedAt != null) {
      final local = reportedAt.toLocal();
      incidentDateController.text = _formatIncidentDate(local);
      incidentTimeController.text = _formatIncidentTime(
        TimeOfDay(hour: local.hour, minute: local.minute),
      );
    }

    final severityRaw =
        (JsonCodec.string(json['severity']) ?? 'high').toLowerCase();
    severity.value = IncidentSeverity.values.firstWhere(
      (value) => value.name == severityRaw,
      orElse: () => IncidentSeverity.high,
    );

    final payload = JsonCodec.mapAt(json, 'payload') ??
        JsonCodec.mapAt(json, 'payloadJson') ??
        const {};

    locationController.text = JsonCodec.stringOr(payload['location'], '');
    detectedDuring.value = JsonCodec.string(payload['detectedDuring']);
    immediateActionController.text = JsonCodec.stringOr(
      payload['immediateAction'],
      '',
    );
    additionalNotesController.text = JsonCodec.stringOr(
      payload['additionalNotes'],
      '',
    );
    followUpRequired.value = payload['followUpRequired'] == true;
    followUpDateController.text = JsonCodec.stringOr(payload['followUpDate'], '');

    final involvedId = JsonCodec.string(payload['involvedClientId']);
    final involvedName = JsonCodec.stringOr(
      payload['involvedClientName'],
      '',
    );
    if (involvedId != null && involvedId.isNotEmpty) {
      selectedInvolvedClient.value = IncidentClientOption(
        id: involvedId,
        name: involvedName.isEmpty ? 'Client' : involvedName,
      );
      involvedClientController.text = selectedInvolvedClient.value!.name;
    } else if (involvedName.isNotEmpty) {
      involvedClientController.text = involvedName;
    }

    final staffInvolvedId = JsonCodec.string(payload['staffInvolvedId']);
    final staffInvolvedName = JsonCodec.stringOr(
      payload['staffInvolvedName'],
      '',
    );
    if (staffInvolvedId != null) {
      selectedStaffInvolved.value = _staffById(staffInvolvedId) ??
          IncidentStaffOption(
            id: staffInvolvedId,
            name: staffInvolvedName.isEmpty ? 'Staff' : staffInvolvedName,
          );
      staffInvolvedController.text = selectedStaffInvolved.value!.name;
    } else if (staffInvolvedName.isNotEmpty) {
      staffInvolvedController.text = staffInvolvedName;
    }

    final reporterId = JsonCodec.string(
      payload['reportedByStaffId'] ?? json['reportedBy'],
    );
    final reporterName = JsonCodec.string(
      payload['reportedByName'] ?? json['reportedByName'],
    );
    if (reporterId != null && reporterId.isNotEmpty) {
      selectedReporter.value = _staffById(reporterId) ??
          (reporterName == null
              ? null
              : IncidentStaffOption(id: reporterId, name: reporterName));
    }
    reportedBy.value = selectedReporter.value?.name ??
        reporterName ??
        session.displayName;

    final supervisorId = JsonCodec.string(payload['supervisorId']);
    final supervisorName = JsonCodec.string(payload['supervisorName']);
    if (supervisorId != null && supervisorId.isNotEmpty) {
      selectedSupervisor.value = _staffById(supervisorId) ??
          IncidentStaffOption(
            id: supervisorId,
            name: supervisorName ?? 'Supervisor',
          );
      supervisorAssignment.value = selectedSupervisor.value?.name;
    } else if (supervisorName != null) {
      supervisorAssignment.value = supervisorName;
    }

    final witnessRaw = payload['witnesses'];
    if (witnessRaw is List) {
      witnesses.assignAll(
        witnessRaw
            .map((item) => JsonCodec.string(item) ?? item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList(),
      );
    }

    final investigation = JsonCodec.mapAt(json, 'investigation') ?? const {};
    investigationNotesController.text = JsonCodec.stringOr(
      investigation['findings'] ?? payload['investigationNotes'],
      '',
    );
    if (immediateActionController.text.trim().isEmpty) {
      immediateActionController.text = JsonCodec.stringOr(
        investigation['correctiveActions'],
        '',
      );
    }

    final evidenceRaw = json['evidence'];
    if (evidenceRaw is List) {
      final files = <IncidentEvidenceFile>[];
      for (final item in evidenceRaw) {
        if (item is! Map) continue;
        final map = JsonCodec.asMap(item);
        final url = JsonCodec.string(
          map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
        );
        if (url == null || url.isEmpty) continue;
        final name = JsonCodec.stringOr(
          map['fileName'] ?? map['name'],
          url.split('/').last,
        );
        files.add(
          IncidentEvidenceFile(
            localPath: '',
            fileName: name,
            mimeType: JsonCodec.string(map['fileType'] ?? map['mimeType']),
            fileUrl: url,
          ),
        );
      }
      evidenceFiles.assignAll(files);
    }
  }

  IncidentStaffOption? _staffById(String id) {
    for (final option in staffOptions) {
      if (option.id == id) return option;
    }
    return null;
  }

  // ── Navigation ─────────────────────────────────────────────────────────

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

  // ── Submit ─────────────────────────────────────────────────────────────

  Future<bool> submit({bool asDraft = false}) async {
    final validationError = _validateForSubmit(asDraft: asDraft);
    if (validationError != null) {
      submitError.value = validationError;
      AppSnackbar.show('Missing details', validationError);
      return false;
    }

    final uploading = evidenceFiles.any((file) => file.isUploading);
    if (uploading) {
      AppSnackbar.show(
        'Uploads in progress',
        'Wait for evidence uploads to finish before submitting.',
      );
      return false;
    }

    final failedUploads =
        evidenceFiles.where((file) => !file.isReady).toList();
    if (failedUploads.isNotEmpty) {
      AppSnackbar.show(
        'Evidence not ready',
        'Remove or re-upload failed evidence files before submitting.',
      );
      return false;
    }

    isSubmitting.value = true;
    submitError.value = '';

    final category = selectedCategory.value!;
    final client = selectedClient.value!;
    final residenceId = selectedResidenceId.value ?? session.residenceId!;
    final title = incidentTitleController.text.trim();
    final reportedAt = _reportedAtIso();
    final payload = _buildPayload();
    final supervisorNotified = selectedSupervisor.value != null;

    late final String incidentId;
    if (isEditMode) {
      final updateResult = await repository.updateIncident(
        incidentId: editIncidentId!.trim(),
        residenceId: residenceId,
        clientId: client.id,
        categoryId: category.id,
        cirTemplateId: selectedCirTemplate.value?.id,
        title: title,
        severity: severity.value.name,
        payload: payload,
        status: existingStatus.value ?? 'investigating',
        reportedAt: reportedAt,
        residentChecked: false,
        supervisorNotified: supervisorNotified,
        familyNotified: false,
        carePlanReviewed: false,
      );

      final updated = updateResult.when(
        success: (_) => true,
        failure: (error) {
          submitError.value = error.message;
          AppErrorDialog.showResultError(
            error,
            fallbackTitle: asDraft
                ? 'Could not save changes'
                : 'Could not update incident',
          );
          return false;
        },
      );
      if (!updated) {
        isSubmitting.value = false;
        return false;
      }
      incidentId = editIncidentId!.trim();
    } else {
      final createResult = await repository.createIncident(
        residenceId: residenceId,
        clientId: client.id,
        categoryId: category.id,
        cirTemplateId: selectedCirTemplate.value?.id,
        title: title,
        severity: severity.value.name,
        payload: payload,
        status: 'open',
        reportedAt: reportedAt,
        residentChecked: false,
        supervisorNotified: supervisorNotified,
        familyNotified: false,
        carePlanReviewed: false,
      );

      final createdId = createResult.when(
        success: (id) => id,
        failure: (error) {
          submitError.value = error.message;
          AppErrorDialog.showResultError(
            error,
            fallbackTitle:
                asDraft ? 'Could not save draft' : 'Could not submit incident',
          );
          return null;
        },
      );

      if (createdId == null) {
        isSubmitting.value = false;
        return false;
      }
      incidentId = createdId;
    }

    draftId.value =
        incidentId.startsWith('#') ? incidentId : '#$incidentId';

    final findings = investigationNotesController.text.trim();
    final immediate = immediateActionController.text.trim();
    if (!asDraft && (findings.isNotEmpty || immediate.isNotEmpty)) {
      final investigation = await repository.recordInvestigation(
        incidentId: incidentId,
        findings: findings.isEmpty ? immediate : findings,
        rootCause: null,
        correctiveActions: immediate.isEmpty ? null : immediate,
        status: isEditMode ? (existingStatus.value ?? 'open') : 'open',
      );
      investigation.when(
        success: (_) {},
        failure: (error) {
          AppSnackbar.show(
            isEditMode ? 'Incident updated' : 'Incident created',
            'Investigation notes could not be saved: ${error.message}',
          );
        },
      );
    }

    for (final file in evidenceFiles.where(
      (item) => item.isReady && item.localPath.trim().isNotEmpty,
    )) {
      final attached = await repository.attachEvidence(
        incidentId: incidentId,
        fileUrl: file.fileUrl!,
        fileType: file.mimeType ?? 'image/jpeg',
      );
      attached.when(
        success: (_) {},
        failure: (error) {
          AppSnackbar.show(
            'Evidence attach failed',
            '${file.fileName}: ${error.message}',
          );
        },
      );
    }

    isSubmitting.value = false;
    AppSnackbar.show(
      isEditMode
          ? (asDraft ? 'Changes saved' : 'Incident updated')
          : (asDraft ? 'Draft saved' : 'Incident submitted'),
      isEditMode
          ? 'Incident $incidentId was updated successfully.'
          : asDraft
              ? 'Incident $incidentId was created on the care home.'
              : 'Incident $incidentId was created successfully.',
    );
    return true;
  }

  String? _validateForSubmit({required bool asDraft}) {
    if (incidentTitleController.text.trim().isEmpty) {
      return 'Please enter an incident title.';
    }
    if (selectedCategory.value == null) {
      return 'Please select an incident category.';
    }
    if (selectedClient.value == null) {
      return 'Please select a client / resident.';
    }
    final residenceId = selectedResidenceId.value ?? session.residenceId;
    if (residenceId == null || residenceId.isEmpty) {
      return 'Please select a residence.';
    }
    if (!asDraft) {
      if (incidentDateController.text.trim().isEmpty ||
          incidentTimeController.text.trim().isEmpty) {
        return 'Please set the incident date and time.';
      }
      if (_reportedAtIso() == null) {
        return 'Incident date/time is invalid.';
      }
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final summaryParts = <String>[
      if (immediateActionController.text.trim().isNotEmpty)
        immediateActionController.text.trim(),
      if (investigationNotesController.text.trim().isNotEmpty)
        investigationNotesController.text.trim(),
      if (additionalNotesController.text.trim().isNotEmpty)
        additionalNotesController.text.trim(),
    ];

    return <String, dynamic>{
      'summary': summaryParts.isEmpty
          ? incidentTitleController.text.trim()
          : summaryParts.join('\n\n'),
      'location': locationController.text.trim(),
      if (detectedDuring.value != null) 'detectedDuring': detectedDuring.value,
      if (selectedInvolvedClient.value != null)
        'involvedClientId': selectedInvolvedClient.value!.id,
      if (involvedClientController.text.trim().isNotEmpty)
        'involvedClientName': involvedClientController.text.trim(),
      if (selectedStaffInvolved.value != null)
        'staffInvolvedId': selectedStaffInvolved.value!.id,
      if (staffInvolvedController.text.trim().isNotEmpty)
        'staffInvolvedName': staffInvolvedController.text.trim(),
      if (selectedReporter.value != null)
        'reportedByStaffId': selectedReporter.value!.id,
      if (reportedBy.value != null) 'reportedByName': reportedBy.value,
      if (witnesses.isNotEmpty) 'witnesses': witnesses.toList(),
      if (immediateActionController.text.trim().isNotEmpty)
        'immediateAction': immediateActionController.text.trim(),
      if (investigationNotesController.text.trim().isNotEmpty)
        'investigationNotes': investigationNotesController.text.trim(),
      'followUpRequired': followUpRequired.value,
      if (followUpDateController.text.trim().isNotEmpty)
        'followUpDate': followUpDateController.text.trim(),
      if (selectedSupervisor.value != null)
        'supervisorId': selectedSupervisor.value!.id,
      if (supervisorAssignment.value != null)
        'supervisorName': supervisorAssignment.value,
      if (additionalNotesController.text.trim().isNotEmpty)
        'additionalNotes': additionalNotesController.text.trim(),
    };
  }

  String? _reportedAtIso() {
    final date = _parseIncidentDate(incidentDateController.text);
    final time = _parseIncidentTime(incidentTimeController.text);
    if (date == null) return null;
    final hour = time?.hour ?? 0;
    final minute = time?.minute ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute)
        .toUtc()
        .toIso8601String();
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

  @override
  void onClose() {
    _clientSearchDebounceTimer?.cancel();
    _involvedClientDebounce?.cancel();
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

/// Owns its [TextEditingController] so dispose happens with the dialog route,
/// not while Flutter is still tearing down the [TextField].
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

  void _submit() => Navigator.of(context).pop(_input.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add witness',
        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _input,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Witness name',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
