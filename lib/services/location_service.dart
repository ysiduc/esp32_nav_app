import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng defaultLocation = LatLng(21.028511, 105.854444); // Hà Nội

  /// Kiểm tra và xin cấp quyền vị trí GPS
  Future<bool> handlePermission() async {
    try {
      if (!kIsWeb && Platform.isLinux) {
        // Trên Linux desktop thường không có phần cứng GPS, bỏ qua kiểm tra nghiêm ngặt
        return true;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lấy vị trí GPS hiện tại (có fallback an toàn)
  Future<LatLng?> getCurrentLocation() async {
    try {
      if (!kIsWeb && Platform.isLinux) {
        return defaultLocation;
      }

      final hasPermission = await handlePermission();
      if (!hasPermission) return defaultLocation;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return defaultLocation;
    }
  }

  /// Lắng nghe luồng vị trí di chuyển theo thời gian thực
  Stream<Position> getPositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3, // Cập nhật mỗi 3 mét
        ),
      ).handleError((_) {});
    } catch (e) {
      return const Stream.empty();
    }
  }

  /// Tính khoảng cách giữa 2 tọa độ (mét)
  static double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}
