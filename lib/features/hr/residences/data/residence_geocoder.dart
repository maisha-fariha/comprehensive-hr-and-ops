import 'dart:convert';
import 'dart:io';

/// Client-side address → coordinates, matching web residence form geocode.
///
/// Web uses `google.maps.Geocoder` after address debounce. The app uses the
/// public Nominatim search API (no Maps key in mobile env) with the same
/// composed address string.
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
    HttpClient? client;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'limit': '1',
      });
      client = HttpClient();
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'comprehensive-hr-and-ops/1.0 (residence-form)',
      );
      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is! Map) return null;
      final lat = first['lat'];
      final lng = first['lon'];
      if (lat == null || lng == null) return null;
      final latN = double.tryParse(lat.toString());
      final lngN = double.tryParse(lng.toString());
      if (latN == null || lngN == null) return null;
      return (lat: latN.toStringAsFixed(6), lng: lngN.toStringAsFixed(6));
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}
