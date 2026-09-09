import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/search_place.dart';
import '../models/map_layer_type.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isMuted = false;

  final List<Map<String, dynamic>> _quickCategories = [
    {'name': 'Cây xăng', 'query': 'Cây xăng xăng dầu', 'icon': Icons.local_gas_station_rounded, 'color': Color(0xFFEA4335)},
    {'name': 'Cà phê', 'query': 'Quán cà phê cafe Highlands Coffee', 'icon': Icons.local_cafe_rounded, 'color': Color(0xFFF9AB00)},
    {'name': 'Nhà hàng', 'query': 'Nhà hàng quán ăn ẩm thực', 'icon': Icons.restaurant_rounded, 'color': Color(0xFF34A853)},
    {'name': 'Tạp hóa', 'query': 'Siêu thị WinMart Circle K', 'icon': Icons.local_grocery_store_rounded, 'color': Color(0xFF4285F4)},
    {'name': 'Khách sạn', 'query': 'Khách sạn hotel homestay', 'icon': Icons.hotel_rounded, 'color': Color(0xFFA142F4)},
    {'name': 'ATM', 'query': 'Cây ATM Vietcombank BIDV', 'icon': Icons.atm_rounded, 'color': Color(0xFF00ACC1)},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearchModal(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    _searchController.clear();
    nav.clearSearchResults();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final searchResults = nav.searchResults;
            final isSearching = nav.isSearching;

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Color(0xFF1A73E8), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Color(0xFF202124), fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'Tìm địa chỉ, địa danh hoặc toạ độ GPS...',
                              hintStyle: TextStyle(color: Color(0xFF70757A), fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setModalState(() {});
                              nav.searchDestination(val);
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF70757A), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              nav.clearSearchResults();
                              setModalState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
                      ),
                    )
                  else if (searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (_, _) => Divider(color: Colors.grey.shade200, height: 1),
                        itemBuilder: (context, idx) {
                          final place = searchResults[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F0FE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(place.icon, color: const Color(0xFF1A73E8), size: 20),
                            ),
                            title: Text(
                              place.name,
                              style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              place.description,
                              style: const TextStyle(color: Color(0xFF70757A), fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              await nav.selectSearchPlace(place);
                              if (context.mounted) Navigator.pop(ctx);
                              _mapController.move(place.location, 15.5);
                            },
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: _searchController.text.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy "${_searchController.text}"',
                                    style: const TextStyle(color: Color(0xFF202124), fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Hãy thử nhập tên phố, quận huyện hoặc toạ độ GPS',
                                    style: TextStyle(color: Color(0xFF70757A), fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: Text('GỢI Ý ĐỊA ĐIỂM TIÊU BIỂU (VIỆT NAM)',
                                      style: TextStyle(color: Color(0xFF70757A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                                ),
                                _buildPlaceTile('280 Lê Văn Sỹ', 'Phường 14, Quận 3, TP.HCM', const LatLng(10.7915, 106.6668), ctx, nav),
                                _buildPlaceTile('Nhà thờ Tân Xa Châu', '367 Lê Văn Sỹ, Phường 2, Tân Bình, TP.HCM', const LatLng(10.7938, 106.6660), ctx, nav),
                                _buildPlaceTile('Ngã tư Phạm Văn Hai', 'Lê Văn Sỹ x Phạm Văn Hai, Tân Bình, TP.HCM', const LatLng(10.7955, 106.6655), ctx, nav),
                                _buildPlaceTile('Hồ Hoàn Kiếm', 'Quận Hoàn Kiếm, Hà Nội', const LatLng(21.0285, 105.8542), ctx, nav),
                                _buildPlaceTile('Landmark 81', '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM', const LatLng(10.7950, 106.7219), ctx, nav),
                              ],
                            ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceTile(String name, String desc, LatLng loc, BuildContext ctx, NavigationProvider nav) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFFE8F0FE), shape: BoxShape.circle),
        child: const Icon(Icons.location_on_rounded, color: Color(0xFFEA4335), size: 20),
      ),
      title: Text(name, style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(color: Color(0xFF70757A), fontSize: 12), maxLines: 1),
      onTap: () async {
        await nav.selectSearchPlace(SearchPlace(name: name, description: desc, location: loc));
        if (context.mounted) Navigator.pop(ctx);
        _mapController.move(loc, 15.5);
      },
    );
  }

  void _openLayerSelectorModal(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loại Bản Đồ (Map Layers)',
                  style: TextStyle(color: Color(0xFF202124), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...MapLayerType.values.map((layer) {
                  final isSelected = nav.currentMapLayer == layer;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Text(layer.iconEmoji, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      layer.displayName,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF1A73E8) : const Color(0xFF202124),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1A73E8))
                        : null,
                    onTap: () {
                      nav.setMapLayer(layer);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final userPos = nav.userLocation ?? const LatLng(10.7915, 106.6668);
    final routes = nav.routes;
    final currentRoute = nav.currentRoute;
    final step = nav.currentStep;

    // Bản đồ 3D góc nhìn lái xe (Perspective Pitch)
    Widget mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userPos,
        initialZoom: nav.uiMode == AppUiMode.activeNavigation ? 16.8 : 14.5,
        maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
        minZoom: 3.0,
        keepAlive: true,
        backgroundColor: const Color(0xFFECE7E1),
        onTap: (tapPosition, point) {
          if (nav.uiMode != AppUiMode.activeNavigation) {
            nav.setDestination(point);
          }
        },
      ),
      children: [
        // 1. TILE LAYER (CARTO VOYAGER 3D BUILDINGS & OSM TILES)
        TileLayer(
          urlTemplate: nav.currentMapLayer.urlTemplate,
          subdomains: nav.currentMapLayer.subdomains,
          userAgentPackageName: 'com.esp32nav.app',
          keepBuffer: 12,
          panBuffer: 4,
          maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
          tileProvider: NetworkTileProvider(),
        ),

        // 2. TUYẾN ĐƯỜNG MÀU XANH ĐẬM CHUẨN GOOGLE MAPS (ẢNH CHỤP)
        if (routes.isNotEmpty) ...[
          // Tuyến phụ (Màu Xám)
          for (int i = 0; i < routes.length; i++)
            if (i != nav.selectedRouteIndex)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routes[i].polyline,
                    strokeWidth: 8.0,
                    color: const Color(0xFF9AA0A6).withAlpha(200),
                  ),
                ],
              ),

          // Tuyến chính (Màu Xanh Đậm Ribbon 3D)
          if (currentRoute != null)
            PolylineLayer(
              polylines: [
                // Viền ngoài tạo độ sâu
                Polyline(
                  points: currentRoute.polyline,
                  strokeWidth: 14.0,
                  color: const Color(0xFF003D99).withAlpha(120),
                ),
                // Lõi xanh dương đậm chuẩn ảnh chụp (#0E56CF)
                Polyline(
                  points: currentRoute.polyline,
                  strokeWidth: 10.0,
                  color: const Color(0xFF0E56CF),
                ),
              ],
            ),
        ],

        // 3. CÁC MARKER (VỊ TRÍ XE 3D, MŨI TÊN RẼ TRÊN ĐƯỜNG, ĐIỂM ĐÍCH)
        MarkerLayer(
          markers: [
            // 3.1 MŨI TÊN CHỈ HƯỚNG RẼ ZIGZAG TRÊN TUYẾN ĐƯỜNG (CHÍNH XÁC NHƯ ẢNH MẪU)
            if (currentRoute != null && currentRoute.polyline.length > 5)
              Marker(
                point: currentRoute.polyline[currentRoute.polyline.length ~/ 2],
                width: 38,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.turn_slight_right_rounded, color: Color(0xFF0E56CF), size: 30),
                ),
              ),

            // 3.2 ĐIỂM XUẤT PHÁT (KHI CHƯA BẬT DẪN ĐƯỜNG)
            if (nav.uiMode != AppUiMode.activeNavigation)
              Marker(
                point: userPos,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E56CF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 6),
                    ],
                  ),
                ),
              ),

            // 3.3 ĐIỂM ĐÍCH (GHIM ĐỎ 📍)
            if (nav.destination != null)
              Marker(
                point: nav.destination!,
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFEA4335),
                  size: 44,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
              ),

            // 3.4 PUCK VỊ TRÍ XE 3D (ĐĨA TRẮNG VIỀN XÁM + MŨI TÊN ĐEN ▲ CHUẨN ẢNH CHỤP)
            if (nav.uiMode == AppUiMode.activeNavigation)
              Marker(
                point: userPos,
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vòng tròn mờ bên ngoài
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF80868B).withAlpha(120),
                      ),
                    ),
                    // Đĩa tròn trắng có bóng đổ
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.navigation_rounded, color: Color(0xFF202124), size: 26),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );

    // Áp dụng góc nghiêng 3D Perspective khi dẫn đường
    if (nav.uiMode == AppUiMode.activeNavigation && nav.is3DView) {
      mapWidget = Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateX(0.65),
        child: mapWidget,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECE7E1),
      body: Stack(
        children: [
          // 1. MÀN HÌNH BẢN ĐỒ
          Positioned.fill(child: mapWidget),

          // ==========================================
          // 2. CÁC NÚT ĐIỀU KHIỂN NỔI BÊN PHẢI (GÓC PHẢI TRÊN CHUẨN ẢNH)
          // ==========================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              children: [
                // Nút chuyển đổi 2D / 3D
                GestureDetector(
                  onTap: () => nav.toggle3DView(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        nav.is3DView ? '3D' : '2D',
                        style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Tắt / Bật Âm Thanh Loa (Icon 🔇 trong ảnh)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: const Color(0xFF202124),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Chọn Lớp Bản Đồ
                GestureDetector(
                  onTap: () => _openLayerSelectorModal(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.layers_outlined, color: Color(0xFF1A73E8), size: 24),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Quản Lý ESP32
                GestureDetector(
                  onTap: () => _showToolsModal(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Icon(
                      nav.bleService.isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
                      color: nav.bleService.isConnected ? const Color(0xFF188038) : const Color(0xFF5F6368),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. GIAO DIỆN CHẾ ĐỘ DẪN ĐƯỜNG TRỰC TIẾP (ẢNH CHỤP)
          // ==========================================
          if (nav.uiMode == AppUiMode.activeNavigation) ...[
            // Banner Xanh Lá Chỉ Hướng
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D652D),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      step?.icon ?? Icons.turn_slight_right_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${nav.distanceToNextStep.toInt()} m',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            step?.streetName.isNotEmpty == true ? step!.streetName : 'Đường Lê Văn Sỹ',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút Tìm Kiếm / Tổng Quan góc dưới phải (Icon tròn xanh như ảnh chụp)
            Positioned(
              bottom: 95,
              right: 16,
              child: GestureDetector(
                onTap: () => _openSearchModal(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A73E8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),

            // Nút Re-center định vị góc dưới trái
            Positioned(
              bottom: 95,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(userPos, 16.8);
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Color(0xFF1A73E8), size: 28),
                ),
              ),
            ),

            // Thanh Bottom Trắng Google Maps Dẫn Đường
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                  ],
                ),
                child: Row(
                  children: [
                    // Nút Dừng dẫn đường (X)
                    GestureDetector(
                      onTap: () => nav.stopNavigation(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF5F6368), size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ETA & Khoảng cách
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentRoute?.shortDurationFormatted ?? '12p',
                                style: const TextStyle(color: Color(0xFF188038), fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentRoute?.formattedTotalDistance ?? '4,8 km',
                                style: const TextStyle(color: Color(0xFF5F6368), fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            'Đến lúc ${currentRoute?.arrivalTimeFormatted ?? '21:05'} • Tuyến nhanh nhất',
                            style: const TextStyle(color: Color(0xFF70757A), fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // Nút Danh Sách Chặng
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF5F6368)),
                      onPressed: () => nav.setUiMode(AppUiMode.previewList),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ==========================================
          // 4. GIAO DIỆN CHẾ ĐỘ TÌM KIẾM (EXPLORE)
          // ==========================================
          if (nav.uiMode == AppUiMode.explore) ...[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh Tìm Kiếm Nổi
                    GestureDetector(
                      onTap: () => _openSearchModal(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFF1A73E8), size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Tìm kiếm tại đây',
                                style: TextStyle(color: Color(0xFF5F6368), fontSize: 15),
                              ),
                            ),
                            const Icon(Icons.mic_none_rounded, color: Color(0xFF5F6368), size: 22),
                            const SizedBox(width: 10),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A73E8),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Băng Chuyền Danh Mục
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final cat = _quickCategories[idx];
                          return GestureDetector(
                            onTap: () {
                              nav.searchDestination(cat['query']);
                              _openSearchModal(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat['icon'], color: cat['color'], size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat['name'],
                                    style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ==========================================
          // 5. GIAO DIỆN CHẾ ĐỘ XEM TRƯỚC LỘ TRÌNH (PREVIEW MAP)
          // ==========================================
          if (nav.uiMode == AppUiMode.previewMap) ...[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF202124)),
                                onPressed: () => nav.setUiMode(AppUiMode.explore),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(color: Color(0xFF1A73E8), shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          nav.startAddressName,
                                          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const Divider(color: Colors.black12, height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: Color(0xFFEA4335), size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            nav.destinationName,
                                            style: const TextStyle(color: Color(0xFF202124), fontSize: 14, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentRoute?.shortDurationFormatted ?? '14p',
                          style: const TextStyle(color: Color(0xFF188038), fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '(${currentRoute?.formattedTotalDistance ?? '7,2 km'})',
                          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () => nav.startNavigation(),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.navigation_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Bắt đầu dẫn đường 3D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ==========================================
          // 6. GIAO DIỆN DANH SÁCH CHẶNG (PREVIEW LIST)
          // ==========================================
          if (nav.uiMode == AppUiMode.previewList) ...[
            SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF202124)),
                            onPressed: () => nav.setUiMode(AppUiMode.activeNavigation),
                          ),
                          const SizedBox(width: 8),
                          const Text('Chi tiết các chặng rẽ', style: TextStyle(color: Color(0xFF202124), fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: currentRoute?.steps.length ?? 0,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                        itemBuilder: (context, idx) {
                          final st = currentRoute!.steps[idx];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFE8F0FE), shape: BoxShape.circle),
                              child: Icon(st.icon, color: const Color(0xFF1A73E8), size: 22),
                            ),
                            title: Text(st.streetName.isNotEmpty ? st.streetName : st.instruction, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Đi tiếp ${st.distanceMeters.round()} m', style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showToolsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Công cụ & Thiết bị ESP32', style: TextStyle(color: Color(0xFF202124), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.layers_rounded, color: Color(0xFF1A73E8)),
                  title: const Text('Chọn Lớp Bản Đồ', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
                  subtitle: const Text('Bản đồ 3D Voyager, OSM, Vệ tinh, Địa hình...', style: TextStyle(color: Color(0xFF70757A), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openLayerSelectorModal(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bluetooth_searching_rounded, color: Color(0xFF1A73E8)),
                  title: const Text('Kết Nối Bluetooth ESP32', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
                  subtitle: const Text('Quét và ghép nối thiết bị định vị ESP32', style: TextStyle(color: Color(0xFF70757A), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BleDevicesScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.developer_board_rounded, color: Color(0xFF188038)),
                  title: const Text('Mô phỏng Màn hình ESP32', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
                  subtitle: const Text('Xem trước màn hình OLED/TFT', style: TextStyle(color: Color(0xFF70757A), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const Esp32SimulatorScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFFEA4335)),
                  title: const Text('Hướng dẫn Cuộc gọi / SMS (ANCS)', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cách kết nối nhận thông báo từ iOS', style: TextStyle(color: Color(0xFF70757A), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AncsGuideScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
