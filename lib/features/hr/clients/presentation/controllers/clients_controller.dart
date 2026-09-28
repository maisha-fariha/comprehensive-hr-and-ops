import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/client_summary.dart';
import '../../domain/repositories/clients_repository.dart';

class ClientsController extends BaseController<List<ClientSummary>> {
  final ClientsRepository repository;

  final RxString query = ''.obs;

  /// `null` means "All residences".
  final RxnString residenceFilter = RxnString();

  /// `null` means every status.
  final RxnString statusFilter = RxnString();

  final RxMap<String, String> residenceNames = <String, String>{}.obs;

  int _loadGeneration = 0;

  ClientsController({required this.repository}) {
    loadClients();
    _loadResidenceNames();
  }

  List<ClientSummary> get clients => state.value.data ?? const [];

  /// Residence ids available in the filter, from `/residences` plus any
  /// residence referenced by a client.
  List<String> get residenceOptions {
    final ids = <String>{
      ...residenceNames.keys,
      ...clients.map((c) => c.residenceId).whereType<String>(),
    }.toList();
    ids.sort((a, b) => residenceLabel(a).compareTo(residenceLabel(b)));
    return ids;
  }

  List<String> get statuses =>
      clients.map((c) => c.status).toSet().toList()..sort();

  String residenceLabel(String id) {
    final known = residenceNames[id];
    if (known != null) return known;
    for (final c in clients) {
      if (c.residenceId == id && c.residenceName != null) {
        return c.residenceName!;
      }
    }
    return 'Unknown residence';
  }

  List<ClientSummary> get filtered {
    final q = query.value.trim().toLowerCase();
    return clients.where((c) {
      if (residenceFilter.value != null &&
          c.residenceId != residenceFilter.value) {
        return false;
      }
      if (statusFilter.value != null && c.status != statusFilter.value) {
        return false;
      }
      if (q.isEmpty) return true;
      return c.fullName.toLowerCase().contains(q) ||
          c.id.toLowerCase().contains(q) ||
          c.shortId.toLowerCase().contains(q) ||
          (c.room?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> loadClients() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getClients();
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> _loadResidenceNames() async {
    final result = await repository.getResidenceNames();
    result.when(success: residenceNames.assignAll, failure: (_) {});
  }

  Future<ClientSummary?> loadClient(String id) async {
    final result = await repository.getClient(id);
    return result.when(success: (client) => client, failure: (_) => null);
  }

  @override
  Future<void> refresh() => loadClients();
}
