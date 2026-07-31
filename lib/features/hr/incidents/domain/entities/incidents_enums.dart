/// Which tab of the Incidents list is selected.
enum IncidentsTab { open, underReview, closed }

/// Severity of an open incident, driving the trailing severity pill color.
/// `low` only appears as a selectable option in the "Create Incident"
/// wizard's severity selector - no list card in the source screenshots
/// uses it.
enum IncidentSeverity { low, medium, high, critical }

/// Which icon/color treatment an incident card's leading avatar uses. Kept
/// as a semantic enum (rather than a raw asset string) so the presentation
/// layer owns the icon-to-asset mapping, same as `AttentionAlert.severity`
/// does on the Dashboard.
enum IncidentIconKind { heart, bandage, home, flame }

/// Semantic tag for a summary stat tile shown at the top of every Incidents
/// tab (mirrors `StatTag` from the Dashboard feature).
enum IncidentStatTag {
  openIncidents,
  criticalCases,
  pendingReview,
  underReview,
  assignedInvestigators,
  pendingActions,
  resolvedToday,
  thisWeek,
  archived,
}

/// Which step of the "Create Incident" wizard is active.
enum IncidentCreationStep { details, people, investigate, evidence }
