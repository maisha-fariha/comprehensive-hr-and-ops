class TenantInfo {
  final String subdomain;
  final String? name;
  final String? id;

  const TenantInfo({
    required this.subdomain,
    this.name,
    this.id,
  });
}
