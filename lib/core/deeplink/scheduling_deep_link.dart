/// Parsed deep link for shift scheduling (App Links + `hrcare://shifts/...`).
class SchedulingDeepLink {
  /// Tenant subdomain from the HTTPS host, e.g. `my-care` from
  /// `my-care.encoderittest.store`. Null for the apex host or custom schemes.
  final String? tenantSubdomain;

  final String shiftId;

  /// `edit` opens the shift editor (manager) / focuses the shift (staff).
  final String action;

  const SchedulingDeepLink({
    required this.shiftId,
    this.tenantSubdomain,
    this.action = 'edit',
  });

  /// Supported hosts for HTTPS App Links (multi-tenant wildcard).
  static const appLinkHostSuffix = 'encoderittest.store';

  static SchedulingDeepLink? tryParse(Uri uri) {
    if (uri.scheme == 'hrcare') {
      return _fromCustomScheme(uri);
    }
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return _fromHttps(uri);
    }
    return null;
  }

  static SchedulingDeepLink? _fromCustomScheme(Uri uri) {
    // hrcare://shifts/<id>  or  hrcare://shifts/<id>?action=edit
    if (uri.host != 'shifts') return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final pathId = segments.isEmpty ? null : segments.first;
    final shiftId = (pathId ?? uri.queryParameters['shiftId'] ?? '').trim();
    if (shiftId.isEmpty) return null;
    final action = (uri.queryParameters['action'] ?? 'edit').trim().toLowerCase();
    return SchedulingDeepLink(shiftId: shiftId, action: action);
  }

  static SchedulingDeepLink? _fromHttps(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host != appLinkHostSuffix && !host.endsWith('.$appLinkHostSuffix')) {
      return null;
    }
    final path = uri.path;
    if (!path.startsWith('/dashboard/scheduling')) return null;

    final shiftId = (uri.queryParameters['shiftId'] ?? '').trim();
    if (shiftId.isEmpty) return null;

    String? tenant;
    if (host != appLinkHostSuffix) {
      tenant = host.substring(0, host.length - appLinkHostSuffix.length - 1);
      if (tenant.isEmpty || tenant.contains('.')) {
        // e.g. www.encoderittest.store — treat as no tenant.
        tenant = null;
      }
    }

    final action =
        (uri.queryParameters['action'] ?? 'edit').trim().toLowerCase();
    return SchedulingDeepLink(
      shiftId: shiftId,
      tenantSubdomain: tenant,
      action: action,
    );
  }
}
