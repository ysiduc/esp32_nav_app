import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/search_place.dart';
import 'coordinate_parser.dart';

class GeocodingService {
  // Cơ sở dữ liệu POI / Địa danh trọng điểm tại Việt Nam (Tối ưu tốc độ 0ms)
  static final List<SearchPlace> _vietnamKeyLandmarks = [
    SearchPlace(
      name: 'Nguyễn Cảnh Dị (Định Công)',
      description: 'Phố Nguyễn Cảnh Dị, Phường Định Công, Quận Hoàng Mai, Hà Nội',
      location: const LatLng(20.9789, 105.8368),
      type: 'street',
    ),
    SearchPlace(
      name: 'Chung cư Smile Building',
      description: 'Số 1 Nguyễn Cảnh Dị, Phường Định Công, Hoàng Mai, Hà Nội',
      location: const LatLng(20.9765, 105.8392),
      type: 'house',
    ),
    SearchPlace(
      name: 'Chung cư CT36B Định Công',
      description: 'Ngõ 177 Định Công, Phường Định Công, Hoàng Mai, Hà Nội',
      location: const LatLng(20.9812, 105.8354),
      type: 'house',
    ),
    SearchPlace(
      name: 'Chung cư A5 Đại Kim',
      description: 'Khu đô thị Đại Kim, Hoàng Mai, Hà Nội',
      location: const LatLng(20.9734, 105.8321),
      type: 'house',
    ),
    SearchPlace(
      name: 'Đầm Đỗi (Định Công)',
      description: 'Phường Định Công, Quận Hoàng Mai, Hà Nội',
      location: const LatLng(20.9772, 105.8425),
      type: 'place',
    ),
    SearchPlace(
      name: 'Sông Sét',
      description: 'Đường Nguyễn Cảnh Dị - Trương Định, Hoàng Mai, Hà Nội',
      location: const LatLng(20.9820, 105.8385),
      type: 'place',
    ),
    SearchPlace(
      name: 'Hồ Hoàn Kiếm (Hồ Gươm)',
      description: 'Phường Hàng Trống, Quận Hoàn Kiếm, Hà Nội',
      location: const LatLng(21.0287, 105.8524),
      type: 'tourism',
    ),
    SearchPlace(
      name: 'Sân bay Quốc tế Nội Bài',
      description: 'Xã Phú Cường, Huyện Sóc Sơn, Hà Nội',
      location: const LatLng(21.2212, 105.8072),
      type: 'airport',
    ),
    SearchPlace(
      name: 'Chợ Bến Thành',
      description: 'Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
      location: const LatLng(10.7725, 106.6980),
      type: 'tourism',
    ),
    SearchPlace(
      name: 'Landmark 81',
      description: '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP. Hồ Chí Minh',
      location: const LatLng(10.7950, 106.7218),
      type: 'house',
    ),
    SearchPlace(
      name: 'Sân bay Quốc tế Tân Sơn Nhất',
      description: 'Đường Trường Sơn, Phường 2, Tân Bình, TP. Hồ Chí Minh',
      location: const LatLng(10.8185, 106.6588),
      type: 'airport',
    ),
    SearchPlace(
      name: 'Cầu Rồng Đà Nẵng',
      description: 'Đường Nguyễn Văn Linh, Phước Ninh, Hải Châu, Đà Nẵng',
      location: const LatLng(16.0610, 108.2272),
      type: 'tourism',
    ),
    SearchPlace(
      name: 'Keangnam Hanoi Landmark Tower',
      description: 'Khu E6 Đô thị mới Cầu Giấy, Mễ Trì, Nam Từ Liêm, Hà Nội',
      location: const LatLng(21.0167, 105.7836),
      type: 'house',
    ),
    SearchPlace(
      name: 'Aeon Mall Hà Đông',
      description: 'Phường Dương Nội, Quận Hà Đông, Hà Nội',
      location: const LatLng(20.9787, 105.7485),
      type: 'restaurant',
    ),
    SearchPlace(
      name: 'Aeon Mall Long Biên',
      description: 'Số 27 Cổ Linh, Long Biên, Hà Nội',
      location: const LatLng(21.0264, 105.9015),
      type: 'restaurant',
    ),
  ];

  /// Xóa dấu tiếng Việt để tìm kiếm không dấu mượt mà
  static String removeDiacritics(String str) {
    var withDiacritics = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
    var withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str.toLowerCase();
  }

  /// Tìm kiếm địa điểm đa tầng (Tọa độ -> POI Nội bộ -> Photon API -> Nominatim API)
  Future<List<SearchPlace>> searchPlaces(String query, {LatLng? userLocation}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final List<SearchPlace> results = [];

    // 1. Kiểm tra Tọa độ GPS (DD hoặc DMS)
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

    // 2. So khớp nhanh trong danh mục POI Việt Nam
    final normalizedQuery = removeDiacritics(cleanQuery);
    for (final landmark in _vietnamKeyLandmarks) {
      final nameNorm = removeDiacritics(landmark.name);
      final descNorm = removeDiacritics(landmark.description);
      if (nameNorm.contains(normalizedQuery) || descNorm.contains(normalizedQuery)) {
        if (!results.any((r) => r.name == landmark.name)) {
          results.add(landmark);
        }
      }
    }

    // 3. Tìm kiếm trực tuyến qua Photon Engine (OpenStreetMap data)
    try {
      String urlStr = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=10';
      if (userLocation != null) {
        urlStr += '&lat=${userLocation.latitude}&lon=${userLocation.longitude}';
      }

      final response = await http
          .get(Uri.parse(urlStr))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final features = data['features'] as List? ?? [];

        for (final item in features) {
          final place = SearchPlace.fromPhotonJson(item as Map<String, dynamic>);
          if (place.name.isNotEmpty && !results.any((r) => r.name == place.name)) {
            results.add(place);
          }
        }
      }
    } catch (_) {}

    // 4. Nếu kết quả ít, thử tìm bổ sung bằng Nominatim OpenStreetMap (Việt Nam)
    if (results.length < 3) {
      try {
        final nomUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&countrycodes=vn&format=json&limit=6&addressdetails=1';
        final response = await http
            .get(
              Uri.parse(nomUrl),
              headers: {
                'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
              },
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List list = jsonDecode(utf8.decode(response.bodyBytes));
          for (final item in list) {
            final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0;
            final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0;
            final name = item['name'] ?? item['display_name']?.split(',').first ?? 'Địa điểm';
            if (!results.any((r) => r.name == name)) {
              results.add(
                SearchPlace(
                  name: name,
                  description: item['display_name'] ?? '',
                  location: LatLng(lat, lon),
                  type: item['type'] ?? 'place',
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    return results;
  }
}
