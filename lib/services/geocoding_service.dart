import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/search_place.dart';
import 'coordinate_parser.dart';

class GeocodingService {
  /// Tìm kiếm địa điểm và phân tích tọa độ GPS
  Future<List<SearchPlace>> searchPlaces(String query, {LatLng? userLocation}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final List<SearchPlace> results = [];

    // 1. Kiểm tra xem người dùng có nhập/dán TỌA ĐỘ GPS không (DD hoặc DMS)
    final parsedCoord = CoordinateParser.parse(cleanQuery);
    if (parsedCoord != null) {
      results.add(
        SearchPlace(
          name: 'Tọa độ GPS: ${parsedCoord.latitude.toStringAsFixed(5)}, ${parsedCoord.longitude.toStringAsFixed(5)}',
          description: 'Vị trí chính xác theo tọa độ bạn đã nhập',
          location: parsedCoord,
          type: 'coordinate',
        ),
      );
    }

    // 2. Tìm kiếm qua Photon OpenStreetMap Engine (hỗ trợ tiếng Việt và dữ liệu OSM toàn cầu)
    try {
      String urlStr = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=10';
      if (userLocation != null) {
        urlStr += '&lat=${userLocation.latitude}&lon=${userLocation.longitude}';
      }

      final response = await http
          .get(Uri.parse(urlStr))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final features = data['features'] as List? ?? [];

        for (final item in features) {
          final place = SearchPlace.fromPhotonJson(item as Map<String, dynamic>);
          if (place.name.isNotEmpty) {
            results.add(place);
          }
        }
      }
    } catch (_) {}

    // 3. Nếu danh sách vẫn rỗng, fallback tìm kiếm qua Nominatim
    if (results.isEmpty) {
      try {
        final nomUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=6&addressdetails=1';
        final response = await http
            .get(
              Uri.parse(nomUrl),
              headers: {
                'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
              },
            )
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final List list = jsonDecode(utf8.decode(response.bodyBytes));
          for (final item in list) {
            final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0;
            final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0;
            results.add(
              SearchPlace(
                name: item['name'] ?? item['display_name']?.split(',').first ?? 'Địa điểm',
                description: item['display_name'] ?? '',
                location: LatLng(lat, lon),
                type: item['type'] ?? 'place',
              ),
            );
          }
        }
      } catch (_) {}
    }

    return results;
  }
}
