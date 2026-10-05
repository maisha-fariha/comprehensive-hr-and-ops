/// Which tab of the Family Visits & Appointments list is selected - the web
/// Family Portal's "Upcoming Visits" / "Past Visits" split.
enum FamilyAppointmentsTab { upcoming, past }

/// Lifecycle status of an appointment/visit as returned by
/// `GET /family/appointments` (`pending | approved | rejected | cancelled |
/// completed`, plus the web-recognised `confirmed`/`declined`/`rescheduled`
/// aliases). Anything else is [other] and is never shown as Pending.
enum FamilyAppointmentStatus {
  pending,
  approved,
  rescheduleRequested,
  completed,
  rejected,
  cancelled,
  other,
}

/// Which kind of appointment a card represents, driving the leading icon
/// glyph and (for non-completed cards) the icon box's tint - see
/// `FamilyAppointmentIconStyle`. Completed cards always render with a
/// single muted style regardless of this value, per the Figma "Completed -
/// Appointments" screenshot.
enum FamilyAppointmentIconKind { medical, dental, physiotherapy, familyVisit }

/// Which "Request Type" segment is active on the Create Appointment form -
/// drives the page title, field labels/values and info-banner copy.
enum AppointmentRequestType { visit, appointment }
