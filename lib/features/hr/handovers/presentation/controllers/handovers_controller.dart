import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/handover_options.dart';
import '../../domain/entities/shift_handover.dart';
import '../../domain/repositories/handovers_repository.dart';

/// Web `/dashboard/handovers`: status / person / date / residence filters,
/// the handover cards and their submit, take and delete actions.
class HandoversController extends GetxController {
  final HandoversRepository repository;
  final UserSession session;

  HandoversController({required this.repository, required this.session});

  final RxList<ShiftHandover> handovers = <ShiftHandover>[].obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();

  final RxnString status = RxnString();
  final RxnString staffId = RxnString();
  final RxnString residenceId = RxnString();
  final Rxn<DateTime> from = Rxn<DateTime>();
  final Rxn<DateTime> to = Rxn<DateTime>();

  final RxList<HandoverOption> residences = <HandoverOption>[].obs;
  final RxList<HandoverOption> staff = <HandoverOption>[].obs;
  final RxnString busyId = RxnString();

  int _serial = 0;

  bool get canWrite => session.can('shift-handovers:write');
  String? get myUserId => session.userId;

  /// Shifts the caller already handed over, left out of the record form.
  Set<String> get myHandedOverShiftIds => {
        for (final h in handovers)
          if (h.createdBy == myUserId && h.fromShiftId != null) h.fromShiftId!,
      };

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
    load();
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.list(
      status: status.value,
      staffId: staffId.value,
      residenceId: residenceId.value,
      from: from.value == null ? null : _day(from.value!),
      to: to.value == null ? null : _day(to.value!),
    );
    if (serial != _serial) return;
    result.when(
      success: (items) {
        handovers.assignAll(items);
        loadError.value = null;
      },
      failure: (error) {
        handovers.clear();
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> _loadOptions() async {
    final residenceResult = await repository.residences();
    residenceResult.when(success: residences.assignAll, failure: (_) {});
    if (session.can('staff:read')) {
      final staffResult = await repository.staff();
      staffResult.when(success: staff.assignAll, failure: (_) {});
    }
  }

  void setStatus(String? value) {
    status.value = value;
    load();
  }

  void setStaff(String? value) {
    staffId.value = value;
    load();
  }

  void setResidence(String? value) {
    residenceId.value = value;
    load();
  }

  void setFrom(DateTime? value) {
    from.value = value;
    load();
  }

  void setTo(DateTime? value) {
    to.value = value;
    load();
  }

  bool canSubmit(ShiftHandover h) =>
      h.status == 'draft' && h.createdBy == myUserId;

  bool canTake(ShiftHandover h) =>
      h.status != 'draft' &&
      h.needsAcknowledgement &&
      h.createdBy != myUserId &&
      !h.acknowledgedBy(myUserId);

  /// The detail's "I've read and taken this" is hidden once taken, when
  /// nothing needs taking, or for the author.
  bool alreadyTaken(ShiftHandover h) =>
      h.acknowledgedBy(myUserId) ||
      !h.needsAcknowledgement ||
      h.createdBy == myUserId;

  Future<bool> _run(
    String id,
    Future<Result<void>> Function() action,
    String success,
  ) async {
    busyId.value = id;
    final result = await action();
    busyId.value = null;
    return result.when(
      success: (_) {
        AppSnackbar.show(success, '');
        load();
        return true;
      },
      failure: (error) {
        AppSnackbar.show('Something went wrong', error.message);
        return false;
      },
    );
  }

  Future<bool> submit(ShiftHandover h) =>
      _run(h.id, () => repository.setStatus(h.id, 'submitted'), 'Handover submitted');

  Future<bool> take(ShiftHandover h, {String? note}) => _run(
        h.id,
        () => repository.acknowledge(h.id, note: note),
        'Marked as taken',
      );

  Future<bool> addNote(ShiftHandover h, String body) =>
      _run(h.id, () => repository.comment(h.id, body), 'Note added');

  Future<bool> delete(ShiftHandover h) =>
      _run(h.id, () => repository.delete(h.id), 'Handover deleted');
}
