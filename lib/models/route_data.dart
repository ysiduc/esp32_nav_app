import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'nav_step.dart';

class Point2D {
  final int x;
  final int y;
  Point2D(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class RouteData {
  final List<LatLng> polyline;
  final List<NavStep> steps;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final LatLng startLocation;
  final LatLng destinationLocation;
  final String viaRoadName;
  final int routeIndex;

  RouteData({
    required this.polyline,
    required this.steps,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.startLocation,
    required this.destinationLocation,
    this.viaRoadName = 'Qua CT. Đại lộ Thăng Long Hà Nội',
    this.routeIndex = 0,
  });

  /// Giờ đến nơi dự kiến (ETA) dạng 21:25
  String get arrivalTimeFormatted {
    final eta = DateTime.now().add(Duration(seconds: totalDurationSeconds.round()));
    return DateFormat('HH:mm').format(eta);
  }

  /// Thời gian hiển thị ngắn dạng "1h 11p" hoặc "14p"
  String get shortDurationFormatted {
    final totalMinutes = (totalDurationSeconds / 60).round();
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return '${hours}h ${mins}p';
    }
    return '${totalMinutes}p';
  }

  /// Thời gian hiển thị đầy đủ dạng "1 giờ 11 phút" hoặc "14 phút"
  String get fullDurationFormatted {
    final totalMinutes = (totalDurationSeconds / 60).round();
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return '$hours giờ $mins phút';
    }
    return '$totalMinutes phút';
  }

  /// Khoảng cách chuẩn hóa dạng "41,4 km" hoặc "350 m"
  String get formattedTotalDistance {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    return '${totalDistanceMeters.round()} m';
  }

  /// Thông tin tóm tắt dạng "1:11 h • 41 km"
  String get durationAndDistanceFormatted {
    final totalMinutes = (totalDurationSeconds / 60).round();
    String durStr;
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      durStr = '$hours:${mins.toString().padLeft(2, '0')} h';
    } else {
      durStr = '$totalMinutes phút';
    }

    String distStr;
    if (totalDistanceMeters >= 1000) {
      distStr = '${(totalDistanceMeters / 1000).toStringAsFixed(0)} km';
    } else {
      distStr = '${totalDistanceMeters.round()} m';
    }

    return '$durStr  •  $distStr';
  }

  /// Nén và chuẩn hóa Polyline thành danh sách điểm (x, y) kích thước width x height cho ESP32
  List<Point2D> generateNormalizedPolyline({
    int width = 120,
    int height = 56,
    int maxPoints = 40,
  }) {
    if (polyline.isEmpty) return [];

    final step = (polyline.length / maxPoints).ceil().clamp(1, 9999);
    final sampled = <LatLng>[];
    for (int i = 0; i < polyline.length; i += step) {
      sampled.add(polyline[i]);
    }
    if (sampled.last != polyline.last) {
      sampled.add(polyline.last);
    }

    double minLat = sampled.first.latitude;
    double maxLat = sampled.first.latitude;
    double minLng = sampled.first.longitude;
    double maxLng = sampled.first.longitude;

    for (final pt in sampled) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    final latRange = (maxLat - minLat == 0) ? 0.0001 : (maxLat - minLat);
    final lngRange = (maxLng - minLng == 0) ? 0.0001 : (maxLng - minLng);

    return sampled.map((pt) {
      final normX = ((pt.longitude - minLng) / lngRange * (width - 4)).round() + 2;
      final normY = height - 2 - ((pt.latitude - minLat) / latRange * (height - 4)).round();
      return Point2D(normX.clamp(0, width), normY.clamp(0, height));
    }).toList();
  }
}
