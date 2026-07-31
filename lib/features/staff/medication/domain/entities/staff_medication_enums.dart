/// Which of the 4 top-level segmented tabs on the Staff "Medication MAR"
/// screen is active. Drives which per-tab content is rendered below the
/// shared header (same page, same header — only the body swaps).
enum StaffMedicationTab { due, administered, missed, refused }

/// Color palette used for resident/staff initials avatars across every
/// Staff Medication tab.
enum AvatarPalette { blue, green, amber, purple, red }

/// The medication form + administration route shown as a dose card's
/// subtitle, e.g. "Tablet · Oral".
enum MedicationRoute { tabletOral, capsuleOral, injectionSubcut }

/// Which section of the "Due" tab a dose belongs to: the immediately-due
/// "Due Now" list or the "Later Today" list.
enum DueDoseSection { dueNow, laterToday }

/// The local (mock, in-memory only) action state of a "Due" tab dose card.
/// [pending] shows the "Administer"/"Not Given" button row; [administered]
/// and [notGiven] reflect a staff member's tap on those buttons; [upcoming]
/// is used for doses further out in the day that aren't actionable yet and
/// render with muted styling and no buttons.
enum DueDoseStatus { pending, administered, notGiven, upcoming }
