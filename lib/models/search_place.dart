import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class SearchPlace {
  final String name;
  final String description;
  final LatLng location;
  final String type; // city, street, house, amenity, etc.

  SearchPlace({
    required this.name,
    required this.description,
    required this.location,
    this.type = 'place',
  });

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
      case 'administrative':
        return Icons.location_city_rounded;
      case 'street':
      case 'highway':
        return Icons.alt_route_rounded;
      case 'restaurant':
      case 'cafe':
      case 'fast_food':
        return Icons.restaurant_rounded;
      case 'hotel':
      case 'lodging':
        return Icons.hotel_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'hospital':
      case 'pharmacy':
        return Icons.local_hospital_rounded;
      case 'bank':
      case 'atm':
        return Icons.account_balance_rounded;
      case 'aerodrome':
      case 'airport':
        return Icons.flight_rounded;
      case 'station':
      case 'bus_stop':
        return Icons.directions_bus_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  factory SearchPlace.fromPhotonJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geometry['coordinates'] as List? ?? [0.0, 0.0];

    final double lng = (coords[0] as num).toDouble();
    final double lat = (coords[1] as num).toDouble();

    final String name = properties['name'] ?? properties['street'] ?? properties['city'] ?? 'Địa điểm';

    final List<String> addressParts = [];
    if (properties['housenumber'] != null) addressParts.add('${properties['housenumber']}');
    if (properties['street'] != null && properties['street'] != name) addressParts.add('${properties['street']}');
    if (properties['district'] != null) addressParts.add('${properties['district']}');
    if (properties['city'] != null && properties['city'] != name) addressParts.add('${properties['city']}');
    if (properties['state'] != null && properties['state'] != properties['city']) addressParts.add('${properties['state']}');
    if (properties['country'] != null) addressParts.add('${properties['country']}');

    final String description = addressParts.isNotEmpty ? addressParts.join(', ') : (properties['country'] ?? '');
    final String type = properties['type'] ?? properties['osm_value'] ?? 'place';

    return SearchPlace(
      name: name,
      description: description,
      location: LatLng(lat, lng),
      type: type,
    );
  }
}
