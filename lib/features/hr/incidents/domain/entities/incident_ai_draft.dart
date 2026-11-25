import 'package:flutter/foundation.dart';

/// Response from web `POST /ai/incidents/draft` ("Draft from my notes").
@immutable
class IncidentAiDraft {
  final String? date;
  final String? time;
  final String? endTime;
  final String? categoryId;
  final String? clientId;
  final String? residenceId;
  final String? detectedDuring;
  final List<String> witnesses;
  final IncidentAiExternalAgency? externalAgency;
  final List<IncidentAiNotification> notifications;
  final String title;
  final String description;
  final String immediateAction;
  final String? severity;
  final bool? emergencyServicesContacted;
  final bool? familyNotified;
  final String? categoryDetail;
  final IncidentAiPerson? reportedBy;
  final IncidentAiPerson? supervisor;
  final IncidentAiChild? child;
  final IncidentAiFollowUp? followUp;
  final IncidentAiDebrief? debrief;
  final List<String> missing;
  final Map<String, dynamic> cirAnswers;
  final String? model;

  const IncidentAiDraft({
    this.date,
    this.time,
    this.endTime,
    this.categoryId,
    this.clientId,
    this.residenceId,
    this.detectedDuring,
    this.witnesses = const [],
    this.externalAgency,
    this.notifications = const [],
    required this.title,
    required this.description,
    required this.immediateAction,
    this.severity,
    this.emergencyServicesContacted,
    this.familyNotified,
    this.categoryDetail,
    this.reportedBy,
    this.supervisor,
    this.child,
    this.followUp,
    this.debrief,
    this.missing = const [],
    this.cirAnswers = const {},
    this.model,
  });
}

@immutable
class IncidentAiPerson {
  final String id;
  final String name;

  const IncidentAiPerson({required this.id, required this.name});
}

@immutable
class IncidentAiExternalAgency {
  final String type;
  final String? reference;
  final String? responder;

  const IncidentAiExternalAgency({
    required this.type,
    this.reference,
    this.responder,
  });
}

@immutable
class IncidentAiNotification {
  final String party;
  final String? contactName;
  final String? date;

  const IncidentAiNotification({
    required this.party,
    this.contactName,
    this.date,
  });
}

@immutable
class IncidentAiChild {
  final String? idNumber;
  final List<String> cfsStatus;
  final String? cipName;
  final String? cipOffice;
  final bool? informedOfRights;

  const IncidentAiChild({
    this.idNumber,
    this.cfsStatus = const [],
    this.cipName,
    this.cipOffice,
    this.informedOfRights,
  });
}

@immutable
class IncidentAiFollowUp {
  final bool? required;
  final String? dueDate;

  const IncidentAiFollowUp({this.required, this.dueDate});
}

@immutable
class IncidentAiDebrief {
  final bool? completed;
  final String? details;

  const IncidentAiDebrief({this.completed, this.details});
}
