class FamilyLinkedClient {
  final String id;
  final String initials;
  final String name;

  /// "Residence · Room number" subtext line.
  final String subtitle;
  final String statusLabel;

  const FamilyLinkedClient({
    this.id = '',
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.statusLabel,
  });
}
