import 'dart:async';

import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/portal_search_hit.dart';
import '../../domain/repositories/portal_inbox_repository.dart';

/// Search controller shared by Manager (and Staff) portal search screens.
///
/// Debounces keystrokes and ignores stale responses so rapid typing cannot
/// show results for an older query.
class PortalSearchController extends BaseController<List<PortalSearchHit>> {
  final PortalInboxRepository repository;

  PortalSearchController({PortalInboxRepository? repository})
      : repository = repository ?? GetIt.instance<PortalInboxRepository>();

  static const Duration _debounceDuration = Duration(milliseconds: 350);

  final RxString query = ''.obs;

  Timer? _debounce;
  int _requestId = 0;

  List<PortalSearchHit> get hits => state.value.data ?? const [];

  /// Called from [TextField.onChanged]. Debounces the network call.
  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _invalidateInFlight();
      setLoading(false);
      setSuccess(const []);
      return;
    }

    _debounce = Timer(_debounceDuration, () => _runSearch(trimmed));
  }

  /// Called from [TextField.onSubmitted] / keyboard search. Runs immediately.
  Future<void> searchNow(String value) {
    _debounce?.cancel();
    query.value = value;
    return _runSearch(value.trim());
  }

  /// Backwards-compatible entry used by older call sites.
  Future<void> search(String value) => searchNow(value);

  Future<void> _runSearch(String trimmed) async {
    if (trimmed.isEmpty) {
      _invalidateInFlight();
      setLoading(false);
      setSuccess(const []);
      return;
    }

    final requestId = ++_requestId;
    setLoading(true);

    final result = await repository.search(trimmed);

    // A newer query (or clear) started while this request was in flight.
    if (requestId != _requestId) return;

    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void _invalidateInFlight() {
    _requestId++;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
