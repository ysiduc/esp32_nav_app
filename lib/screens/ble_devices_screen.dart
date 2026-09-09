import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class BleDevicesScreen extends StatefulWidget {
  const BleDevicesScreen({super.key});

  @override
  State<BleDevicesScreen> createState() => _BleDevicesScreenState();
}

class _BleDevicesScreenState extends State<BleDevicesScreen> {
  @override
  void initState() {
    super.initState();
    final ble = context.read<NavigationProvider>().bleService;
    ble.startScan();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final ble = nav.bleService;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Quản lý Kết nối ESP32', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<bool>(
            stream: ble.isScanningStream,
            initialData: false,
            builder: (context, snapshot) {
              final isScanning = snapshot.data ?? false;
              return IconButton(
                icon: isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
                onPressed: isScanning ? null : () => ble.startScan(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Trạng thái kết nối hiện tại
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ble.isConnected ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ble.isConnected ? const Color(0xFF10B981) : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  ble.isConnected ? Icons.check_circle_rounded : Icons.bluetooth_searching_rounded,
                  color: ble.isConnected ? const Color(0xFF10B981) : Colors.white60,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ble.isConnected
                            ? 'Đã kết nối: ${ble.connectedDevice?.platformName.isNotEmpty == true ? ble.connectedDevice!.platformName : "ESP32 Device"}'
                            : 'Chưa kết nối ESP32',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ble.isConnected
                            ? 'Dữ liệu chỉ đường & bản đồ đang được đồng bộ'
                            : 'Hãy bật ESP32 và chọn thiết bị bên dưới để kết nối',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (ble.isConnected)
                  TextButton(
                    onPressed: () => ble.disconnect(),
                    child: const Text('Ngắt', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Log Gói tin BLE vừa truyền
          if (nav.lastSentPayload != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.data_object_rounded, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gói tin gửi: ${nav.lastSentPayload}',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DANH SÁCH THIẾT BỊ BLE QUANH ĐÂY',
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),

          // Danh sách thiết bị quét được
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: ble.scanResults,
              initialData: const [],
              builder: (context, snapshot) {
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  return const Center(
                    child: Text('Đang quét tìm thiết bị ESP32...', style: TextStyle(color: Colors.white38)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final res = results[index];
                    final name = res.device.platformName.isNotEmpty ? res.device.platformName : 'Thiết bị không tên';
                    final isEsp = name.toLowerCase().contains('esp') || name.toLowerCase().contains('nav');

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: isEsp ? Border.all(color: const Color(0xFF00E5FF).withAlpha(100)) : null,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth_rounded,
                          color: isEsp ? const Color(0xFF00E5FF) : Colors.white54,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isEsp ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          'MAC: ${res.device.remoteId}  |  RSSI: ${res.rssi} dBm',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final success = await ble.connect(res.device);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Kết nối thành công với $name!'
                                      : 'Không thể kết nối. Hãy đảm bảo ESP32 đang bật!',
                                ),
                              ),
                            );
                          },
                          child: const Text('Kết nối', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
