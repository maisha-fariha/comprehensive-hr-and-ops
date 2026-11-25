import 'dart:convert';
import 'dart:io';

/// Client-side address → coordinates, matching web residence form geocode.
///
/// Web uses `google.maps.Geocoder`. Mobile has no Maps key, so we try
/// Nominatim then Photon (same composed address string as web).
class ResidenceGeocoder {
  static String composeAddress({
    required String street,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  }) {
    return [
      street.trim(),
      city.trim(),
      state.trim(),
      postalCode.trim(),
      country.trim(),
    ].where((p) => p.isNotEmpty).join(', ');
  }

  /// Returns `(lat, lng)` as fixed-6 strings, or null when not found / failed.
  Future<({String lat, String lng})?> geocode(String address) async {
    final q = address.trim();
    if (q.isEmpty) return null;

    final candidates = <String>{
      q,
      // Shorter fallbacks help when street text is incomplete / local.
      if (q.contains(',')) q.split(',').skip(1).join(',').trim(),
    }.where((s) => s.length >= 3).toList();

    for (final query in candidates) {
      final hit = await _nominatim(query) ?? await _photon(query);
      if (hit != null) return hit;
    }
    return null;
  }

  Future<({String lat, String lng})?> _nominatim(String q) async {
    HttpClient? client;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'limit': '1',
      });
      client = HttpClient();
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'comprehensive-hr-and-ops/1.0 (residence-form)',
      );
      final response =
          await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is! Map) return null;
      return _pair(first['lat'], first['lon']);
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  Future<({String lat, String lng})?> _photon(String q) async {
    HttpClient? client;
    try {
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': q,
        'limit': '1',
      });
      client = HttpClient();
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'comprehensive-hr-and-ops/1.0 (residence-form)',
      );
      final response =
          await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final features = decoded['features'];
      if (features is! List || features.isEmpty) return null;
      final first = features.first;
      if (first is! Map) return null;
      final geometry = first['geometry'];
      if (geometry is! Map) return null;
      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) return null;
      // GeoJSON: [lng, lat]
      return _pair(coords[1], coords[0]);
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  ({String lat, String lng})? _pair(dynamic lat, dynamic lng) {
    if (lat == null || lng == null) return null;
    final latN = double.tryParse(lat.toString());
    final lngN = double.tryParse(lng.toString());
    if (latN == null || lngN == null) return null;
    return (lat: latN.toStringAsFixed(6), lng: lngN.toStringAsFixed(6));
  }
}
