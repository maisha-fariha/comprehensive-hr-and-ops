import 'package:flutter/foundation.dart';

@immutable
class FamilyNotificationPreference {
  final String channel;
  final String eventKey;
  final bool enabled;

  const FamilyNotificationPreference({
    required this.channel,
    required this.eventKey,
    required this.enabled,
  });

  FamilyNotificationPreference copyWith({bool? enabled}) {
    return FamilyNotificationPreference(
      channel: channel,
      eventKey: eventKey,
      enabled: enabled ?? this.enabled,
    );
  }

  String get label {
    final spaced = eventKey.replaceAll('.', ' ').replaceAll('_', ' ');
    if (spaced.isEmpty) return channel;
    return '${spaced[0].toUpperCase()}${spaced.substring(1)} · $channel';
  }

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'eventKey': eventKey,
        'enabled': enabled,
      };
}
