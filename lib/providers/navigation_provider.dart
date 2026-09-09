import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '../models/nav_step.dart';
import '../models/route_data.dart';
import '../models/search_place.dart';
import '../models/map_layer_type.dart';
import '../services/ble_service.dart';
import '../services/location_service.dart';
import '../services/osrm_service.dart';
import '../services/geocoding_service.dart';

enum AppUiMode {
  explore,         // Chế độ xem bản đồ & tìm kiếm Google Maps
  previewMap,      // Chế độ xem trước lộ trình (Directions)
  previewList,     // Danh sách chi tiết các chặng đường (Steps)
  activeNavigation // Dẫn đường trực tiếp Turn-by-Turn 3D
}

enum TransportMode {
  driving,    // Ô tô
  motorcycle, // Xe máy
  walking,    // Đi bộ
}

class NavigationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final OsrmService _osrmService = OsrmService();
  final BleService _bleService = BleService();
  final GeocodingService _geocodingService = GeocodingService();

  BleService get bleService => _bleService;

  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  LatLng? _destination;
  LatLng? get destination => _destination;

  final String _startAddressName = 'Vị trí của bạn';
  String get startAddressName => _startAddressName;

  String _destinationName = '280 Lê Văn Sỹ, Tân Bình';
  String get destinationName => _destinationName;

  List<RouteData> _routes = [];
  List<RouteData> get routes => _routes;

  int _selectedRouteIndex = 0;
  int get selectedRouteIndex => _selectedRouteIndex;

  RouteData? get currentRoute => _routes.isNotEmpty && _selectedRouteIndex < _routes.length
      ? _routes[_selectedRouteIndex]
      : null;

  AppUiMode _uiMode = AppUiMode.activeNavigation;
  AppUiMode get uiMode => _uiMode;

  TransportMode _transportMode = TransportMode.driving;
  TransportMode get transportMode => _transportMode;

  bool _is3DView = true;
  bool get is3DView => _is3DView;

  void toggle3DView() {
    _is3DView = !_is3DView;
    notifyListeners();
  }

  double _bearing = 0.0;
  double get bearing => _bearing;

  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  NavStep? get currentStep {
    if (currentRoute == null || currentRoute!.steps.isEmpty) return null;
    if (_currentStepIndex < currentRoute!.steps.length) {
      return currentRoute!.steps[_currentStepIndex];
    }
    return currentRoute!.steps.last;
  }

  double _distanceToNextStep = 250.0;
  double get distanceToNextStep => _distanceToNextStep;

  double _currentSpeedKmh = 40.0;
  double get currentSpeedKmh => _currentSpeedKmh;

  bool _isNavigating = true;
  bool get isNavigating => _isNavigating;

  bool _isLoadingRoute = false;
  bool get isLoadingRoute => _isLoadingRoute;

  String? _lastSentPayload;
  String? get lastSentPayload => _lastSentPayload;

  MapLayerType _currentMapLayer = MapLayerType.openFreeMapLiberty;
  MapLayerType get currentMapLayer => _currentMapLayer;

  Style? _mapStyle;
  Style? get mapStyle => _mapStyle;

  bool _isLoadingStyle = false;
  bool get isLoadingStyle => _isLoadingStyle;

  List<SearchPlace> _searchResults = [];
  List<SearchPlace> get searchResults => _searchResults;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _bleSyncTimer;
  Timer? _debounceTimer;

  NavigationProvider() {
    _init();
  }

  Future<void> _init() async {
    _loadOpenFreeMapStyle();

    final loc = await _locationService.getCurrentLocation();
    if (loc != null) {
      _userLocation = loc;
    } else {
      _userLocation = const LatLng(10.7915, 106.6668);
    }
    _destination = const LatLng(10.8035, 106.6640);
    _destinationName = 'Trạm xăng dầu 280 Lê Văn Sỹ';
    notifyListeners();

    await calculateRoute();

    _bleService.lastPayloadStream.listen((payload) {
      _lastSentPayload = payload;
      notifyListeners();
    });
  }

  Future<void> _loadOpenFreeMapStyle() async {
    _isLoadingStyle = true;
    notifyListeners();
    try {
      final style = await StyleReader(
        uri: _currentMapLayer.styleUrl,
        httpHeaders: {'User-Agent': 'ESP32NavApp/2.0'},
      ).read();
      _mapStyle = style;
    } catch (e) {
      debugPrint('OpenFreeMap style load error: $e');
    } finally {
      _isLoadingStyle = false;
      notifyListeners();
    }
  }

  void setUiMode(AppUiMode mode) {
    _uiMode = mode;
    notifyListeners();
  }

  void setTransportMode(TransportMode mode) {
    _transportMode = mode;
    notifyListeners();
    if (_destination != null) {
      calculateRoute();
    }
  }

  void selectRoute(int index) {
    if (index >= 0 && index < _routes.length) {
      _selectedRouteIndex = index;
      _currentStepIndex = 0;
      notifyListeners();
      if (_bleService.isConnected && currentRoute != null) {
        final points = currentRoute!.generateNormalizedPolyline();
        _bleService.sendVectorMap(points);
      }
    }
  }

  void setMapLayer(MapLayerType layer) {
    _currentMapLayer = layer;
    notifyListeners();
    _loadOpenFreeMapStyle();
  }

  void searchDestination(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _geocodingService.searchPlaces(query, userLocation: _userLocation);
      _searchResults = results;
      _isSearching = false;
      notifyListeners();
    });
  }

  void clearSearchResults() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  Future<void> selectSearchPlace(SearchPlace place) async {
    _destination = place.location;
    _destinationName = place.name;
    _searchResults = [];
    _isSearching = false;
    _uiMode = AppUiMode.previewMap;
    notifyListeners();
    await calculateRoute();
  }

  Future<void> setDestination(LatLng dest, {String? name}) async {
    _destination = dest;
    _destinationName = name ?? 'Điểm đã chọn trên bản đồ';
    _uiMode = AppUiMode.previewMap;
    notifyListeners();
    await calculateRoute();
  }

  Future<void> calculateRoute() async {
    if (_userLocation == null && _destination == null) return;

    final start = _userLocation ?? const LatLng(10.7915, 106.6668);
    final end = _destination ?? const LatLng(10.8035, 106.6640);

    _isLoadingRoute = true;
    notifyListeners();

    final fetchedRoutes = await _osrmService.getRoutes(start: start, destination: end);
    if (fetchedRoutes.isNotEmpty) {
      _routes = fetchedRoutes;
      _selectedRouteIndex = 0;
      _calculateInitialBearing();
    }
    _currentStepIndex = 0;
    _isLoadingRoute = false;
    notifyListeners();

    if (_bleService.isConnected && currentRoute != null) {
      final points = currentRoute!.generateNormalizedPolyline();
      await _bleService.sendVectorMap(points);
    }
  }

  void _calculateInitialBearing() {
    if (currentRoute != null && currentRoute!.polyline.length > 1) {
      final p1 = currentRoute!.polyline[0];
      final p2 = currentRoute!.polyline[1];
      _bearing = _computeBearing(p1, p2);
    }
  }

  double _computeBearing(LatLng start, LatLng end) {
    final lat1 = start.latitudeInRad;
    final lat2 = end.latitudeInRad;
    final dLon = (end.longitude - start.longitude) * (math.pi / 180.0);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final rad = math.atan2(y, x);
    return (rad * (180.0 / math.pi) + 360.0) % 360.0;
  }

  void startNavigation() {
    if (currentRoute == null || currentRoute!.steps.isEmpty) return;

    _isNavigating = true;
    _uiMode = AppUiMode.activeNavigation;
    _currentStepIndex = 0;
    notifyListeners();

    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((pos) {
      _userLocation = LatLng(pos.latitude, pos.longitude);
      _currentSpeedKmh = (pos.speed * 3.6).clamp(0, 200);
      if (pos.heading > 0) {
        _bearing = pos.heading;
      }

      _updateNavigationStep();
      notifyListeners();
    });

    _bleSyncTimer?.cancel();
    _bleSyncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncNavToEsp32();
    });
  }

  void stopNavigation() {
    _isNavigating = false;
    _uiMode = AppUiMode.explore;
    _positionSubscription?.cancel();
    _bleSyncTimer?.cancel();
    notifyListeners();
  }

  void _updateNavigationStep() {
    if (currentRoute == null || _userLocation == null) return;
    if (_currentStepIndex >= currentRoute!.steps.length) return;

    final targetStep = currentRoute!.steps[_currentStepIndex];
    final dist = LocationService.calculateDistance(_userLocation!, targetStep.location);
    _distanceToNextStep = dist;

    if (dist < 15 && _currentStepIndex < currentRoute!.steps.length - 1) {
      _currentStepIndex++;
      _distanceToNextStep = LocationService.calculateDistance(
        _userLocation!,
        currentRoute!.steps[_currentStepIndex].location,
      );
    }
  }

  void _syncNavToEsp32() {
    if (!_bleService.isConnected || !_isNavigating || currentStep == null) return;

    _bleService.sendNavigationPacket(
      turnCode: currentStep!.esp32TurnCode,
      distMeters: _distanceToNextStep,
      streetName: currentStep!.streetName,
      speedKmh: _currentSpeedKmh,
      remainDistanceMeters: currentRoute?.totalDistanceMeters ?? 0,
      remainDurationSeconds: currentRoute?.totalDurationSeconds ?? 0,
    );
  }

  Future<void> sendMapVectorToEsp32() async {
    if (currentRoute == null) return;
    final points = currentRoute!.generateNormalizedPolyline();
    await _bleService.sendVectorMap(points);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _positionSubscription?.cancel();
    _bleSyncTimer?.cancel();
    super.dispose();
  }
}
