import 'package:gems_core/gems_core.dart';

import '../entities/staff_search_record.dart';

/// Staff Home search: the web header "⌘K" page palette plus record lookup.
abstract class StaffSearchRepository {
  /// `GET /me` → `tenant.modules` (gates module pages like the web sidebar).
  Future<Result<StaffTenantModules>> getTenantModules();

  /// `GET /search?q=` → `{clients, documents, medications}`.
  Future<Result<List<StaffSearchRecord>>> searchRecords(String query);
}
