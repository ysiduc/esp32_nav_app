import 'package:flutter/material.dart';

class AncsGuideScreen extends StatelessWidget {
  const AncsGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Kích hoạt Cuộc gọi / Tin nhắn (ANCS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner giải thích
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.apple_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Apple ANCS là gì?',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Apple Notification Center Service (ANCS) là tính năng Bluetooth tích hợp sẵn trong iOS. Khi iPhone ghép đôi với ESP32, iOS sẽ tự động chuyển tiếp toàn bộ cuộc gọi đến, SMS, Zalo, Messenger sang màn hình ESP32 mà không cần mở bất kỳ ứng dụng nào.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'HƯỚNG DẪN KÍCH HOẠT TỪNG BƯỚC TRÊN IPHONE',
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          _buildStepCard(
            stepNumber: '1',
            title: 'Bật nguồn ESP32',
            description: 'Đảm bảo ESP32 đã nạp firmware ANCS và đang phát tín hiệu Bluetooth (chờ kết nối).',
            icon: Icons.power_rounded,
          ),
          _buildStepCard(
            stepNumber: '2',
            title: 'Mở Cài đặt Bluetooth trên iPhone',
            description: 'Trên iPhone, vào Cài đặt (Settings) -> Bluetooth. Tìm thiết bị có tên "ESP32-NAV" hoặc "ESP32-ANCS" và bấm Kết nối.',
            icon: Icons.bluetooth_searching_rounded,
          ),
          _buildStepCard(
            stepNumber: '3',
            title: 'Xác nhận Ghép đôi (Pairing Request)',
            description: 'Khi màn hình iPhone hiện thông báo "Yêu cầu ghép đôi Bluetooth", bấm chọn "Ghép đôi" (Pair).',
            icon: Icons.phonelink_ring_rounded,
          ),
          _buildStepCard(
            stepNumber: '4',
            title: 'Bật "Chia sẻ thông báo hệ thống"',
            description: 'Bấm vào biểu tượng chữ (i) bên cạnh tên ESP32 trong danh sách Bluetooth -> Gạt BẬT mục "Chia sẻ thông báo hệ thống" (Share System Notifications).',
            icon: Icons.notifications_active_rounded,
            isHighlight: true,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent.withAlpha(100)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mẹo: Sau khi hoàn thành 4 bước trên, mỗi khi có cuộc gọi đến, tên người gọi sẽ lập tức hiển thị lên màn hình ESP32!',
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: isHighlight ? Border.all(color: Colors.cyanAccent, width: 1.5) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isHighlight ? Colors.cyanAccent : const Color(0xFF334155),
            child: Text(
              stepNumber,
              style: TextStyle(
                color: isHighlight ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: isHighlight ? Colors.cyanAccent : Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
