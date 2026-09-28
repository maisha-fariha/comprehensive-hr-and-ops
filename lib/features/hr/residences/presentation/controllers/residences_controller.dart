import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/residence_summary.dart';
import '../../domain/repositories/residences_repository.dart';

class ResidencesController extends BaseController<List<ResidenceSummary>> {
  final ResidencesRepository repository;

  final RxString query = ''.obs;

  /// `null` means "All statuses" / "All types".
  final RxnString statusFilter = RxnString();
  final RxnString typeFilter = RxnString();

  int _loadGeneration = 0;

  ResidencesController({required this.repository}) {
    loadResidences();
  }

  List<ResidenceSummary> get residences => state.value.data ?? const [];

  List<String> get statuses =>
      residences.map((r) => r.status).toSet().toList()..sort();

  List<String> get types => residences
      .map((r) => r.residenceType)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort();

  List<ResidenceSummary> get filtered {
    final q = query.value.trim().toLowerCase();
    return residences.where((r) {
      if (statusFilter.value != null && r.status != statusFilter.value) {
        return false;
      }
      if (typeFilter.value != null && r.residenceType != typeFilter.value) {
        return false;
      }
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          (r.address?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  int get totalResidents => residences.fold(0, (sum, r) => sum + r.residents);

  int get totalBedsFree => residences.fold(0, (sum, r) => sum + r.bedsFree);

  int get atCapacityCount => residences.where((r) => r.atCapacity).length;

  Future<void> loadResidences() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getResidences();
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<List<ResidenceRoom>?> loadRooms(String residenceId) async {
    final result = await repository.getRooms(residenceId);
    return result.when(success: (rooms) => rooms, failure: (_) => null);
  }

  @override
  Future<void> refresh() => loadResidences();
}
