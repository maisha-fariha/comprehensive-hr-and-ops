import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/stock_ops.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_action.dart';

/// Web `/dashboard/inventory/counts` ("Stock counts").
class StockCountsController extends GetxController {
  final InventoryRepository repository;
  final UserSession session;

  StockCountsController({required this.repository, required this.session});

  static const List<int> pageSizes = [10, 20, 25, 50];

  final RxList<StockCount> counts = <StockCount>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();
  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;

  final RxList<InventoryOption> residences = <InventoryOption>[].obs;
  final RxList<InventoryOption> categories = <InventoryOption>[].obs;

  int _serial = 0;

  bool get canAdjust => session.can('inventory:adjustment');

  int get totalPages =>
      total.value == 0 ? 1 : ((total.value + limit.value - 1) ~/ limit.value);

  @override
  void onInit() {
    super.onInit();
    load();
    loadOptions();
  }

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.stockCounts(page: page.value, limit: limit.value);
    if (serial != _serial) return;
    result.when(
      success: (data) {
        counts.assignAll(data.items);
        total.value = data.total;
        loadError.value = null;
      },
      failure: (error) {
        counts.clear();
        total.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadOptions() async {
    if (session.can('residences:read')) {
      (await repository.residences()).when(success: residences.assignAll, failure: (_) {});
    }
    (await repository.categories()).when(
      success: (rows) => categories.assignAll([
        for (final c in rows)
          if (c.isActive) InventoryOption(value: c.id, label: c.name),
      ]),
      failure: (_) {},
    );
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

  Future<Result<StockCount>> count(String id) => repository.stockCount(id);

  /// Returns the count to open, or the error message as a failure.
  Future<Result<String>> open({required String residenceId, String? categoryId}) async {
    final result = await repository.openStockCount(
      residenceId: residenceId,
      categoryId: categoryId,
    );
    return result.when(
      success: (opened) {
        if (opened.alreadyOpen) {
          AppSnackbar.show('A count was already open for these shelves — opened it.', '');
        } else {
          AppSnackbar.show('Count opened', '');
        }
        load();
        return Result.success(opened.id);
      },
      failure: Result.failure,
    );
  }

  Future<String?> saveLines(String countId, List<Map<String, dynamic>> lines) =>
      runInventoryAction(
        () => repository.saveCountLines(countId, lines),
        success: 'Counts saved',
        onSuccess: load,
      );

  Future<String?> submit(String countId) => runInventoryAction(
        () => repository.submitCount(countId),
        success: 'Count submitted — stock updated',
        onSuccess: load,
      );

  Future<String?> cancel(StockCount count) =>
      runInventoryAction(() => repository.cancelCount(count.id), onSuccess: load);
}
