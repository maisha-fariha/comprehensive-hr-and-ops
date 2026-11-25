/// Live Harmony Help permission catalog and web nav map.
///
/// Source: `GET /roles` on harmony-help (tenant_admin holds all **114** keys).
/// Web sidebar: `tenantNavItems` in the dashboard shell bundle.
///
/// Drive menus and actions off [UserSession.can] / these keys — never off
/// role names. Resource-only checks like `can('clients')` still match
/// `clients:read` / `clients:write` via [UserSession.can].
abstract final class AppPermissions {
  AppPermissions._();

  /// Full catalog (114). Keep sorted; used for audits and docs.
  static const List<String> catalog = [
    'admissions:read',
    'admissions:update',
    'admissions:write',
    'appointments:export',
    'appointments:read',
    'appointments:write',
    'attendance:manage',
    'attendance:read',
    'attendance:write',
    'billing:manage',
    'billing:read',
    'care-flags:read',
    'care-flags:resolve',
    'client-activities:read',
    'client-activities:write',
    'clients:create',
    'clients:delete',
    'clients:export',
    'clients:read',
    'clients:update',
    'clients:write',
    'compliance:export',
    'compliance:read',
    'compliance:write',
    'daily-logs:read',
    'daily-logs:review',
    'daily-logs:write',
    'dashboard:read',
    'documents:export',
    'documents:read',
    'documents:write',
    'emergency:raise',
    'emergency:read',
    'emergency:respond',
    'family:read',
    'family:write',
    'finance:read',
    'finance:write',
    'incidents:export',
    'incidents:read',
    'incidents:write',
    'inventory:adjustment',
    'inventory:movement',
    'inventory:read',
    'inventory:transfer:approve',
    'inventory:transfer:dispatch',
    'inventory:transfer:receive',
    'inventory:transfer:request',
    'inventory:waste',
    'inventory:write',
    'mar:export',
    'mar:manage',
    'mar:read',
    'mar:write',
    'messaging:monitor',
    'messaging:read',
    'messaging:write',
    'notifications:read',
    'notifications:write',
    'payroll:export',
    'payroll:read',
    'payroll:write',
    'permissions:read',
    'purchase-orders:approve',
    'purchase-orders:read',
    'purchase-orders:receive',
    'purchase-orders:write',
    'recurring-checks:complete',
    'recurring-checks:manage',
    'recurring-checks:read',
    'recurring-checks:write',
    'reports:read',
    'reports:write',
    'residences:create',
    'residences:delete',
    'residences:export',
    'residences:read',
    'residences:update',
    'roles:read',
    'roles:write',
    'scheduling:bid',
    'scheduling:read',
    'scheduling:write',
    'settings:read',
    'settings:write',
    'shift-handovers:read',
    'shift-handovers:write',
    'staff-categories:read',
    'staff-categories:write',
    'staff:create',
    'staff:directory',
    'staff:pii:read',
    'staff:pii:write',
    'staff:read',
    'staff:update',
    'staff:write',
    'suppliers:read',
    'suppliers:write',
    'tasks:manage',
    'tasks:read',
    'tasks:review',
    'tasks:write',
    'tickets:create',
    'tickets:reply',
    'tickets:view_own',
    'tickets:view_tenant',
    'training:manage',
    'training:oversee',
    'training:read',
    'training:write',
    'uploads:read',
    'uploads:write',
    'users:read',
    'users:write',
  ];

  /// Web `tenantNavItems` — any listed permission grants the item.
  static const List<WebNavItem> tenantNav = [
    WebNavItem('Dashboard', ['dashboard:read']),
    WebNavItem('Users & Access', ['users:read', 'roles:read']),
    WebNavItem('Residences', ['residences:read']),
    WebNavItem('Clients', ['clients:read']),
    WebNavItem('Scheduling', ['scheduling:read'], module: 'scheduling'),
    WebNavItem('Attendance', ['attendance:read'], module: 'attendance'),
    WebNavItem('Handovers', ['shift-handovers:read'], module: 'scheduling'),
    WebNavItem(
      'Recurring Checks',
      ['recurring-checks:read'],
      module: 'scheduling',
    ),
    WebNavItem('Task Management', ['tasks:read']),
    WebNavItem('Daily Logs', ['daily-logs:read']),
    WebNavItem('Emergency', ['emergency:read']),
    WebNavItem('Incidents', ['incidents:read'], module: 'incidents'),
    WebNavItem('Medication MAR', ['mar:read'], module: 'mar'),
    WebNavItem('Inventory', ['inventory:read'], module: 'inventory'),
    WebNavItem('Reports & Analytics', ['reports:read'], module: 'reports'),
    WebNavItem('AI Alerts & Insights', ['dashboard:read', 'notifications:read']),
    WebNavItem('Compliance & Audit', ['compliance:read'], module: 'compliance'),
    WebNavItem('Finance & Payroll', ['payroll:read', 'finance:read'],
        module: 'payroll'),
    WebNavItem('Documents Management', ['documents:read'], module: 'documents'),
    WebNavItem('Appointments', ['appointments:read'], module: 'appointments'),
    WebNavItem('Training', ['training:read'], module: 'training'),
    WebNavItem('Support & Tickets', ['tickets:view_own', 'tickets:view_tenant']),
    WebNavItem('Communication', ['messaging:read'], module: 'messaging'),
    WebNavItem('Settings', ['settings:read']),
  ];

  /// `GET /residences` requires this. Pickers still work from session /
  /// roster / open-record context when it is missing (web clock-in pattern).
  static const String residencesRead = 'residences:read';

  /// Web Permissions modal group title (`admissions:read` → `Admissions`).
  static String groupLabel(String permission) {
    final family = permission.contains(':')
        ? permission.split(':').first
        : permission;
    return family
        .split('-')
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  /// Web Permissions modal row title
  /// (`admissions:read` → `Read admissions`, code chip `Admissions Read`).
  static String actionLabel(String permission) {
    if (!permission.contains(':')) return groupLabel(permission);
    final parts = permission.split(':');
    final family = groupLabel(parts.first).toLowerCase();
    final action = parts.sublist(1).join(' ');
    final pretty = action
        .split(RegExp(r'[-_]'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
    return '$pretty $family';
  }

  /// Compact code chip under the row (`Admissions Read`).
  static String codeLabel(String permission) {
    return permission
        .split(RegExp(r'[:\-_]'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  /// Catalog grouped like the web Permissions modal (family → keys).
  static Map<String, List<String>> get catalogByGroup {
    final map = <String, List<String>>{};
    for (final key in catalog) {
      map.putIfAbsent(groupLabel(key), () => <String>[]).add(key);
    }
    return map;
  }
}

class WebNavItem {
  final String label;
  final List<String> permissions;
  final String? module;

  const WebNavItem(this.label, this.permissions, {this.module});
}

/// Merges API residence rows with session / contextual homes so pickers
/// stay usable without [AppPermissions.residencesRead].
List<T> mergeResidencePickerOptions<T>({
  required Iterable<T> loaded,
  required String Function(T) idOf,
  required String Function(T) nameOf,
  required T Function(String id, String name) create,
  String? sessionId,
  String? sessionName,
  String? contextId,
  String? contextName,
}) {
  final byId = <String, T>{
    for (final row in loaded)
      if (idOf(row).isNotEmpty) idOf(row): row,
  };

  void put(String? id, String? name) {
    if (id == null || id.isEmpty) return;
    final label = (name ?? '').trim();
    byId.putIfAbsent(
      id,
      () => create(id, label.isEmpty ? 'Residence' : label),
    );
  }

  put(contextId, contextName);
  put(sessionId, sessionName);
  return byId.values.toList();
}
