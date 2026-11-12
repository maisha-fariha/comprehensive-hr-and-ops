import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';

/// Residence GPS gate used by the web Clock in / out dialog.
class ResidenceClockGeofence {
  final bool enabled;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;

  const ResidenceClockGeofence({
    required this.enabled,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  static const unknown = ResidenceClockGeofence(enabled: false);

  /// Web only gates clock-in when the residence flag is on and a radius exists.
  bool get requiresGate =>
      enabled &&
      latitude != null &&
      longitude != null &&
      (radiusMeters ?? 0) > 0;

  double? distanceMetersFrom(double lat, double lng) {
    if (latitude == null || longitude == null) return null;
    return Geolocator.distanceBetween(latitude!, longitude!, lat, lng);
  }

  bool? isWithin(double lat, double lng) {
    if (!requiresGate) return null;
    final distance = distanceMetersFrom(lat, lng);
    if (distance == null) return null;
    return distance <= (radiusMeters ?? 0);
  }
}

Future<ResidenceClockGeofence> loadResidenceClockGeofence(
  String residenceId,
) async {
  if (residenceId.isEmpty || !GetIt.instance.isRegistered<AppApiClient>()) {
    return ResidenceClockGeofence.unknown;
  }
  final result = await GetIt.instance<AppApiClient>().get(
    ApiEndpoints.residenceById(residenceId),
    silent: true,
  );
  if (result.isFailure) return ResidenceClockGeofence.unknown;
  final json = JsonCodec.unwrapMap(result.value);
  final geofence = JsonCodec.mapAt(json, 'geofence') ?? {};
  final enabled = JsonCodec.boolean(json['geofenceEnabled']) ??
      JsonCodec.boolean(geofence['enabled']) ??
      false;
  final lat = JsonCodec.number(json['latitude'])?.toDouble();
  final lng = JsonCodec.number(json['longitude'])?.toDouble();
  // Nested `geofence.radiusMeters` matches web; top-level is a legacy fallback.
  final radius = JsonCodec.number(
    geofence['radiusMeters'] ??
        geofence['radius'] ??
        json['geofenceRadiusMeters'],
  )?.toDouble();
  return ResidenceClockGeofence(
    enabled: enabled,
    latitude: lat,
    longitude: lng,
    radiusMeters: radius,
  );
}

/// Org `attendance_verification` flags — ask only, never hard-block alone.
class ClockVerificationPrefs {
  final bool askLocation;
  final bool askPhoto;

  const ClockVerificationPrefs({
    this.askLocation = false,
    this.askPhoto = false,
  });

  static Future<ClockVerificationPrefs> load() async {
    if (!GetIt.instance.isRegistered<AppApiClient>()) {
      return const ClockVerificationPrefs();
    }
    // Avoid 403 when the role cannot read org settings — use safe defaults.
    try {
      if (Get.isRegistered<UserSession>()) {
        final session = Get.find<UserSession>();
        if (session.permissionsReady && !session.can('settings:read')) {
          return const ClockVerificationPrefs();
        }
      }
    } catch (_) {}
    final result = await GetIt.instance<AppApiClient>().get(
      ApiEndpoints.settings,
      silent: true,
    );
    if (result.isFailure) return const ClockVerificationPrefs();
    final map = JsonCodec.unwrapMap(result.value);
    final attendance = JsonCodec.asMap(map['attendance_verification']);
    return ClockVerificationPrefs(
      askLocation: JsonCodec.boolean(attendance['locationRequired']) ?? false,
      askPhoto: JsonCodec.boolean(attendance['photoRequired']) ?? false,
    );
  }
}

/// Web distance copy: `209.7 km` / `48 m`.
String formatClockDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  if (meters >= 100) return '${meters.round()} m';
  if (meters >= 10) return '${meters.toStringAsFixed(1)} m';
  return '${meters.toStringAsFixed(1)} m';
}

TextStyle _clockVerifyText(
  double size,
  FontWeight weight, [
  Color color = AppColors.textHeading,
]) =>
    TextStyle(
      fontFamily: 'Outfit',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
    );

/// Web "Location verification" block on Clock in / out.
class ClockLocationVerification extends StatelessWidget {
  final ResidenceClockGeofence? geofence;
  final bool loadingGeofence;
  final bool capturingLocation;
  final double? latitude;
  final double? longitude;
  final int? accuracyMeters;
  final String? locationError;
  final bool? withinGeofence;
  final VoidCallback? onRetry;

  const ClockLocationVerification({
    super.key,
    required this.geofence,
    this.loadingGeofence = false,
    this.capturingLocation = false,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.locationError,
    this.withinGeofence,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final fence = geofence;
    final gated = fence?.requiresGate == true;

    Widget pill(String label, Color fg, Color bg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: _clockVerifyText(11, FontWeight.w600, fg)),
        );

    Widget tryAgain() {
      if (onRetry == null) return const SizedBox.shrink();
      return TextButton.icon(
        onPressed: capturingLocation ? null : onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Try again'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: _clockVerifyText(12.5, FontWeight.w600),
        ),
      );
    }

    final children = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.place_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location verification',
                  style: _clockVerifyText(13, FontWeight.w600),
                ),
                if (gated) ...[
                  const SizedBox(height: 2),
                  Text(
                    'This residence requires GPS verification to ensure staff '
                    'are on site.',
                    style: _clockVerifyText(
                      12,
                      FontWeight.w400,
                      AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
    ];

    if (loadingGeofence || fence == null) {
      children.add(
        Text(
          'Checking whether this home needs an on-site location…',
          style: _clockVerifyText(12.5, FontWeight.w400, AppColors.textSecondary),
        ),
      );
    } else if (!gated) {
      children.addAll([
        Text(
          'Geofencing is not enabled for this residence — location '
          'verification not required.',
          style: _clockVerifyText(12.5, FontWeight.w400, AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            pill(
              'Geofence Off',
              AppColors.textSecondary,
              AppColors.filterButtonBackground,
            ),
            Text(
              'Staff can clock in directly without GPS location checks.',
              style: _clockVerifyText(
                12.5,
                FontWeight.w400,
                AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ]);
    } else if (capturingLocation && latitude == null && locationError == null) {
      children.add(
        Text(
          'Finding your location…',
          style: _clockVerifyText(12.5, FontWeight.w400, AppColors.textSecondary),
        ),
      );
    } else if (latitude != null && longitude != null) {
      final distance = fence.distanceMetersFrom(latitude!, longitude!);
      final radius = fence.radiusMeters ?? 0;
      final inside = withinGeofence == true ||
          (distance != null && distance <= radius);
      final distanceLabel =
          distance == null ? null : formatClockDistance(distance);
      final radiusLabel = radius >= 1000
          ? formatClockDistance(radius)
          : '${radius.round()} m';
      final gpsLabel = accuracyMeters == null ? null : 'GPS ±$accuracyMeters m';

      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            pill(
              inside ? 'Within geofence' : 'Outside geofence',
              inside ? AppColors.activeGreen : AppColors.criticalRed,
              inside ? AppColors.activeBackground : const Color(0xFFFDECEC),
            ),
            if (distanceLabel != null)
              Text(
                inside
                    ? '$distanceLabel from center'
                        '${gpsLabel == null ? '' : ' · $gpsLabel'}'
                    : '$distanceLabel away · Must be within $radiusLabel '
                        'to clock in'
                        '${gpsLabel == null ? '' : ' ($gpsLabel)'}',
                style: _clockVerifyText(
                  12.5,
                  FontWeight.w400,
                  AppColors.textSecondary,
                ),
              ),
            tryAgain(),
          ],
        ),
      );

      if (!inside && distanceLabel != null) {
        children.addAll([
          const SizedBox(height: 10),
          Text(
            'You are currently $distanceLabel away from the residence. '
            'You must be within $radiusLabel to clock in. This residence '
            'records where a shift starts, so clocking in requires your '
            'location.',
            style: _clockVerifyText(
              12.5,
              FontWeight.w400,
              AppColors.textSecondary,
            ),
          ),
        ]);
      }
    } else {
      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            pill(
              'No location',
              AppColors.urgentAmber,
              AppColors.urgentBackground,
            ),
            Text(
              '${locationError ?? 'Location unavailable'} — this home needs '
              'GPS to let you in.',
              style: _clockVerifyText(
                12.5,
                FontWeight.w400,
                AppColors.textSecondary,
              ),
            ),
            tryAgain(),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground.withValues(alpha: 0.45),
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Web "Photo verification" block.
class ClockPhotoVerification extends StatelessWidget {
  final bool enabledToggle;
  final Widget? captureChild;
  final ValueChanged<bool>? onToggle;

  const ClockPhotoVerification({
    super.key,
    this.enabledToggle = false,
    this.captureChild,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo verification',
                    style: _clockVerifyText(13, FontWeight.w600),
                  ),
                  Text(
                    'Capture a selfie with this clock-in (optional)',
                    style: _clockVerifyText(
                      12,
                      FontWeight.w400,
                      AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: enabledToggle,
              onChanged: onToggle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (enabledToggle)
          captureChild ?? const SizedBox.shrink()
        else
          Text(
            'Photo verification turned off — clocking in without a photo '
            'is allowed.',
            style: _clockVerifyText(12.5, FontWeight.w400, AppColors.textSecondary),
          ),
      ],
    );
  }
}
