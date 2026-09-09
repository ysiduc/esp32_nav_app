import 'package:latlong2/latlong.dart';

class CoordinateParser {
  /// Phân tích chuỗi tìm kiếm xem có phải là tọa độ GPS (DD hoặc DMS) không
  static LatLng? parse(String input) {
    input = input.trim();
    if (input.isEmpty) return null;

    // 1. Thử dạng Thập phân đơn giản (Decimal Degrees): "21.0285, 105.8544" hoặc "21.0285 105.8544"
    final ddRegex = RegExp(r'^([+-]?\d+(?:\.\d+)?)[,\s]+([+-]?\d+(?:\.\d+)?)$');
    final ddMatch = ddRegex.firstMatch(input);
    if (ddMatch != null) {
      final lat = double.tryParse(ddMatch.group(1)!);
      final lng = double.tryParse(ddMatch.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return LatLng(lat, lng);
      }
    }

    // 2. Thử dạng Độ-Phút-Giây (DMS): vd "20°58'48.9\"N 105°50'59.8\"E" hoặc "20 58 48.9 N 105 50 59.8 E"
    final dmsRegex = RegExp(
      r'(\d+)[°\s]+(\d+)[\x27\x22\s\x60]*(\d+(?:\.\d+)?)?[\x27\x22\s]*([NSEWnsew])[,\s]+(\d+)[°\s]+(\d+)[\x27\x22\s\x60]*(\d+(?:\.\d+)?)?[\x27\x22\s]*([NSEWnsew])',
      caseSensitive: false,
    );
    final dmsMatch = dmsRegex.firstMatch(input);
    if (dmsMatch != null) {
      final latDeg = double.tryParse(dmsMatch.group(1)!) ?? 0;
      final latMin = double.tryParse(dmsMatch.group(2)!) ?? 0;
      final latSec = double.tryParse(dmsMatch.group(3) ?? '0') ?? 0;
      final latDir = dmsMatch.group(4)!.toUpperCase();

      final lngDeg = double.tryParse(dmsMatch.group(5)!) ?? 0;
      final lngMin = double.tryParse(dmsMatch.group(6)!) ?? 0;
      final lngSec = double.tryParse(dmsMatch.group(7) ?? '0') ?? 0;
      final lngDir = dmsMatch.group(8)!.toUpperCase();

      double lat = latDeg + (latMin / 60.0) + (latSec / 3600.0);
      if (latDir == 'S') lat = -lat;

      double lng = lngDeg + (lngMin / 60.0) + (lngSec / 3600.0);
      if (lngDir == 'W') lng = -lng;

      if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return LatLng(lat, lng);
      }
    }

    return null;
  }
}
