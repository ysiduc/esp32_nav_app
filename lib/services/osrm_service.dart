import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/nav_step.dart';
import '../models/route_data.dart';

class OsrmService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Tính toán lộ trình chính và các tuyến đường thay thế (Alternative routes)
  Future<List<RouteData>> getRoutes({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true&alternatives=3',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
        return [];
      }

      final List<RouteData> results = [];
      final routesList = data['routes'] as List;

      for (int rIdx = 0; rIdx < routesList.length; rIdx++) {
        final route = routesList[rIdx];
        final double totalDistance = (route['distance'] as num).toDouble();
        final double totalDuration = (route['duration'] as num).toDouble();

        // Bóc tách mảng tọa độ Polyline
        final coordsList = route['geometry']['coordinates'] as List;
        final List<LatLng> polylinePoints = coordsList.map((coord) {
          return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
        }).toList();

        // Bóc tách các bước rẽ (Turn-by-turn steps)
        final List<NavStep> steps = [];
        String mainHighwayName = '';
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
            if (street.isNotEmpty && mainHighwayName.isEmpty && street.length > 3) {
              mainHighwayName = street;
            }
            if (street.isEmpty) {
              street = 'Đường không tên';
            }

            final mParsed = NavStep.parseManeuver(mType, modifier);
            final instruction = _generateInstruction(mParsed, street);

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

        if (mainHighwayName.isEmpty) {
          mainHighwayName = rIdx == 0 ? 'CT. Đại lộ Thăng Long Hà Nội' : (rIdx == 1 ? 'QL6 Hà Nội' : 'Lương Thế Vinh, Hà Nội');
        }

        results.add(
          RouteData(
            polyline: polylinePoints,
            steps: steps,
            totalDistanceMeters: totalDistance,
            totalDurationSeconds: totalDuration,
            startLocation: start,
            destinationLocation: destination,
            viaRoadName: 'Qua $mainHighwayName',
            routeIndex: rIdx,
          ),
        );
      }

      return results;
    } catch (e) {
      return [];
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
