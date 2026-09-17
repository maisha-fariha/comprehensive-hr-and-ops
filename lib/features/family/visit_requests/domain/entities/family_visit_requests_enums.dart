/// Which My Requests filter is selected: open (Pending) vs past (History).
enum FamilyVisitRequestsTab { pending, history }

/// Whether a request is for a general "Visit" or a scheduled "Appointment",
/// driving the small colored tag pill shown on every request card.
enum VisitRequestType { visit, appointment }

/// How a request will take place - shown as either a location pin + address
/// line ("In-Person at Sunrise Home") or a video icon + "Telehealth" line.
enum VisitRequestMode { inPerson, telehealth }

/// Lifecycle status of a visit/appointment request, driving the colored
/// status pill (and, on "My Requests" cards, a matching colored dot) shown
/// across every screen in this feature.
enum VisitRequestStatus { pending, approved, rejected, rescheduleRequested, completed, cancelled }
