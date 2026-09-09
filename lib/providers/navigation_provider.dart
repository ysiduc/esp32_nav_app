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

  String? _destinationName;
  String? get destinationName => _destinationName;

  RouteData? _currentRoute;
  RouteData? get currentRoute => _currentRoute;

  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  NavStep? get currentStep {
    if (_currentRoute == null || _currentRoute!.steps.isEmpty) return null;
    if (_currentStepIndex < _currentRoute!.steps.length) {
      return _currentRoute!.steps[_currentStepIndex];
    }
    return _currentRoute!.steps.last;
  }

  double _distanceToNextStep = 0.0;
  double get distanceToNextStep => _distanceToNextStep;

  double _currentSpeedKmh = 0.0;
  double get currentSpeedKmh => _currentSpeedKmh;

  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;

  bool _isLoadingRoute = false;
  bool get isLoadingRoute => _isLoadingRoute;

  String? _lastSentPayload;
  String? get lastSentPayload => _lastSentPayload;

  // Lớp bản đồ hiện tại (mặc định Dark OSM - 0 Watermark)
  MapLayerType _currentMapLayer = MapLayerType.darkOSM;
  MapLayerType get currentMapLayer => _currentMapLayer;

  // Quản lý tìm kiếm
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
      notifyListeners();
    }

    _bleService.lastPayloadStream.listen((payload) {
      _lastSentPayload = payload;
      notifyListeners();
    });
  }

  /// Đổi Lớp Bản đồ (Dark OSM, Standard, HOT, Esri Street, Satellite...)
  void setMapLayer(MapLayerType layer) {
    _currentMapLayer = layer;
    notifyListeners();
  }

  /// Tìm kiếm địa điểm với Debounce
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

  /// Chọn địa điểm từ kết quả tìm kiếm
  Future<void> selectSearchPlace(SearchPlace place) async {
    _destination = place.location;
    _destinationName = place.name;
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
    await calculateRoute();
  }

  /// Cập nhật điểm đến khi chạm trực tiếp trên bản đồ
  Future<void> setDestination(LatLng dest, {String? name}) async {
    _destination = dest;
    _destinationName = name ?? 'Điểm đã chọn trên bản đồ';
    notifyListeners();
    await calculateRoute();
  }

  /// Tính toán lộ trình từ vị trí hiện tại đến điểm đến
  Future<void> calculateRoute() async {
    if (_userLocation == null && _destination == null) return;

    final start = _userLocation ?? const LatLng(21.028511, 105.854444);
    final end = _destination ?? const LatLng(21.0368, 105.8346);

    _isLoadingRoute = true;
    notifyListeners();

    final route = await _osrmService.getRoute(start: start, destination: end);
    _currentRoute = route;
    _currentStepIndex = 0;
    _isLoadingRoute = false;
    notifyListeners();

    // Nếu đã kết nối ESP32, tự động gửi bản đồ vector Polyline sang ESP32
    if (_bleService.isConnected && _currentRoute != null) {
      final points = _currentRoute!.generateNormalizedPolyline();
      await _bleService.sendVectorMap(points);
    }
  }

  /// Bắt đầu chế độ dẫn đường Turn-by-Turn
  void startNavigation() {
    if (_currentRoute == null || _currentRoute!.steps.isEmpty) return;

    _isNavigating = true;
    _currentStepIndex = 0;
    notifyListeners();

    // Lắng nghe GPS thời gian thực
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((pos) {
      _userLocation = LatLng(pos.latitude, pos.longitude);
      _currentSpeedKmh = (pos.speed * 3.6).clamp(0, 200);

      _updateNavigationStep();
      notifyListeners();
    });

    // Định kỳ 1 giây gửi gói tin chỉ đường sang ESP32
    _bleSyncTimer?.cancel();
    _bleSyncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncNavToEsp32();
    });
  }

  /// Hủy dẫn đường
  void stopNavigation() {
    _isNavigating = false;
    _positionSubscription?.cancel();
    _bleSyncTimer?.cancel();
    notifyListeners();
  }

  /// Cập nhật bước rẽ tiếp theo dựa trên khoảng cách GPS
  void _updateNavigationStep() {
    if (_currentRoute == null || _userLocation == null) return;
    if (_currentStepIndex >= _currentRoute!.steps.length) return;

    final targetStep = _currentRoute!.steps[_currentStepIndex];
    final dist = LocationService.calculateDistance(_userLocation!, targetStep.location);
    _distanceToNextStep = dist;

    // Nếu người dùng đã đến gần khúc rẽ (< 15 mét), tự động chuyển sang bước rẽ tiếp theo
    if (dist < 15 && _currentStepIndex < _currentRoute!.steps.length - 1) {
      _currentStepIndex++;
      _distanceToNextStep = LocationService.calculateDistance(
        _userLocation!,
        _currentRoute!.steps[_currentStepIndex].location,
      );
    }
  }

  /// Đồng bộ gói tin sang ESP32 qua BLE
  void _syncNavToEsp32() {
    if (!_bleService.isConnected || !_isNavigating || currentStep == null) return;

    _bleService.sendNavigationPacket(
      turnCode: currentStep!.esp32TurnCode,
      distMeters: _distanceToNextStep,
      streetName: currentStep!.streetName,
      speedKmh: _currentSpeedKmh,
      remainDistanceMeters: _currentRoute?.totalDistanceMeters ?? 0,
      remainDurationSeconds: _currentRoute?.totalDurationSeconds ?? 0,
    );
  }

  /// Gửi thủ công bản đồ vector sang ESP32
  Future<void> sendMapVectorToEsp32() async {
    if (_currentRoute == null) return;
    final points = _currentRoute!.generateNormalizedPolyline();
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
