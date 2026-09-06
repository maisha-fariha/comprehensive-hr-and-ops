/// Which of the 4 top-level segmented tabs on the Medication screen is
/// active. Drives which per-tab content is rendered below the shared
/// header (same page, same header — only the body swaps).
enum MedicationTab { overview, due, missed, refused }

/// Semantic status driving a dose pill's color/label in the Overview
/// "Due Today" list and the "Due" tab's schedule rows.
enum DoseStatus { due, dueSoon, upcoming, completed }

/// Which kind of item a "Missed / Refused Alerts" row represents (Overview
/// tab).
enum AlertKind { missed, refused }

/// Tag driving a stat tile's icon/color, shared by the Overview, Missed and
/// Refused tabs (mirrors the dashboard's `StatTag` pattern).
enum MedicationStatTag {
  compliance,
  dueToday,
  missedCount,
  refusedCount,
  missedToday,
  criticalMissed,
  totalRefused,
  needsFollowUp,
}

/// Color palette used for resident/staff initials avatars across every
/// Medication tab.
enum AvatarPalette { blue, green, purple }

enum SchedulePeriod { today, morning, afternoon, evening }
