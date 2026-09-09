import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum ManeuverType {
  depart,
  straight,
  slightLeft,
  turnLeft,
  sharpLeft,
  slightRight,
  turnRight,
  sharpRight,
  uTurn,
  roundabout,
  arrive,
  unknown,
}

class NavStep {
  final String instruction;
  final String streetName;
  final double distanceMeters;
  final double durationSeconds;
  final ManeuverType maneuverType;
  final LatLng location;
  final String? modifier;

  NavStep({
    required this.instruction,
    required this.streetName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    required this.location,
    this.modifier,
  });

  /// Map maneuver type to integer code for ESP32 packet
  /// 0: Straight, 1: Slight Left, 2: Left, 3: Sharp Left
  /// 4: Slight Right, 5: Right, 6: Sharp Right
  /// 7: U-Turn, 8: Roundabout, 9: Arrive/Destination, 10: Depart/Start
  int get esp32TurnCode {
    switch (maneuverType) {
      case ManeuverType.straight:
        return 0;
      case ManeuverType.slightLeft:
        return 1;
      case ManeuverType.turnLeft:
        return 2;
      case ManeuverType.sharpLeft:
        return 3;
      case ManeuverType.slightRight:
        return 4;
      case ManeuverType.turnRight:
        return 5;
      case ManeuverType.sharpRight:
        return 6;
      case ManeuverType.uTurn:
        return 7;
      case ManeuverType.roundabout:
        return 8;
      case ManeuverType.arrive:
        return 9;
      case ManeuverType.depart:
        return 10;
      case ManeuverType.unknown:
        return 0;
    }
  }

  IconData get icon {
    switch (maneuverType) {
      case ManeuverType.depart:
        return Icons.trip_origin_rounded;
      case ManeuverType.straight:
        return Icons.straight_rounded;
      case ManeuverType.slightLeft:
        return Icons.turn_slight_left_rounded;
      case ManeuverType.turnLeft:
        return Icons.turn_left_rounded;
      case ManeuverType.sharpLeft:
        return Icons.turn_sharp_left_rounded;
      case ManeuverType.slightRight:
        return Icons.turn_slight_right_rounded;
      case ManeuverType.turnRight:
        return Icons.turn_right_rounded;
      case ManeuverType.sharpRight:
        return Icons.turn_sharp_right_rounded;
      case ManeuverType.uTurn:
        return Icons.u_turn_left_rounded;
      case ManeuverType.roundabout:
        return Icons.roundabout_left_rounded;
      case ManeuverType.arrive:
        return Icons.flag_rounded;
      case ManeuverType.unknown:
        return Icons.navigation_rounded;
    }
  }

  static ManeuverType parseManeuver(String type, String? modifier) {
    if (type == 'depart') return ManeuverType.depart;
    if (type == 'arrive') return ManeuverType.arrive;
    if (type == 'roundabout' || type == 'rotary') return ManeuverType.roundabout;

    if (modifier != null) {
      switch (modifier) {
        case 'slight left':
          return ManeuverType.slightLeft;
        case 'left':
          return ManeuverType.turnLeft;
        case 'sharp left':
          return ManeuverType.sharpLeft;
        case 'slight right':
          return ManeuverType.slightRight;
        case 'right':
          return ManeuverType.turnRight;
        case 'sharp right':
          return ManeuverType.sharpRight;
        case 'uturn':
          return ManeuverType.uTurn;
        case 'straight':
          return ManeuverType.straight;
      }
    }

    if (type == 'turn') {
      return ManeuverType.turnRight;
    }
    return ManeuverType.straight;
  }
}
