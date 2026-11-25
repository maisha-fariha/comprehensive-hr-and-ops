import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/residence_geocoder.dart';

/// Interactive pin + geofence radius map for the residence Address step.
///
/// Web embeds Google Maps; the app uses OSM tiles ([flutter_map]) and the
/// same Nominatim geocoder as address auto-fill (no Maps API key required).
class ResidenceGeofenceMap extends StatefulWidget {
  final String latitude;
  final String longitude;
  final String geofenceRadiusMeters;
  final ValueChanged<({String lat, String lng})> onPinChanged;

  const ResidenceGeofenceMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    required this.onPinChanged,
  });

  @override
  State<ResidenceGeofenceMap> createState() => _ResidenceGeofenceMapState();
}

class _ResidenceGeofenceMapState extends State<ResidenceGeofenceMap> {
  static const _fallback = LatLng(39.8283, -98.5795); // continental US center

  final _map = MapController();
  final _search = TextEditingController();
  final _geocoder = ResidenceGeocoder();
  bool _searching = false;
  bool _locating = false;

  LatLng? get _pin {
    final lat = double.tryParse(widget.latitude.trim());
    final lng = double.tryParse(widget.longitude.trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  double get _radiusMeters {
    final n = double.tryParse(widget.geofenceRadiusMeters.trim());
    if (n == null || n <= 0) return 150;
    return n.clamp(10, 5000);
  }

  @override
  void didUpdateWidget(covariant ResidenceGeofenceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _pin;
    if (next == null) return;
    final latChanged = oldWidget.latitude != widget.latitude;
    final lngChanged = oldWidget.longitude != widget.longitude;
    if (!latChanged && !lngChanged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _map.move(next, _map.camera.zoom < 12 ? 15 : _map.camera.zoom);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  void _place(LatLng point, {double? zoom}) {
    widget.onPinChanged((
      lat: point.latitude.toStringAsFixed(6),
      lng: point.longitude.toStringAsFixed(6),
    ));
    _map.move(point, zoom ?? (_map.camera.zoom < 12 ? 15 : _map.camera.zoom));
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final hit = await _geocoder.geocode(q);
    if (!mounted) return;
    setState(() => _searching = false);
    if (hit == null) {
      AppSnackbar.show('No place found for that search', '');
      return;
    }
    _place(LatLng(double.parse(hit.lat), double.parse(hit.lng)), zoom: 16);
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are turned off';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission was not given';
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      _place(LatLng(position.latitude, position.longitude), zoom: 16);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Could not use current location',
        error is String ? error : '',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pin;
    final center = pin ?? _fallback;
    final radius = _radiusMeters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            key: const ValueKey('residence-geofence-map'),
            height: 240,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: pin == null ? 3.5 : 15,
                    onTap: (tap, point) => _place(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'comprehensive_hr_and_ops',
                    ),
                    if (pin != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: pin,
                            radius: radius,
                            useRadiusInMeter: true,
                            color: AppColors.secondaryTeal.withValues(alpha: 0.18),
                            borderColor: AppColors.secondaryTeal,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (pin != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: pin,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.criticalRed,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.surfaceWhite,
                    child: TextField(
                      key: const ValueKey('residence-map-search'),
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search address or landmark to place pin…',
                        hintStyle: handoverText(
                          context,
                          12.5,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Search',
                                onPressed: _runSearch,
                                icon: const Icon(Icons.arrow_forward, size: 18),
                              ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 36,
                  child: Material(
                    elevation: 2,
                    color: AppColors.surfaceWhite,
                    shape: const CircleBorder(),
                    child: IconButton(
                      key: const ValueKey('residence-map-my-location'),
                      tooltip: 'My Location',
                      onPressed: _locating ? null : _useMyLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Text(
                      pin == null
                          ? 'Tap the map or search to place the residence pin.'
                          : 'Geofence ≈ ${radius.round()} m · tap map to move pin',
                      textAlign: TextAlign.center,
                      style: handoverText(
                        context,
                        11,
                        color: Colors.white,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Map data © OpenStreetMap contributors',
          style: handoverText(context, 10.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
