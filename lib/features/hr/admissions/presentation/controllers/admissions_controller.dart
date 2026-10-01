import 'dart:async';

import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/referral.dart';
import '../../domain/repositories/admissions_repository.dart';
import '../admissions_labels.dart';

enum AdmissionsTab { referrals, forms }

/// Web `/dashboard/admissions`: the referral pipeline board, its KPI tiles,
/// the "Intake forms" tab and every referral / form mutation.
class AdmissionsController extends GetxController {
  final AdmissionsRepository repository;
  final UserSession session;

  AdmissionsController({required this.repository, required this.session});

  static const List<int> pageSizes = [10, 20, 25, 50];
  static const int defaultLimit = 20;
  static const Duration searchDebounce = Duration(milliseconds: 300);

  final Rx<AdmissionsTab> tab = AdmissionsTab.referrals.obs;

  final RxList<Referral> referrals = <Referral>[].obs;
  final RxInt total = 0.obs;
  final RxInt pageCount = 1.obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();

  final RxString search = ''.obs;

  /// `null` is "Any stage".
  final RxnString status = RxnString();
  final RxInt page = 1.obs;
  final RxInt limit = defaultLimit.obs;

  final Rxn<ReferralBoard> board = Rxn<ReferralBoard>();
  final RxList<AdmissionOption> residences = <AdmissionOption>[].obs;

  final RxList<IntakeTemplate> templates = <IntakeTemplate>[].obs;
  final RxBool templatesLoading = false.obs;
  final RxnString templatesError = RxnString();
  bool _templatesLoaded = false;

  final RxnString busyId = RxnString();

  int _serial = 0;
  Timer? _debounce;

  bool get canRead => session.can('admissions:read');
  bool get canWrite =>
      session.can('admissions:update') || session.can('admissions:write');

  /// Admitting creates a resident record.
  bool get canAdmit =>
      session.can('clients:create') || session.can('clients:write');
  bool get canReadResidences => session.can('residences:read');

  int get totalPages => pageCount.value < 1 ? 1 : pageCount.value;

  String? residenceName(String? id) =>
      id == null ? null : residences.where((r) => r.id == id).firstOrNull?.label;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
    loadResidences();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> refreshAll() => Future.wait([
        load(),
        loadBoard(),
        if (_templatesLoaded || tab.value == AdmissionsTab.forms) loadTemplates(),
      ]);

  Future<void> load() async {
    if (!canRead) {
      loading.value = false;
      return;
    }
    final serial = ++_serial;
    loading.value = true;
    final query = search.value.trim();
    final result = await repository.referrals(
      page: page.value,
      limit: limit.value,
      search: query.isEmpty ? null : query,
      status: status.value,
    );
    if (serial != _serial) return;
    result.when(
      success: (data) {
        referrals.assignAll(data.items);
        total.value = data.total;
        pageCount.value = data.totalPages;
        loadError.value = null;
      },
      failure: (error) {
        referrals.clear();
        total.value = 0;
        pageCount.value = 1;
        loadError.value = AdmissionsLabels.error(error);
      },
    );
    loading.value = false;
  }

  Future<void> loadBoard() async {
    if (!canRead) return;
    final result = await repository.board();
    result.when(success: (b) => board.value = b, failure: (_) {});
  }

  Future<void> loadResidences() async {
    if (!canReadResidences) return;
    final result = await repository.residences();
    result.when(success: residences.assignAll, failure: (_) {});
  }

  Future<void> loadTemplates() async {
    if (!canRead) return;
    _templatesLoaded = true;
    templatesLoading.value = true;
    final result = await repository.templates();
    result.when(
      success: (list) {
        templates.assignAll(list);
        templatesError.value = null;
      },
      failure: (error) {
        templates.clear();
        templatesError.value = AdmissionsLabels.error(error);
      },
    );
    templatesLoading.value = false;
  }

  void setTab(AdmissionsTab value) {
    tab.value = value;
    if (value == AdmissionsTab.forms && !_templatesLoaded) loadTemplates();
  }

  void setSearch(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      page.value = 1;
      load();
    });
  }

  void setStatus(String? value) {
    status.value = value;
    page.value = 1;
    load();
  }

  void setPage(int value) {
    page.value = value;
    load();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    load();
  }

  /// Returns the error message, or null on success. Success toasts and
  /// refreshes every admissions list like the web query invalidation.
  Future<String?> _run(
    String id,
    Future<Result<void>> Function() action,
    String? success, {
    bool toastErrors = false,
  }) async {
    busyId.value = id;
    final result = await action();
    busyId.value = null;
    return result.when(
      success: (_) {
        if (success != null) AppSnackbar.show(success, '');
        refreshAll();
        return null;
      },
      failure: (error) {
        final message = AdmissionsLabels.error(error);
        if (toastErrors) AppSnackbar.show('Something went wrong', message);
        return message;
      },
    );
  }

  Future<String?> createReferral(Map<String, dynamic> body) => _run(
        'new',
        () => repository.createReferral(body),
        'Referral recorded',
      );

  Future<String?> updateReferral(String id, Map<String, dynamic> body) => _run(
        id,
        () => repository.updateReferral(id, body),
        'Referral updated',
      );

  Future<String?> moveStage(String id, String stage) => _run(
        id,
        () => repository.updateReferral(id, {'status': stage}),
        'Stage updated',
      );

  Future<String?> setChecklist(String id, List<String> completed) => _run(
        id,
        () => repository.setChecklist(id, completed),
        null,
        toastErrors: true,
      );

  Future<String?> setContacts(String id, List<Map<String, dynamic>> contacts) =>
      _run(
        id,
        () => repository.setContacts(id, contacts),
        'Contacts saved',
      );

  Future<String?> addAssessment(
    String id, {
    required String summary,
    String? outcome,
  }) =>
      _run(
        id,
        () => repository.addAssessment(id, summary: summary, outcome: outcome),
        'Assessment recorded',
      );

  Future<String?> admit(
    String id, {
    required String residenceId,
    String? roomId,
    String? level,
  }) =>
      _run(
        id,
        () => repository.admit(
          id,
          residenceId: residenceId,
          roomId: roomId,
          level: level,
        ),
        'Admitted — the resident record has been created',
      );

  Future<String?> decline(String id, String reason) => _run(
        id,
        () => repository.decline(id, reason),
        'Referral declined',
      );

  Future<String?> deleteReferral(Referral referral) => _run(
        referral.id,
        () => repository.deleteReferral(referral.id),
        'Referral deleted',
        toastErrors: true,
      );

  Future<String?> createTemplate(Map<String, dynamic> body) => _run(
        'new-template',
        () => repository.createTemplate(body),
        'Intake form created',
      );

  Future<String?> updateTemplate(String id, Map<String, dynamic> body) => _run(
        id,
        () => repository.updateTemplate(id, body),
        'Intake form updated',
      );

  Future<String?> retireTemplate(IntakeTemplate template) => _run(
        template.id,
        () => repository.updateTemplate(template.id, {'isActive': false}),
        'Form retired',
        toastErrors: true,
      );

  Future<String?> reinstateTemplate(IntakeTemplate template) => _run(
        template.id,
        () => repository.updateTemplate(template.id, {'isActive': true}),
        'Form back in use',
        toastErrors: true,
      );
}
