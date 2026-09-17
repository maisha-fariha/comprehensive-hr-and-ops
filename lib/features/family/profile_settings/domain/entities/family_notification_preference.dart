import 'package:flutter/foundation.dart';

@immutable
class FamilyNotificationPreference {
  final String channel;
  final String eventKey;
  final bool enabled;
  final String? displayLabel;
  final bool configurable;

  const FamilyNotificationPreference({
    required this.channel,
    required this.eventKey,
    required this.enabled,
    this.displayLabel,
    this.configurable = true,
  });

  FamilyNotificationPreference copyWith({bool? enabled}) {
    return FamilyNotificationPreference(
      channel: channel,
      eventKey: eventKey,
      enabled: enabled ?? this.enabled,
      displayLabel: displayLabel,
      configurable: configurable,
    );
  }

  String get label {
    if (displayLabel != null && displayLabel!.trim().isNotEmpty) {
      return displayLabel!.trim();
    }
    final spaced = eventKey.replaceAll('.', ' ').replaceAll('_', ' ');
    if (spaced.isEmpty) return channel;
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  String get channelLabel {
    switch (channel.toLowerCase()) {
      case 'push':
        return 'Push';
      case 'in_app':
        return 'In-app';
      case 'email':
        return 'Email';
      default:
        return channel;
    }
  }

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'eventKey': eventKey,
        'enabled': enabled,
      };
}
