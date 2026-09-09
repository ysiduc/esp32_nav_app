import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/route_data.dart';

class BleService {
  static const String customServiceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String customCharUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;

  final _isScanningController = StreamController<bool>.broadcast();
  Stream<bool> get isScanningStream => _isScanningController.stream;

  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;

  final _lastPayloadController = StreamController<String>.broadcast();
  Stream<String> get lastPayloadStream => _lastPayloadController.stream;

  bool get isConnected => connectedDevice != null && writeCharacteristic != null;

  BleService() {
    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanningController.add(scanning);
    });
  }

  /// Bắt đầu quét thiết bị BLE
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    // Kiểm tra Bluetooth khả dụng
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      return;
    }

    await FlutterBluePlus.startScan(
      timeout: timeout,
    );
  }

  /// Dừng quét BLE
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// Kết nối tới thiết bị ESP32
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 8),
        autoConnect: false,
      );

      connectedDevice = device;

      // Lắng nghe trạng thái kết nối
      device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
          writeCharacteristic = null;
        }
      });

      // Yêu cầu MTU lớn hơn (để gửi chuỗi JSON dài)
      try {
        await device.requestMtu(247);
      } catch (_) {}

      // Tìm Custom Service & Characteristic để ghi dữ liệu
      final services = await device.discoverServices();
      for (final s in services) {
        final sUuid = s.uuid.toString().toLowerCase();
        if (sUuid.contains('ffe0') || sUuid.contains('6e400001')) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.toString().toLowerCase();
            if (cUuid.contains('ffe1') || cUuid.contains('6e400002') || c.properties.write || c.properties.writeWithoutResponse) {
              writeCharacteristic = c;
              break;
            }
          }
        }
      }

      // Nếu không khớp UUID trên, lấy characteristic hỗ trợ Write đầu tiên
      if (writeCharacteristic == null) {
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              writeCharacteristic = c;
              break;
            }
          }
          if (writeCharacteristic != null) break;
        }
      }

      return writeCharacteristic != null;
    } catch (e) {
      disconnect();
      return false;
    }
  }

  /// Ngắt kết nối
  Future<void> disconnect() async {
    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
      }
    } catch (_) {}
    connectedDevice = null;
    writeCharacteristic = null;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  /// Gửi gói tin chỉ đường thời gian thực sang ESP32
  Future<bool> sendNavigationPacket({
    required int turnCode,
    required double distMeters,
    required String streetName,
    required double speedKmh,
    required double remainDistanceMeters,
    required double remainDurationSeconds,
  }) async {
    if (writeCharacteristic == null) return false;

    try {
      // Chuẩn bị payload rút gọn dạng JSON
      final payload = jsonEncode({
        "t": turnCode,
        "d": distMeters.round(),
        "s": streetName,
        "v": speedKmh.round(),
        "rem": remainDistanceMeters.round(),
        "eta": (remainDurationSeconds / 60).round(),
      });

      _lastPayloadController.add(payload);

      final bytes = utf8.encode('$payload\n');
      await writeCharacteristic!.write(bytes, withoutResponse: writeCharacteristic!.properties.writeWithoutResponse);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gửi dữ liệu Polyline mini map rút gọn sang ESP32 để vẽ lộ trình
  Future<bool> sendVectorMap(List<Point2D> points) async {
    if (writeCharacteristic == null || points.isEmpty) return false;

    try {
      // Gửi danh sách điểm: "MAP:x1,y1,x2,y2..."
      final pointString = points.map((p) => '${p.x},${p.y}').join(';');
      final payload = 'MAP:$pointString\n';

      _lastPayloadController.add('Sent Map: ${points.length} points');

      final bytes = utf8.encode(payload);
      // Chia nhỏ thành các chunks 100 bytes nếu cần
      const chunkSize = 100;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        await writeCharacteristic!.write(chunk, withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
