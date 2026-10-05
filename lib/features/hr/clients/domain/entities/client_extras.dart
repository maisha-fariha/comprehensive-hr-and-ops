import 'package:flutter/foundation.dart';

import 'client_summary.dart';

/// One page of `GET /clients`.
@immutable
class ClientPage {
  final List<ClientSummary> items;
  final int total;
  final int totalPages;

  const ClientPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });
}

/// A relative on the record (`GET /clients/{id}/family`).
@immutable
class ClientFamilyMember {
  final String id;
  final String name;
  final String? userId;
  final String? relationship;
  final String? email;
  final String? phone;
  final bool isPrimaryGuardian;
  final bool isEmergencyContact;
  final bool receiveNotifications;
  final bool emergencyAlerts;

  const ClientFamilyMember({
    required this.id,
    required this.name,
    this.userId,
    this.relationship,
    this.email,
    this.phone,
    this.isPrimaryGuardian = false,
    this.isEmergencyContact = false,
    this.receiveNotifications = false,
    this.emergencyAlerts = false,
  });

  bool get hasPortalAccess => userId != null && userId!.isNotEmpty;
}

/// A room at a residence (`GET /residences/{id}/rooms`).
@immutable
class ClientRoom {
  final String id;
  final String name;
  final String? roomType;
  final bool isActive;
  final int available;

  const ClientRoom({
    required this.id,
    required this.name,
    this.roomType,
    this.isActive = true,
    this.available = 0,
  });
}

/// `GET /inventory/client-spend/{clientId}`.
@immutable
class ClientSpend {
  final num? spend;
  final int purchaseCount;
  final num? stockOnHandValue;
  final int stockOnHandCount;
  final int unpricedStockCount;
  final List<ClientPurchase> purchases;

  const ClientSpend({
    this.spend,
    this.purchaseCount = 0,
    this.stockOnHandValue,
    this.stockOnHandCount = 0,
    this.unpricedStockCount = 0,
    this.purchases = const [],
  });
}

@immutable
class ClientPurchase {
  final String item;
  final num quantity;
  final String? unit;
  final num? unitCost;
  final num? lineTotal;
  final DateTime? orderedAt;

  const ClientPurchase({
    required this.item,
    required this.quantity,
    this.unit,
    this.unitCost,
    this.lineTotal,
    this.orderedAt,
  });
}

/// A file chosen on the device, before it is uploaded.
@immutable
class ClientPickedFile {
  final String path;
  final String name;
  final int size;

  const ClientPickedFile({
    required this.path,
    required this.name,
    this.size = 0,
  });
}

/// Body of `POST /clients/{id}/transfer`.
@immutable
class ClientTransferRequest {
  final String toResidenceId;
  final String? roomId;
  final String? reason;
  final String? overCapacityReason;

  const ClientTransferRequest({
    required this.toResidenceId,
    this.roomId,
    this.reason,
    this.overCapacityReason,
  });

  Map<String, dynamic> toJson() {
    final why = reason?.trim() ?? '';
    final anyway = overCapacityReason?.trim() ?? '';
    return {
      'toResidenceId': toResidenceId,
      'roomId': ?roomId,
      if (why.isNotEmpty) 'reason': why,
      if (anyway.isNotEmpty) 'overCapacityReason': anyway,
    };
  }
}
