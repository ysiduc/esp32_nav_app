import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../models/route_data.dart';

class Esp32SimulatorScreen extends StatefulWidget {
  const Esp32SimulatorScreen({super.key});

  @override
  State<Esp32SimulatorScreen> createState() => _Esp32SimulatorScreenState();
}

class _Esp32SimulatorScreenState extends State<Esp32SimulatorScreen> {
  bool _simulatedCall = false;
  final String _callerName = 'Mẹ (+84 912 345 678)';

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final step = nav.currentStep;
    final points = nav.currentRoute?.generateNormalizedPolyline(width: 120, height: 50) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text('Giả Lập Màn Hình ESP32', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GIAO DIỆN MÀN HÌNH OLED / TFT THỰC TẾ',
              style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            // Khung Màn Hình ESP32 (Mô phỏng OLED SSD1306 128x64 / ST7789)
            Center(
              child: Container(
                width: 320,
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155), width: 6),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00E5FF).withAlpha(30), blurRadius: 24, spreadRadius: 4),
                  ],
                ),
                child: _simulatedCall
                    // 1. GIAO DIỆN ANCS KHI CÓ CUỘC GỌI ĐẾN
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_in_talk_rounded, color: Colors.redAccent, size: 22),
                                SizedBox(width: 6),
                                Text(
                                  'INCOMING CALL (iOS)',
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _callerName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '[ Nhấn nút ESP32 để từ chối ]',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      )
                    // 2. GIAO DIỆN NAVIGATION + MINI VECTOR MAP
                    : Row(
                        children: [
                          // Cột trái: Hướng rẽ, Khoảng cách & Tốc độ
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      step?.icon ?? Icons.straight_rounded,
                                      color: const Color(0xFF00E5FF),
                                      size: 38,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      nav.distanceToNextStep >= 1000
                                          ? '${(nav.distanceToNextStep / 1000).toStringAsFixed(1)}km'
                                          : '${nav.distanceToNextStep.round()}m',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  step?.streetName ?? 'Chờ lộ trình...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${nav.currentSpeedKmh.round()} km/h',
                                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      nav.currentRoute?.formattedTotalDistance ?? '0 km',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const VerticalDivider(color: Colors.white24, width: 16),

                          // Cột phải: Bản đồ Vector Mini (Render từ danh sách Point2D)
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: points.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Mini Map',
                                        style: TextStyle(color: Colors.white24, fontSize: 10),
                                      ),
                                    )
                                  : CustomPaint(
                                      painter: MiniMapVectorPainter(points: points),
                                      child: Container(),
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // Các nút Test Giả Lập
            const Text(
              'BỘ ĐIỀU KHIỂN THỬ NGHIỆM',
              style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _simulatedCall ? Colors.redAccent : const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_simulatedCall ? Icons.call_end_rounded : Icons.call_rounded),
                    label: Text(_simulatedCall ? 'Tắt Cuộc Gọi' : 'Test Cuộc Gọi iOS'),
                    onPressed: () {
                      setState(() {
                        _simulatedCall = !_simulatedCall;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                      side: const BorderSide(color: Color(0xFF00E5FF)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Gửi lại BLE'),
                    onPressed: () {
                      nav.sendMapVectorToEsp32();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã gửi gói tin sang ESP32!')),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Giải thích cơ chế hoạt động:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Khi có cuộc gọi/tin nhắn, dịch vụ ANCS trên iOS tự động đẩy thông báo sang ESP32 mà không cần App Flutter chạy ngầm can thiệp.\n'
                    '2. Khi bạn bật dẫn đường trên App Flutter, App sẽ liên tục tính khoảng cách tới khúc rẽ tiếp theo và nén lộ trình thành các điểm vector gửi qua BLE.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter vẽ đường Vector Polyline lên khung Mini Map
class MiniMapVectorPainter extends CustomPainter {
  final List<Point2D> points;

  MiniMapVectorPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Scale tọa độ Point2D (0..120, 0..50) vào kích thước canvas thực tế
    final scaleX = size.width / 120;
    final scaleY = size.height / 50;

    path.moveTo(points.first.x * scaleX, points.first.y * scaleY);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x * scaleX, points[i].y * scaleY);
    }

    canvas.drawPath(path, paint);

    // Vẽ điểm bắt đầu (Xanh lá) và điểm kết thúc (Đỏ)
    final startPaint = Paint()..color = Colors.greenAccent..style = PaintingStyle.fill;
    final endPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(points.first.x * scaleX, points.first.y * scaleY), 3.0, startPaint);
    canvas.drawCircle(Offset(points.last.x * scaleX, points.last.y * scaleY), 3.0, endPaint);
  }

  @override
  bool shouldRepaint(covariant MiniMapVectorPainter oldDelegate) => true;
}
