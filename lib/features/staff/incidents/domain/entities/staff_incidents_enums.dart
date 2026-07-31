/// Which segmented tab of the Staff Incidents list is selected.
enum StaffIncidentsTab { myIncidents, allIncidents }

/// Severity of a reported incident, driving colored dots/tags/pills across
/// the list cards, the Create Incident severity picker and the Incident
/// Details severity pill.
enum IncidentSeverity { low, medium, high, critical }

/// Lifecycle status of an incident, driving the trailing status-text link
/// on each Staff Incidents list card ("Open" / "In Review" / "Closed").
enum IncidentStatus { open, inReview, closed }

/// Which icon glyph an incident card's leading icon uses - a warning
/// triangle for physical/behavioral incidents (Fall, Verbal Aggression) or
/// an info circle for care-related incidents (Medication Refusal). The
/// icon's *color* instead tracks the incident's [IncidentSeverity], per the
/// Figma screenshots (see `StaffIncidentTypeIcon`).
enum StaffIncidentIconKind { warning, info }
