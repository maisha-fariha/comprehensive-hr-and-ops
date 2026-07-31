import 'package:gems_core/gems_core.dart';

import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/family_visit_requests_overview.dart';
import '../../domain/entities/my_visit_request.dart';
import '../../domain/entities/visit_request.dart';
import '../../domain/entities/visit_request_detail.dart';
import '../../domain/repositories/visit_requests_repository.dart';

/// Local implementation of [VisitRequestsRepository].
///
/// There is no backend endpoint for Family Visit Requests yet, so this
/// returns the exact static content shown in the Figma "All - Visit
/// Requests", "My Requests - Visit Requests", "History - Visit Requests"
/// and "Details - My Requests - Visit Requests" screenshots (see the
/// feature's final report for exactly which values are directly visible
/// vs. reasonable approximations).
class VisitRequestsRepositoryImpl implements VisitRequestsRepository {
  static const List<VisitRequest> _allRequests = [
    VisitRequest(
      id: 'all-emily-carter',
      requesterName: 'Emily Carter',
      type: VisitRequestType.visit,
      mode: VisitRequestMode.inPerson,
      locationLabel: 'In-Person at Sunrise Home',
      dateTimeLabel: 'May 18, 2025 · 2:00 PM',
      status: VisitRequestStatus.pending,
    ),
    VisitRequest(
      id: 'all-michael-reyes',
      requesterName: 'Michael Reyes',
      type: VisitRequestType.appointment,
      mode: VisitRequestMode.telehealth,
      dateTimeLabel: 'May 15, 2025 · 10:30 AM',
      status: VisitRequestStatus.approved,
    ),
    VisitRequest(
      id: 'all-sofia-nguyen',
      requesterName: 'Sofia Nguyen',
      type: VisitRequestType.visit,
      mode: VisitRequestMode.inPerson,
      locationLabel: 'In-Person at Sunrise Home',
      dateTimeLabel: 'May 14, 2025 · 4:00 PM',
      status: VisitRequestStatus.rescheduleRequested,
    ),
    VisitRequest(
      id: 'all-david-owusu',
      requesterName: 'David Owusu',
      type: VisitRequestType.appointment,
      mode: VisitRequestMode.inPerson,
      locationLabel: 'In-Person at Clinic',
      dateTimeLabel: 'May 13, 2025 · 9:00 AM',
      status: VisitRequestStatus.pending,
    ),
  ];

  // NOTE: the source screenshot crops "Grace Bennett" off right after her
  // name/status/type tag - her date/time is a plausible approximation that
  // continues the other rows' descending-date pattern, flagged here since
  // it isn't directly visible.
  static const List<VisitRequest> _historyRequests = [
    VisitRequest(
      id: 'history-emily-carter',
      requesterName: 'Emily Carter',
      type: VisitRequestType.visit,
      dateTimeLabel: 'Apr 30, 2025 · 4:00 PM',
      status: VisitRequestStatus.completed,
    ),
    VisitRequest(
      id: 'history-michael-reyes',
      requesterName: 'Michael Reyes',
      type: VisitRequestType.appointment,
      dateTimeLabel: 'Apr 26, 2025 · 11:00 AM',
      status: VisitRequestStatus.rejected,
    ),
    VisitRequest(
      id: 'history-sofia-nguyen',
      requesterName: 'Sofia Nguyen',
      type: VisitRequestType.visit,
      dateTimeLabel: 'Apr 22, 2025 · 2:30 PM',
      status: VisitRequestStatus.cancelled,
    ),
    VisitRequest(
      id: 'history-david-owusu',
      requesterName: 'David Owusu',
      type: VisitRequestType.appointment,
      dateTimeLabel: 'Apr 18, 2025 · 9:30 AM',
      status: VisitRequestStatus.completed,
    ),
    VisitRequest(
      id: 'history-grace-bennett',
      requesterName: 'Grace Bennett',
      type: VisitRequestType.visit,
      dateTimeLabel: 'Apr 15, 2025 · 1:00 PM',
      status: VisitRequestStatus.completed,
    ),
  ];

  // NOTE: only the first (Pending) and second (Approved) cards' description
  // lines are directly visible in the source screenshot; the third
  // (Rejected) card is cropped right after its type tag, and the stat
  // chips ("2 Pending", "3 Approved", "1 Rejected") imply 3 more requests
  // beyond the 3 visible cards - "my-4"/"my-5"/"my-6" below are reasonable
  // approximations added so the counts and list stay consistent, flagged
  // here since they aren't directly visible.
  static const List<MyVisitRequest> _myRequests = [
    MyVisitRequest(
      id: 'my-1',
      type: VisitRequestType.visit,
      dateTimeLabel: 'May 18, 2025 · 2:00 PM',
      status: VisitRequestStatus.pending,
      description: 'Birthday celebration with the family — hoping to book the courtyard.',
    ),
    MyVisitRequest(
      id: 'my-2',
      type: VisitRequestType.visit,
      dateTimeLabel: 'May 10, 2025 · 3:00 PM',
      status: VisitRequestStatus.approved,
      description: 'In-Person at Sunrise Home',
    ),
    MyVisitRequest(
      id: 'my-3',
      type: VisitRequestType.appointment,
      dateTimeLabel: 'Apr 28, 2025 · 1:00 PM',
      status: VisitRequestStatus.rejected,
      description: 'Telehealth check-in requested to discuss recent care plan updates.',
    ),
    MyVisitRequest(
      id: 'my-4',
      type: VisitRequestType.appointment,
      dateTimeLabel: 'Apr 20, 2025 · 11:00 AM',
      status: VisitRequestStatus.pending,
      description: 'Follow-up appointment requested with the care team.',
    ),
    MyVisitRequest(
      id: 'my-5',
      type: VisitRequestType.visit,
      dateTimeLabel: 'Apr 12, 2025 · 1:00 PM',
      status: VisitRequestStatus.approved,
      description: 'In-Person at Sunrise Home',
    ),
    MyVisitRequest(
      id: 'my-6',
      type: VisitRequestType.visit,
      dateTimeLabel: 'Apr 5, 2025 · 10:00 AM',
      status: VisitRequestStatus.approved,
      description: 'In-Person at Sunrise Home',
    ),
  ];

  // NOTE: only "my-1" (the Pending request) matches the "Details - My
  // Requests - Visit Requests" screenshot exactly. The other requests'
  // details are reasonable approximations that follow the same structure/
  // tone, built by analogy since no matching screenshot exists for them -
  // flagged in the feature's final report.
  static const Map<String, VisitRequestDetail> _details = {
    'my-1': VisitRequestDetail(
      id: 'my-1',
      type: VisitRequestType.visit,
      status: VisitRequestStatus.pending,
      dateTimeLabel: 'May 18, 2025 · 2:00 PM',
      locationModeLabel: 'In-Person at Sunrise Home',
      patientName: 'John Doe',
      assignedStaffLabel: 'Sarah M. — Care Manager',
      roomLocationLabel: 'Sunrise Home · Room 207',
      purpose: 'Family Visit',
      notes: "I'd like to celebrate John's birthday and have some family time.",
    ),
    'my-2': VisitRequestDetail(
      id: 'my-2',
      type: VisitRequestType.visit,
      status: VisitRequestStatus.approved,
      dateTimeLabel: 'May 10, 2025 · 3:00 PM',
      locationModeLabel: 'In-Person at Sunrise Home',
      patientName: 'John Doe',
      assignedStaffLabel: 'Sarah M. — Care Manager',
      roomLocationLabel: 'Sunrise Home · Room 207',
      purpose: 'Family Visit',
      notes: 'Regular weekend visit to spend time with John and catch up on his week.',
    ),
    'my-3': VisitRequestDetail(
      id: 'my-3',
      type: VisitRequestType.appointment,
      status: VisitRequestStatus.rejected,
      dateTimeLabel: 'Apr 28, 2025 · 1:00 PM',
      locationModeLabel: 'Telehealth',
      patientName: 'John Doe',
      assignedStaffLabel: 'Sarah M. — Care Manager',
      roomLocationLabel: 'Sunrise Home · Room 207',
      purpose: 'Care Plan Review',
      notes: 'Requested a video call to go over recent changes to the care plan.',
    ),
    'my-4': VisitRequestDetail(
      id: 'my-4',
      type: VisitRequestType.appointment,
      status: VisitRequestStatus.pending,
      dateTimeLabel: 'Apr 20, 2025 · 11:00 AM',
      locationModeLabel: 'In-Person at Sunrise Home',
      patientName: 'John Doe',
      assignedStaffLabel: 'Sarah M. — Care Manager',
      roomLocationLabel: 'Sunrise Home · Room 207',
      purpose: 'Follow-Up Appointment',
      notes: 'Follow-up appointment to review John\'s progress with the care team.',
    ),
    'my-5': VisitRequestDetail(
      id: 'my-5',
      type: VisitRequestType.visit,
      status: VisitRequestStatus.approved,
      dateTimeLabel: 'Apr 12, 2025 · 1:00 PM',
      locationModeLabel: 'In-Person at Sunrise Home',
      patientName: 'John Doe',
      assignedStaffLabel: 'Sarah M. — Care Manager',
      roomLocationLabel: 'Sunrise Home · Room 207',
      purpose: 'Family Visit',
      notes: 'Afternoon visit to spend time with John in the courtyard.',
    ),
    'my-6': VisitRequestDetail(
      id: 'my-6',
      type: VisitRequestType.visit,
      status: VisitRequestStatus.approved,
      dateTimeLabel: 'Apr 5, 2025 · 10:00 AM',
      locationModeLabel: 'In-Person at Sunrise Home',
      patientName: 'John Doe',
      assignedStaffLabel: 'Sarah M. — Care Manager',
      roomLocationLabel: 'Sunrise Home · Room 207',
      purpose: 'Family Visit',
      notes: 'Morning visit to bring John his favorite books and photos.',
    ),
  };

  @override
  Future<Result<FamilyVisitRequestsOverview>> getOverview() async {
    return Result.success(
      const FamilyVisitRequestsOverview(
        allRequests: _allRequests,
        myRequests: _myRequests,
        historyRequests: _historyRequests,
      ),
    );
  }

  @override
  Future<Result<VisitRequestDetail>> getRequestDetail(String requestId) async {
    final detail = _details[requestId];
    if (detail == null) {
      return Result.failure(UnknownError(message: 'Visit request not found.'));
    }
    return Result.success(detail);
  }
}
