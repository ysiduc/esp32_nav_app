import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/nav_step.dart';
import '../models/route_data.dart';

class OsrmService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Tính toán lộ trình từ start -> destination qua OSRM API
  Future<RouteData?> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
        return null;
      }

      final route = data['routes'][0];
      final double totalDistance = (route['distance'] as num).toDouble();
      final double totalDuration = (route['duration'] as num).toDouble();

      // Bóc tách mảng tọa độ Polyline (GeoJSON format: [longitude, latitude])
      final coordsList = route['geometry']['coordinates'] as List;
      final List<LatLng> polylinePoints = coordsList.map((coord) {
        return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
      }).toList();

      // Bóc tách các bước rẽ (Turn-by-turn steps)
      final List<NavStep> steps = [];
      final legs = route['legs'] as List;
      for (final leg in legs) {
        final legSteps = leg['steps'] as List;
        for (final step in legSteps) {
          final maneuver = step['maneuver'];
          final String mType = maneuver['type'] ?? 'turn';
          final String? modifier = maneuver['modifier'];
          final locationArr = maneuver['location'] as List;
          final stepLoc = LatLng(
            (locationArr[1] as num).toDouble(),
            (locationArr[0] as num).toDouble(),
          );

          String street = step['name'] ?? '';
          if (street.isEmpty) {
            street = 'Đường không tên';
          }

          final mParsed = NavStep.parseManeuver(mType, modifier);

          // Tạo câu hướng dẫn thân thiện tiếng Việt
          String instruction = _generateInstruction(mParsed, street);

          steps.add(
            NavStep(
              instruction: instruction,
              streetName: street,
              distanceMeters: (step['distance'] as num).toDouble(),
              durationSeconds: (step['duration'] as num).toDouble(),
              maneuverType: mParsed,
              location: stepLoc,
              modifier: modifier,
            ),
          );
        }
      }

      return RouteData(
        polyline: polylinePoints,
        steps: steps,
        totalDistanceMeters: totalDistance,
        totalDurationSeconds: totalDuration,
        startLocation: start,
        destinationLocation: destination,
      );
    } catch (e) {
      return null;
    }
  }

  static String _generateInstruction(ManeuverType type, String street) {
    switch (type) {
      case ManeuverType.depart:
        return 'Bắt đầu di chuyển trên $street';
      case ManeuverType.straight:
        return 'Đi thẳng trên $street';
      case ManeuverType.slightLeft:
        return 'Chếch sang trái vào $street';
      case ManeuverType.turnLeft:
        return 'Rẽ trái vào $street';
      case ManeuverType.sharpLeft:
        return 'Rẽ ngoặt sang trái vào $street';
      case ManeuverType.slightRight:
        return 'Chếch sang phải vào $street';
      case ManeuverType.turnRight:
        return 'Rẽ phải vào $street';
      case ManeuverType.sharpRight:
        return 'Rẽ ngoặt sang phải vào $street';
      case ManeuverType.uTurn:
        return 'Quay đầu lại trên $street';
      case ManeuverType.roundabout:
        return 'Vào bùng binh ra hướng $street';
      case ManeuverType.arrive:
        return 'Bạn đã đến điểm đích!';
      case ManeuverType.unknown:
        return 'Tiếp tục đi trên $street';
    }
  }
}
