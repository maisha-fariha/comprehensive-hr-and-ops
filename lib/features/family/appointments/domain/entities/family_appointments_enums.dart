/// Which segmented tab of the Family Appointments list is selected.
enum FamilyAppointmentsTab { all, upcoming, completed }

/// Lifecycle status of an appointment/visit, driving each list card's
/// trailing status pill color (see `FamilyAppointmentStatusStyle`).
enum FamilyAppointmentStatus { upcoming, pending, approved, completed }

/// Which kind of appointment a card represents, driving the leading icon
/// glyph and (for non-completed cards) the icon box's tint - see
/// `FamilyAppointmentIconStyle`. Completed cards always render with a
/// single muted style regardless of this value, per the Figma "Completed -
/// Appointments" screenshot.
enum FamilyAppointmentIconKind { medical, dental, physiotherapy, familyVisit }

/// Which "Request Type" segment is active on the Create Appointment form -
/// drives the page title, field labels/values and info-banner copy.
enum AppointmentRequestType { visit, appointment }
