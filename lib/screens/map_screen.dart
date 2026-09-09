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
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FE),
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
                              _mapController.move(place.location, 14.5);
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
                                _buildPlaceTile('Hồ Hoàn Kiếm', 'Quận Hoàn Kiếm, Hà Nội', const LatLng(21.0285, 105.8542), ctx, nav),
                                _buildPlaceTile('Chung cư CT36A Định Công', 'Phố Định Công Thượng, Hoàng Mai, Hà Nội', const LatLng(20.9789, 105.8368), ctx, nav),
                                _buildPlaceTile('Sân bay Nội Bài', 'Sóc Sơn, Hà Nội', const LatLng(21.2187, 105.8041), ctx, nav),
                                _buildPlaceTile('Landmark 81', '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM', const LatLng(10.7950, 106.7219), ctx, nav),
                                _buildPlaceTile('Chợ Bến Thành', 'Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM', const LatLng(10.7725, 106.6980), ctx, nav),
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
        _mapController.move(loc, 14.0);
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
    final userPos = nav.userLocation ?? const LatLng(21.0285, 105.8542);
    final routes = nav.routes;
    final currentRoute = nav.currentRoute;
    final step = nav.currentStep;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 1. LỚP BẢN ĐỒ OPENSTREETMAP CHÍNH THỨC (CHUẨN GOOGLE MAPS)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: nav.uiMode == AppUiMode.activeNavigation ? 16.5 : 13.5,
              maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
              minZoom: 3.0,
              keepAlive: true,
              backgroundColor: const Color(0xFFE5E3DF),
              onTap: (tapPosition, point) {
                if (nav.uiMode != AppUiMode.activeNavigation) {
                  nav.setDestination(point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: nav.currentMapLayer.urlTemplate,
                subdomains: nav.currentMapLayer.subdomains,
                userAgentPackageName: 'com.esp32nav.app',
                keepBuffer: 10,
                panBuffer: 4,
                maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
                tileProvider: NetworkTileProvider(),
              ),

              // VẼ TUYẾN ĐƯỜNG GOOGLE MAPS (XANH DƯƠNG #1A73E8 & XÁM PHỤ #70757A)
              if (routes.isNotEmpty) ...[
                // Tuyến phụ (Màu Xám Google)
                for (int i = 0; i < routes.length; i++)
                  if (i != nav.selectedRouteIndex)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routes[i].polyline,
                          strokeWidth: 6.0,
                          color: const Color(0xFF9AA0A6).withAlpha(220),
                        ),
                      ],
                    ),

                // Tuyến chính (Màu Xanh Google Maps Nổi Bật)
                if (currentRoute != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: currentRoute.polyline,
                        strokeWidth: 9.0,
                        color: const Color(0xFF185ABC).withAlpha(120),
                      ),
                      Polyline(
                        points: currentRoute.polyline,
                        strokeWidth: 6.0,
                        color: const Color(0xFF1A73E8),
                      ),
                    ],
                  ),
              ],

              // MARKERS GOOGLE MAPS
              MarkerLayer(
                markers: [
                  // 1. Điểm xuất phát (Chấm tròn xanh Google Maps)
                  Marker(
                    point: userPos,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),

                  // 2. Điểm đích (Ghim Đỏ Google Maps 📍)
                  if (nav.destination != null)
                    Marker(
                      point: nav.destination!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFEA4335),
                        size: 40,
                        shadows: [
                          Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                    ),

                  // 3. Mũi tên dẫn đường Google Navigation Puck (Khi dẫn đường)
                  if (nav.uiMode == AppUiMode.activeNavigation)
                    Marker(
                      point: userPos,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A73E8),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF1A73E8).withAlpha(150), blurRadius: 14, spreadRadius: 2),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.navigation_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),

                  // 4. Huy hiệu thời gian trên lộ trình (Google Time Badges)
                  if (nav.uiMode != AppUiMode.activeNavigation && routes.isNotEmpty) ...[
                    if (currentRoute != null && currentRoute.polyline.length > 15)
                      Marker(
                        point: currentRoute.polyline[currentRoute.polyline.length ~/ 3],
                        width: 110,
                        height: 36,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF188038),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${currentRoute.shortDurationFormatted} • Nhanh nhất',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                      ),

                    for (int i = 0; i < routes.length; i++)
                      if (i != nav.selectedRouteIndex && routes[i].polyline.length > 15)
                        Marker(
                          point: routes[i].polyline[routes[i].polyline.length ~/ 2],
                          width: 80,
                          height: 32,
                          child: GestureDetector(
                            onTap: () => nav.selectRoute(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  routes[i].shortDurationFormatted,
                                  style: const TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ],
          ),

          // ==========================================
          // 2. GIAO DIỆN CHẾ ĐỘ 1: TÌM KIẾM & KHÁM PHÁ (GOOGLE MAPS EXPLORE)
          // ==========================================
          if (nav.uiMode == AppUiMode.explore) ...[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh Tìm Kiếm Trắng Nổi Google Maps
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

                    // Băng Chuyền Chip Danh Mục Nhanh (Google Categories)
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

            // Nút FAB nổi bên phải (Lớp bản đồ, Định vị GPS, Bluetooth ESP32)
            Positioned(
              right: 16,
              bottom: 40,
              child: Column(
                children: [
                  // Nút Lớp Bản Đồ
                  FloatingActionButton.small(
                    heroTag: 'fab_layer',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A73E8),
                    elevation: 3,
                    onPressed: () => _openLayerSelectorModal(context),
                    child: const Icon(Icons.layers_outlined),
                  ),
                  const SizedBox(height: 12),

                  // Nút Công cụ & BLE ESP32
                  FloatingActionButton.small(
                    heroTag: 'fab_ble',
                    backgroundColor: Colors.white,
                    foregroundColor: nav.bleService.isConnected ? const Color(0xFF188038) : const Color(0xFF5F6368),
                    elevation: 3,
                    onPressed: () => _showToolsModal(context),
                    child: Icon(nav.bleService.isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded),
                  ),
                  const SizedBox(height: 12),

                  // Nút Vị trí của tôi (GPS)
                  FloatingActionButton(
                    heroTag: 'fab_gps',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A73E8),
                    elevation: 4,
                    onPressed: () {
                      _mapController.move(userPos, 15.0);
                    },
                    child: const Icon(Icons.my_location_rounded, size: 26),
                  ),
                ],
              ),
            ),
          ],

          // ==========================================
          // 3. GIAO DIỆN CHẾ ĐỘ 2: XEM TRƯỚC LỘ TRÌNH (GOOGLE DIRECTIONS)
          // ==========================================
          if (nav.uiMode == AppUiMode.previewMap) ...[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Hộp Điểm Đi - Đến Google Maps
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
                              IconButton(
                                icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF5F6368)),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Tabs Phương Tiện (Ô tô, Xe máy, Đi bộ)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTransportTab(
                                icon: Icons.directions_car_rounded,
                                label: 'Ô tô',
                                isSelected: nav.transportMode == TransportMode.driving,
                                onTap: () => nav.setTransportMode(TransportMode.driving),
                              ),
                              _buildTransportTab(
                                icon: Icons.two_wheeler_rounded,
                                label: 'Xe máy',
                                isSelected: nav.transportMode == TransportMode.motorcycle,
                                onTap: () => nav.setTransportMode(TransportMode.motorcycle),
                              ),
                              _buildTransportTab(
                                icon: Icons.directions_walk_rounded,
                                label: 'Đi bộ',
                                isSelected: nav.transportMode == TransportMode.walking,
                                onTap: () => nav.setTransportMode(TransportMode.walking),
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

            // Bottom Sheet Lộ trình Google Maps
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () => nav.setUiMode(AppUiMode.previewList),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Row(
                          children: [
                            Text(
                              currentRoute?.shortDurationFormatted ?? '14p',
                              style: const TextStyle(color: Color(0xFF188038), fontSize: 26, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${currentRoute?.formattedTotalDistance ?? '7,2 km'})',
                              style: const TextStyle(color: Color(0xFF5F6368), fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          'Đến lúc ${currentRoute?.arrivalTimeFormatted ?? '20:45'}',
                          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentRoute?.viaRoadName ?? 'Tuyến đường nhanh nhất dù có chút công trình',
                      style: const TextStyle(color: Color(0xFF202124), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 2,
                            ),
                            onPressed: () => nav.startNavigation(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.navigation_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A73E8),
                              side: const BorderSide(color: Color(0xFFDADCE0)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: () => nav.setUiMode(AppUiMode.previewList),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.list_alt_rounded, size: 18),
                                SizedBox(width: 6),
                                Text('Các chặng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ==========================================
          // 4. GIAO DIỆN CHẾ ĐỘ 3: DANH SÁCH CÁC CHẶNG ĐƯỜNG (GOOGLE STEPS)
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
                            onPressed: () => nav.setUiMode(AppUiMode.previewMap),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Chi tiết lộ trình', style: TextStyle(color: Color(0xFF70757A), fontSize: 12)),
                                Text(
                                  '${currentRoute?.shortDurationFormatted ?? ''} (${currentRoute?.formattedTotalDistance ?? ''})',
                                  style: const TextStyle(color: Color(0xFF202124), fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                            title: Text(
                              st.streetName.isNotEmpty ? st.streetName : st.instruction,
                              style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Đi tiếp ${st.distanceMeters.round()} m',
                              style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () => nav.startNavigation(),
                          child: const Text('Bắt đầu dẫn đường', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ==========================================
          // 5. GIAO DIỆN CHẾ ĐỘ 4: DẪN ĐƯỜNG TRỰC TIẾP (GOOGLE MAPS ACTIVE NAVIGATION)
          // ==========================================
          if (nav.uiMode == AppUiMode.activeNavigation) ...[
            // BANNER XANH LÁ GOOGLE MAPS TRÊN CÙNG (#0D652D)
            SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D652D),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      step?.icon ?? Icons.turn_sharp_left_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${nav.distanceToNextStep.toInt()} m',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            step?.streetName ?? 'Phố Trần Nguyên Hãn',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

            // Nút Loa & Nút La Bàn góc trên bên phải
            Positioned(
              top: 110,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'fab_mute',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5F6368),
                    elevation: 3,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                    child: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'fab_nav_layer',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A73E8),
                    elevation: 3,
                    onPressed: () => _openLayerSelectorModal(context),
                    child: const Icon(Icons.layers_outlined),
                  ),
                ],
              ),
            ),

            // Đồng hồ Tốc độ & Giới hạn tốc độ tròn Google Maps
            Positioned(
              bottom: 95,
              left: 16,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${nav.currentSpeedKmh.toInt()}',
                      style: const TextStyle(color: Color(0xFF202124), fontSize: 20, fontWeight: FontWeight.w900, height: 1),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(color: Color(0xFF5F6368), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Nút Re-center (Định vị) góc dưới phải
            Positioned(
              bottom: 95,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'fab_recenter',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A73E8),
                elevation: 4,
                onPressed: () {
                  _mapController.move(userPos, 16.5);
                },
                child: const Icon(Icons.navigation_rounded, size: 26),
              ),
            ),

            // THANH BOTTOM TRẮNG GOOGLE MAPS DẪN ĐƯỜNG
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
                    // Nút Dừng dẫn đường (X màu xám)
                    GestureDetector(
                      onTap: () => nav.stopNavigation(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF5F6368), size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ETA & Khoảng cách còn lại
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentRoute?.shortDurationFormatted ?? '10p',
                                style: const TextStyle(color: Color(0xFF188038), fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentRoute?.formattedTotalDistance ?? '7,2 km',
                                style: const TextStyle(color: Color(0xFF5F6368), fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            'Đến lúc ${currentRoute?.arrivalTimeFormatted ?? '20:45'}',
                            style: const TextStyle(color: Color(0xFF70757A), fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // Nút Tìm kiếm trên tuyến đường (🔍)
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Color(0xFF5F6368)),
                      onPressed: () => _openSearchModal(context),
                    ),

                    // Nút Công cụ & BLE (⋮)
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF5F6368)),
                      onPressed: () => _showToolsModal(context),
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

  Widget _buildTransportTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: const Color(0xFF1A73E8)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1A73E8) : const Color(0xFF5F6368), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1A73E8) : const Color(0xFF5F6368),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
                  subtitle: const Text('OpenStreetMap, Vệ tinh, Địa hình, Ban đêm...', style: TextStyle(color: Color(0xFF70757A), fontSize: 12)),
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
