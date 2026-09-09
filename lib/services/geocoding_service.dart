import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/search_place.dart';

class GeocodingService {
  /// Tìm kiếm địa điểm dựa trên OpenStreetMap data qua Photon / Nominatim API
  Future<List<SearchPlace>> searchPlaces(String query, {LatLng? userLocation}) async {
    if (query.trim().isEmpty) return [];

    try {
      String urlStr = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=8';
      if (userLocation != null) {
        urlStr += '&lat=${userLocation.latitude}&lon=${userLocation.longitude}';
      }

      final response = await http
          .get(Uri.parse(urlStr))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final features = data['features'] as List? ?? [];

        return features
            .map((item) => SearchPlace.fromPhotonJson(item as Map<String, dynamic>))
            .where((p) => p.name.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Fallback sang Nominatim nếu Photon tạm thời bận
      try {
        final nomUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=6&addressdetails=1';
        final response = await http
            .get(Uri.parse(nomUrl), headers: {'User-Agent': 'esp32_nav_app/1.0'})
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final List list = jsonDecode(utf8.decode(response.bodyBytes));
          return list.map((item) {
            final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0;
            final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0;
            return SearchPlace(
              name: item['name'] ?? item['display_name']?.split(',').first ?? 'Địa điểm',
              description: item['display_name'] ?? '',
              location: LatLng(lat, lon),
              type: item['type'] ?? 'place',
            );
          }).toList();
        }
      } catch (_) {}
    }

    return [];
  }
}
