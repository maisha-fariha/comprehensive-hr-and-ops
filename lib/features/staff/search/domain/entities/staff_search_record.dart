import 'package:flutter/foundation.dart';

/// Record groups returned by `GET /search?q=`.
enum StaffSearchRecordType { client, document, medication }

@immutable
class StaffSearchRecord {
  final String id;
  final StaffSearchRecordType type;
  final String title;
  final String subtitle;

  const StaffSearchRecord({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
  });
}

/// Tenant feature modules from `GET /me` → `tenant.modules`.
///
/// [known] is false when `/me` could not be read; module-gated pages then stay
/// visible and the API enforces access.
@immutable
class StaffTenantModules {
  final Map<String, bool> flags;
  final bool known;

  const StaffTenantModules(this.flags) : known = true;

  const StaffTenantModules.unknown()
      : flags = const {},
        known = false;

  bool has(String module) {
    if (!known) return true;
    return flags['legacy_unlimited'] == true || flags[module] == true;
  }
}
