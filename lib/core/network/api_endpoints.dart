/// Mobile API paths relative to `{tenant_base_url}/api/v1`.
///
/// Verified against the Part A (Residence Manager) screen → API map.
/// Staff (Part B) and Family (Part C) paths will be added alongside those
/// modules. Do not invent paths — only what the map lists.
abstract final class ApiEndpoints {
  // ── Auth (public / mobile) ──────────────────────────────────────────────
  static const String publicTenant = '/public/tenant';
  static const String mobileLogin = '/mobile/auth/login';
  static const String mobileMe = '/mobile/me';
  static const String mobileTokenRefresh = '/mobile/auth/token/refresh';
  static const String mobileLogout = '/mobile/auth/logout';
  static const String mobilePasswordForgot = '/mobile/auth/password/forgot';
  static const String mobilePasswordReset = '/mobile/auth/password/reset';
  static const String mobileOtpRequest = '/mobile/auth/otp/request';
  static const String mobileOtpVerify = '/mobile/auth/otp/verify';
  static const String changePassword = '/auth/change-password';
  static const String devices = '/devices';

  // ── Dashboard ───────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String dashboardAlerts = '/dashboard/alerts';
  static const String mobileHome = '/mobile/home';
  static const String search = '/search';
  static const String notifications = '/notifications';

  // ── Residences / staff / clients ────────────────────────────────────────
  static const String residences = '/residences';
  static const String staff = '/staff';
  static const String staffDirectory = '/staff/directory';
  static const String clients = '/clients';

  // ── Scheduling ──────────────────────────────────────────────────────────
  static const String shifts = '/shifts';
  static const String shiftSwaps = '/shift-swaps';

  // ── Attendance ──────────────────────────────────────────────────────────
  static const String attendance = '/attendance';
  static const String attendanceSummary = '/attendance/summary';
  static const String attendanceManual = '/attendance/manual';
  static const String attendanceOvertime = '/attendance/overtime';
  static const String attendanceCheckIn = '/attendance/check-in';
  static const String attendanceCheckOut = '/attendance/check-out';
  static const String attendanceBreakStart = '/attendance/break/start';
  static const String attendanceBreakEnd = '/attendance/break/end';
  static const String appointments = '/appointments';
  static const String recurringCheckInstances = '/recurring-checks/instances';

  // ── Daily logs ──────────────────────────────────────────────────────────
  static const String dailyLogs = '/daily-logs';
  static const String dailyLogEntries = '/daily-logs/entries';
  static const String careFlags = '/care-flags';
  static const String shiftHandovers = '/shift-handovers';
  static const String clientActivities = '/client-activities';

  // ── Incidents ───────────────────────────────────────────────────────────
  static const String incidents = '/incidents';
  static const String incidentsSummary = '/incidents/summary';
  static const String incidentCategories = '/incident-categories';
  static const String incidentCirTemplates = '/incidents/cir-templates';
  static const String uploads = '/uploads';
  static const String tickets = '/tickets';
  static const String notificationPreferences = '/notification-preferences';

  // ── Family (always `/family/*` — staff paths 403 for this role) ─────────
  static const String familyHome = '/family/home';
  static const String familyAppointments = '/family/appointments';
  static const String familyMessages = '/family/messages';
  static const String familyDocuments = '/family/documents';
  static const String familyClients = '/family/clients';
  static const String familyTickets = '/family/tickets';
  static const String familySearch = '/family/search';

  static String familyDailyUpdates(String clientId) =>
      '$familyClients/$clientId/daily-updates';
  static String familyAppointmentById(String id) => '$familyAppointments/$id';
  static String familyAppointmentReschedule(String id) =>
      '$familyAppointments/$id/reschedule';
  static String familyAppointmentCancel(String id) =>
      '$familyAppointments/$id/cancel';
  static String familyConversation(String id) => '$familyMessages/$id';
  static String familyConversationMessages(String id) =>
      '$familyMessages/$id/messages';
  static String familyTicketById(String id) => '$familyTickets/$id';
  static String familyTicketMessages(String id) =>
      '$familyTickets/$id/messages';
  static String ticketMessages(String id) => '$tickets/$id/messages';
  static String ticketClose(String id) => '$tickets/$id/close';

  // ── Medication MAR ──────────────────────────────────────────────────────
  static const String marDue = '/mar/due';
  static const String marRound = '/mar/round';
  static const String marAdministrations = '/mar/administrations';
  static const String medications = '/medications';
  static const String prnMedications = '/prn-medications';

  // ── Tasks & compliance ──────────────────────────────────────────────────
  static const String tasks = '/tasks';
  static const String tasksStats = '/tasks/stats';
  static const String tasksReview = '/tasks/review';
  static const String tasksRecurring = '/tasks/recurring';
  static const String trainingAssignments = '/training/assignments';
  static const String trainingCertificates = '/training/certificates';
  static const String emergencyAlerts = '/emergency-alerts';
  static const String inventoryItems = '/inventory/items';
  static const String supportTickets = '/support/tickets';
  static const String complianceScore = '/compliance/score';
  static const String complianceOverview = '/compliance/overview';
  static const String complianceChecks = '/compliance/checks';
  static const String complianceRequirements = '/compliance/requirements';
  static const String complianceAlerts = '/compliance/alerts';
  static const String complianceFindings = '/compliance/findings';
  static const String complianceCorrectiveActions =
      '/compliance/corrective-actions';

  // ── Team, reports, messages ─────────────────────────────────────────────
  static const String reportsSummary = '/reports/summary';
  static const String reportsKpis = '/reports/kpis';
  static const String reportsSeries = '/reports/series';
  static const String reportsAnalytics = '/reports/analytics';
  static const String reportsExports = '/reports/exports';
  static const String documents = '/documents';
  static const String documentsSummary = '/documents/summary';
  static const String documentTypes = '/document-types';
  static const String conversations = '/conversations';
  static const String conversationContacts = '/conversations/contacts';

  static String staffById(String staffId) => '$staff/$staffId';
  static String residenceById(String id) => '$residences/$id';
  static String residenceGeofence(String id) => '$residences/$id/geofence';
  static String shiftById(String id) => '$shifts/$id';
  static String shiftOpen(String id) => '$shifts/$id/open';
  static String shiftAssignments(String id) => '$shifts/$id/assignments';
  static String shiftCancel(String id) => '$shifts/$id/cancel';
  static String shiftRecurring = '$shifts/recurring';
  static String shiftBidAccept(String shiftId, String bidId) =>
      '$shifts/$shiftId/bids/$bidId/accept';
  static String shiftBids(String shiftId) => '$shifts/$shiftId/bids';
  static String shiftSwapRequests(String shiftId) =>
      '$shifts/$shiftId/swap-requests';
  static String shiftSwapById(String id) => '$shiftSwaps/$id';
  static String shiftSwapDecide(String id) => '$shiftSwaps/$id/decide';
  static String shiftSwapRespond(String id) => '$shiftSwaps/$id/respond';
  static String shiftSwapCancel(String id) => '$shiftSwaps/$id/cancel';
  static String attendanceById(String id) => '$attendance/$id';
  static String attendanceApprove(String id) => '$attendance/$id/approve';
  static String attendanceReject(String id) => '$attendance/$id/reject';
  static String dailyLogEntryById(String id) => '$dailyLogEntries/$id';
  static String dailyLogAmendments(String id) =>
      '$dailyLogEntries/$id/amendments';
  static String careFlagResolve(String id) => '$careFlags/$id/resolve';
  static String handoverById(String id) => '$shiftHandovers/$id';
  static String handoverAcknowledge(String id) =>
      '$shiftHandovers/$id/acknowledge';
  static String handoverComments(String id) => '$shiftHandovers/$id/comments';
  static String handoverStatus(String id) => '$shiftHandovers/$id/status';
  static String incidentById(String id) => '$incidents/$id';
  static String incidentInvestigation(String id) =>
      '$incidents/$id/investigation';
  static String incidentEvidence(String id) => '$incidents/$id/evidence';
  static String incidentAcknowledge(String id) => '$incidents/$id/acknowledge';
  static String incidentActivity(String id) => '$incidents/$id/activity';
  static String notificationRead(String id) => '$notifications/$id/read';
  static const String notificationsReadAll = '$notifications/read-all';
  static String conversationMessages(String id) =>
      '$conversations/$id/messages';
  static String conversationRead(String id) => '$conversations/$id/read';
  static const String conversationsReadAll = '$conversations/read-all';
  static String taskById(String id) => '$tasks/$id';
  static String taskNotes(String id) => '$tasks/$id/notes';
  static String taskAssignees(String id) => '$tasks/$id/assignees';
  static String taskReview(String id) => '$tasks/$id/review';
  static String trainingCourseQuiz(String courseId) =>
      '/training/courses/$courseId/quiz';
  static String trainingCourseAttempts(String courseId) =>
      '/training/courses/$courseId/attempts';
  static String recurringCheckInstanceById(String id) =>
      '$recurringCheckInstances/$id';

  const ApiEndpoints._();
}
