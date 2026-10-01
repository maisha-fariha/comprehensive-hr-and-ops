import 'dart:async';

import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_search_record.dart';
import '../../domain/repositories/staff_search_repository.dart';
import '../staff_search_destinations.dart';

/// Staff Home search: web header palette ("Search pages...") over the pages
/// this user may open, plus `/search` record hits they may read.
class StaffSearchController extends GetxController {
  final StaffSearchRepository repository;
  final UserSession session;
  final List<StaffSearchDestination> _destinations;

  StaffSearchController({
    StaffSearchRepository? repository,
    UserSession? session,
    List<StaffSearchDestination>? destinations,
  })  : repository = repository ?? GetIt.instance<StaffSearchRepository>(),
        session = session ?? Get.find<UserSession>(),
        _destinations = destinations ?? staffSearchDestinations();

  static const Duration debounceDuration = Duration(milliseconds: 350);

  final RxString query = ''.obs;
  final Rx<StaffTenantModules> modules =
      const StaffTenantModules.unknown().obs;
  final RxList<StaffSearchRecord> records = <StaffSearchRecord>[].obs;
  final RxBool recordsLoading = false.obs;
  final RxString recordsError = ''.obs;

  Timer? _debounce;
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final result = await repository.getTenantModules();
    result.when(
      success: (value) => modules.value = value,
      failure: (_) {},
    );
  }

  /// Web `useVisibleNavItems`: module enabled and any listed permission held.
  List<StaffSearchDestination> get visibleDestinations => _destinations
      .where((d) => d.module == null || modules.value.has(d.module!))
      .where((d) => d.permissions.isEmpty || d.permissions.any(session.can))
      .toList();

  List<StaffSearchDestination> get matchingDestinations {
    final q = query.value.trim().toLowerCase();
    final visible = visibleDestinations;
    if (q.isEmpty) return visible;
    final scored = <(int, int, StaffSearchDestination)>[];
    for (var i = 0; i < visible.length; i++) {
      final score = _score(visible[i].label.toLowerCase(), q);
      if (score > 0) scored.add((score, i, visible[i]));
    }
    scored.sort((a, b) {
      final byScore = b.$1.compareTo(a.$1);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    });
    return [for (final entry in scored) entry.$3];
  }

  bool _canReadRecords(StaffSearchRecordType type) =>
      session.can(staffSearchRecordPermission(type));

  bool get canSearchRecords =>
      StaffSearchRecordType.values.any(_canReadRecords);

  List<StaffSearchRecord> recordsOf(StaffSearchRecordType type) {
    if (!_canReadRecords(type)) return const [];
    return records.where((r) => r.type == type).toList();
  }

  bool get hasAnyResult =>
      matchingDestinations.isNotEmpty ||
      StaffSearchRecordType.values.any((t) => recordsOf(t).isNotEmpty);

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty || !canSearchRecords) {
      _requestId++;
      records.clear();
      recordsLoading.value = false;
      recordsError.value = '';
      return;
    }
    _debounce = Timer(debounceDuration, () => _searchRecords(trimmed));
  }

  Future<void> _searchRecords(String trimmed) async {
    final requestId = ++_requestId;
    recordsLoading.value = true;
    recordsError.value = '';
    final result = await repository.searchRecords(trimmed);
    if (requestId != _requestId) return;
    result.when(
      success: records.assignAll,
      failure: (error) {
        records.clear();
        recordsError.value = error.message;
      },
    );
    recordsLoading.value = false;
  }

  /// cmdk-style match: query characters in order; contiguous and word-start
  /// matches rank higher. 0 = no match.
  static int _score(String label, String q) {
    if (label.startsWith(q)) return 4;
    if (label.split(RegExp(r'[\s&]+')).any((w) => w.startsWith(q))) return 3;
    if (label.contains(q)) return 2;
    var index = 0;
    for (final char in q.split('')) {
      if (char == ' ') continue;
      index = label.indexOf(char, index);
      if (index < 0) return 0;
      index++;
    }
    return 1;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
