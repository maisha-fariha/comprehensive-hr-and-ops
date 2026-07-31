import 'package:gems_core/gems_core.dart';

import '../entities/medication_overview.dart';

/// Contract for fetching the Medication MAR (Medication Administration
/// Record) summary. The presentation layer only ever depends on this
/// interface, so swapping the mocked [MedicationRepositoryImpl] for a real
/// API-backed implementation later requires no changes above the data
/// layer.
abstract class MedicationRepository {
  Future<Result<MedicationOverview>> getOverview();
}
