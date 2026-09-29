/// Web MAR console tabs: MAR · PRN · Given · Resident chart.
enum StaffMedicationTab { mar, prn, given, residentChart }

/// Color palette used for resident/staff initials avatars across every
/// Staff Medication tab.
enum AvatarPalette { blue, green, amber, purple, red }

/// The medication form + administration route shown as a dose card's
/// subtitle, e.g. "Tablet · Oral".
enum MedicationRoute { tabletOral, capsuleOral, injectionSubcut }

/// Which section of the MAR (scheduled) tab a dose belongs to:
/// immediately due vs later today.
enum DueDoseSection { dueNow, laterToday }

/// Local action state of a scheduled MAR dose card.
enum DueDoseStatus { pending, administered, notGiven, upcoming }
