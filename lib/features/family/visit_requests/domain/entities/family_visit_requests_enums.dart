/// Status tab selected on the Visit Requests list. [all] shows every
/// request; the others list exactly the requests with that API status
/// (labels as on the web register: Pending / Approved / Rejected /
/// Cancelled / Completed).
enum FamilyVisitRequestsTab { all, pending, approved, rejected, cancelled, completed }

/// Whether a request is for a general "Visit" or a scheduled "Appointment",
/// driving the small colored tag pill shown on every request card.
enum VisitRequestType { visit, appointment }

/// How a request will take place - shown as either a location pin + address
/// line ("In-Person at Sunrise Home") or a video icon + "Telehealth" line.
enum VisitRequestMode { inPerson, telehealth }

/// Lifecycle status of a visit/appointment request, driving the colored
/// status pill (and, on "My Requests" cards, a matching colored dot) shown
/// across every screen in this feature. Unrecognised API values map to
/// [other], never to [pending].
enum VisitRequestStatus { pending, approved, rejected, rescheduleRequested, completed, cancelled, other }
