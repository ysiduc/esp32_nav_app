import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  activeNavigation // Dẫn đường trực tiếp Turn-by-Turn
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

  String _destinationName = 'Hồ Hoàn Kiếm, Hà Nội';
  String get destinationName => _destinationName;

  List<RouteData> _routes = [];
  List<RouteData> get routes => _routes;

  int _selectedRouteIndex = 0;
  int get selectedRouteIndex => _selectedRouteIndex;

  RouteData? get currentRoute => _routes.isNotEmpty && _selectedRouteIndex < _routes.length
      ? _routes[_selectedRouteIndex]
      : null;

  AppUiMode _uiMode = AppUiMode.explore;
  AppUiMode get uiMode => _uiMode;

  TransportMode _transportMode = TransportMode.driving;
  TransportMode get transportMode => _transportMode;

  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  NavStep? get currentStep {
    if (currentRoute == null || currentRoute!.steps.isEmpty) return null;
    if (_currentStepIndex < currentRoute!.steps.length) {
      return currentRoute!.steps[_currentStepIndex];
    }
    return currentRoute!.steps.last;
  }

  double _distanceToNextStep = 10.0;
  double get distanceToNextStep => _distanceToNextStep;

  double _currentSpeedKmh = 0.0;
  double get currentSpeedKmh => _currentSpeedKmh;

  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;

  bool _isLoadingRoute = false;
  bool get isLoadingRoute => _isLoadingRoute;

  String? _lastSentPayload;
  String? get lastSentPayload => _lastSentPayload;

  MapLayerType _currentMapLayer = MapLayerType.osmStandard;
  MapLayerType get currentMapLayer => _currentMapLayer;

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
    final loc = await _locationService.getCurrentLocation();
    if (loc != null) {
      _userLocation = loc;
    } else {
      _userLocation = const LatLng(21.0285, 105.8542); // Hà Nội mặc định
    }
    notifyListeners();

    _bleService.lastPayloadStream.listen((payload) {
      _lastSentPayload = payload;
      notifyListeners();
    });
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

    final start = _userLocation ?? const LatLng(21.0285, 105.8542);
    final end = _destination ?? const LatLng(20.9789, 105.8368);

    _isLoadingRoute = true;
    notifyListeners();

    final fetchedRoutes = await _osrmService.getRoutes(start: start, destination: end);
    if (fetchedRoutes.isNotEmpty) {
      _routes = fetchedRoutes;
      _selectedRouteIndex = 0;
    }
    _currentStepIndex = 0;
    _isLoadingRoute = false;
    notifyListeners();

    if (_bleService.isConnected && currentRoute != null) {
      final points = currentRoute!.generateNormalizedPolyline();
      await _bleService.sendVectorMap(points);
    }
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
