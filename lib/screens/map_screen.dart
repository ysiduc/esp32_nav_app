import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'ble_devices_screen.dart';
import 'esp32_simulator_screen.dart';
import 'ancs_guide_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final userPos = nav.userLocation ?? const LatLng(21.028511, 105.854444);

    return Scaffold(
      body: Stack(
        children: [
          // 1. OPENSTREETMAP TILE LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                if (!nav.isNavigating) {
                  nav.setDestination(point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isDarkMode
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.esp32nav.app',
              ),
              // Polyline Lộ trình
              if (nav.currentRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: nav.currentRoute!.polyline,
                      strokeWidth: 6.0,
                      color: const Color(0xFF00E5FF),
                    ),
                  ],
                ),
              // Marker Vị trí & Điểm đến
              MarkerLayer(
                markers: [
                  // Vị trí người dùng
                  Marker(
                    point: userPos,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.navigation_rounded, color: Color(0xFF00E5FF), size: 28),
                      ),
                    ),
                  ),
                  // Điểm đến
                  if (nav.destination != null)
                    Marker(
                      point: nav.destination!,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // 2. THANH CÔNG CỤ TRÊN CÙNG (TOP HEADER)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Nút BLE Status & Scanner
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BleDevicesScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: nav.bleService.isConnected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            nav.bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            nav.bleService.isConnected ? 'ESP32 Online' : 'Kết nối BLE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Nút Giả lập ESP32 HUD
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                    icon: const Icon(Icons.developer_board_rounded, color: Colors.cyanAccent),
                    tooltip: 'Mô phỏng Màn hình ESP32',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Esp32SimulatorScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Nút Hướng dẫn ANCS (Call/SMS)
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                    icon: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                    tooltip: 'Hướng dẫn Cuộc gọi/SMS ANCS',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AncsGuideScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Đổi Theme Bản đồ Sáng/Tối
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                    icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. CARD CHỈ ĐƯỜNG TRỰC TIẾP (TURN-BY-TURN HUD) KHI ĐANG DẪN ĐƯỜNG
          if (nav.isNavigating && nav.currentStep != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withAlpha(235),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E5FF).withAlpha(80)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        nav.currentStep!.icon,
                        color: const Color(0xFF00E5FF),
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nav.distanceToNextStep >= 1000
                                ? '${(nav.distanceToNextStep / 1000).toStringAsFixed(1)} km'
                                : '${nav.distanceToNextStep.round()} m',
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            nav.currentStep!.instruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. HUD TỐC ĐỘ (SPEED GAUGE)
          if (nav.isNavigating)
            Positioned(
              bottom: 180,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withAlpha(220),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Text(
                      '${nav.currentSpeedKmh.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // 5. THANH ĐIỀU KHIỂN DƯỚI CÙNG (BOTTOM NAVIGATION SHEET)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 20, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nav.isLoadingRoute)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    )
                  else if (nav.currentRoute != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng quãng đường', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            Text(
                              nav.currentRoute!.formattedTotalDistance,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Thời gian dự kiến', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            Text(
                              nav.currentRoute!.formattedDuration,
                              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Nút Gửi Bản Đồ Sang ESP32
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00E5FF),
                              side: const BorderSide(color: Color(0xFF00E5FF)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('Gửi Bản Đồ ESP32', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              nav.sendMapVectorToEsp32();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã gửi bản đồ lộ trình vector sang ESP32!')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nút Bắt đầu / Dừng dẫn đường
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: nav.isNavigating ? Colors.redAccent : const Color(0xFF00E5FF),
                              foregroundColor: nav.isNavigating ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: Icon(nav.isNavigating ? Icons.stop_rounded : Icons.navigation_rounded),
                            label: Text(
                              nav.isNavigating ? 'Dừng Lộ Trình' : 'Bắt Đầu',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            onPressed: () {
                              if (nav.isNavigating) {
                                nav.stopNavigation();
                              } else {
                                nav.startNavigation();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Color(0xFF00E5FF), size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Chạm vào bất kỳ điểm nào trên bản đồ để tạo lộ trình chỉ đường OSRM',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
