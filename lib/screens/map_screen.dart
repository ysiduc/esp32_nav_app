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
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF101725),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00D2FF).withAlpha(120), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Color(0xFF00D2FF), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'Tìm địa chỉ, tên đường, địa danh hoặc toạ độ...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
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
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              nav.clearSearchResults();
                              setModalState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: Color(0xFF00D2FF)),
                      ),
                    )
                  else if (searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, idx) {
                          final place = searchResults[idx];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(place.icon, color: const Color(0xFF00D2FF), size: 20),
                            ),
                            title: Text(
                              place.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              place.description,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                                  const Icon(Icons.search_off_rounded, color: Colors.white30, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy "${_searchController.text}"',
                                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Hãy thử nhập tên phố, quận huyện hoặc toạ độ GPS',
                                    style: TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('ĐỊA ĐIỂM TIÊU BIỂU TẠI VIỆT NAM',
                                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
        child: const Icon(Icons.place_rounded, color: Colors.cyanAccent, size: 20),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1),
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
      backgroundColor: const Color(0xFF101725),
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn Giao Diện Bản Đồ',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                        color: isSelected ? const Color(0xFF00D2FF) : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00D2FF))
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
    final userPos = nav.userLocation ?? const LatLng(20.9789, 105.8368);
    final routes = nav.routes;
    final currentRoute = nav.currentRoute;
    final step = nav.currentStep;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 1. BẢN ĐỒ TỐI ĐA LUỒNG CDN (KHÔNG BAO GIỜ BỊ Ô VUÔNG TRẮNG, TẢI CỰC NHANH 60FPS)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: nav.uiMode == AppUiMode.activeNavigation ? 16.5 : 12.8,
              maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
              minZoom: 3.0,
              keepAlive: true,
              backgroundColor: const Color(0xFF0F172A),
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

              // VẼ CÁC TUYẾN ĐƯỜNG THAY THẾ (ALTERNATIVE ROUTES) & TUYẾN CHÍNH
              if (routes.isNotEmpty) ...[
                // Tuyến phụ (Màu Xám)
                for (int i = 0; i < routes.length; i++)
                  if (i != nav.selectedRouteIndex)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routes[i].polyline,
                          strokeWidth: 7.0,
                          color: const Color(0xFF7E8B9B).withAlpha(180),
                        ),
                      ],
                    ),

                // Tuyến chính được chọn (Màu Cyan Phát sáng Neon)
                if (currentRoute != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: currentRoute.polyline,
                        strokeWidth: 10.0,
                        color: const Color(0xFF0084FF).withAlpha(140),
                      ),
                      Polyline(
                        points: currentRoute.polyline,
                        strokeWidth: 6.0,
                        color: const Color(0xFF00D2FF),
                      ),
                    ],
                  ),
              ],

              // MARKERS: HUY HIỆU THỜI GIAN, CẢNH BÁO CÔNG TRƯỜNG, ĐIỂM ĐÍCH, PUCK
              MarkerLayer(
                markers: [
                  // 1. Điểm xuất phát (Chấm tròn xanh Waze)
                  Marker(
                    point: userPos,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),

                  // 2. Điểm đến đích (Cờ đích ô caro Waze 🏁)
                  if (nav.destination != null)
                    Marker(
                      point: nav.destination!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.sports_score_rounded, color: Colors.black, size: 28),
                        ),
                      ),
                    ),

                  // 3. Mũi tên dẫn đường Waze 3D Navigator Puck
                  if (nav.uiMode == AppUiMode.activeNavigation)
                    Marker(
                      point: userPos,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00D2FF),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF00D2FF).withAlpha(160), blurRadius: 16, spreadRadius: 2),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.navigation_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ),

                  // 4. HUY HIỆU THỜI GIAN TRÊN CÁC TUYẾN ĐƯỜNG
                  if (nav.uiMode != AppUiMode.activeNavigation && routes.isNotEmpty) ...[
                    if (currentRoute != null && currentRoute.polyline.length > 15)
                      Marker(
                        point: currentRoute.polyline[currentRoute.polyline.length ~/ 3],
                        width: 130,
                        height: 38,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D2FF),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_car_rounded, color: Colors.black, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${currentRoute.shortDurationFormatted} Tốt nhất',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                    for (int i = 0; i < routes.length; i++)
                      if (i != nav.selectedRouteIndex && routes[i].polyline.length > 15)
                        Marker(
                          point: routes[i].polyline[routes[i].polyline.length ~/ 2],
                          width: 85,
                          height: 34,
                          child: GestureDetector(
                            onTap: () => nav.selectRoute(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2634),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_car_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    routes[i].shortDurationFormatted,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                    // 5. Icon Cảnh báo Sự cố / Công trình
                    if (routes.length > 1 && routes[1].polyline.length > 20)
                      Marker(
                        point: routes[1].polyline[routes[1].polyline.length ~/ 3],
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: const BoxDecoration(color: Color(0xFFEAB308), shape: BoxShape.circle),
                          child: const Icon(Icons.engineering_rounded, color: Colors.black, size: 18),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),

          // ==========================================
          // 2. GIAO DIỆN CHẾ ĐỘ 1: XEM TRƯỚC LỘ TRÌNH (ẢNH 1)
          // ==========================================
          if (nav.uiMode == AppUiMode.previewMap) ...[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E2634)),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: () => _openSearchModal(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openSearchModal(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2634),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 8),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(color: Color(0xFF00D2FF), shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        nav.startAddressName,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: Color(0xFFFF4B4B), size: 14),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          nav.destinationName,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2634),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Tránh', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openLayerSelectorModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2634),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(nav.currentMapLayer.iconEmoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                const Text('Lớp bản đồ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF12161E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () => nav.setUiMode(AppUiMode.previewList),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentRoute?.shortDurationFormatted ?? '1h 11p',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          currentRoute?.arrivalTimeFormatted ?? '21:34',
                          style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentRoute?.viaRoadName ?? 'Qua CT. Đại lộ Thăng Long Hà Nội',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Tuyến đường nhanh nhất dù có công trình',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2634),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.engineering_rounded, color: Color(0xFFEAB308), size: 16),
                          SizedBox(width: 6),
                          Text('Có công trình', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: () => nav.setUiMode(AppUiMode.previewList),
                            child: const Text('Xem danh sách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0084FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 4,
                            ),
                            onPressed: () => nav.startNavigation(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.navigation_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
          // 3. GIAO DIỆN CHẾ ĐỘ 2: DANH SÁCH CÁC TUYẾN ĐƯỜNG (ẢNH 3)
          // ==========================================
          if (nav.uiMode == AppUiMode.previewList) ...[
            SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF101725),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => nav.setUiMode(AppUiMode.previewMap),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Thời gian đến gần đúng', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          Text(nav.destinationName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2634),
                          foregroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => nav.setUiMode(AppUiMode.previewMap),
                        child: const Text('B.đồ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D2FF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {},
                        child: const Text('D.sách', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 170,
              left: 16,
              right: 16,
              bottom: 20,
              child: ListView.separated(
                itemCount: routes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final r = routes[idx];
                  final isBest = idx == 0;
                  final isSelected = idx == nav.selectedRouteIndex;

                  return _buildRouteCard(
                    duration: r.shortDurationFormatted,
                    etaAndDist: '${r.arrivalTimeFormatted}  •  ${r.formattedTotalDistance}',
                    roadName: isBest ? 'Qua CT. Đại lộ Thăng Long • Tốt nhất' : 'Qua QL6 / Đ. Nguyễn Trãi',
                    btnLabel: isSelected ? '▲ Xuất phát' : 'Chọn',
                    hasHelmet: isBest,
                    isSelected: isSelected,
                    onTap: () {
                      nav.selectRoute(idx);
                      nav.startNavigation();
                    },
                  );
                },
              ),
            ),
          ],

          // ==========================================
          // 4. GIAO DIỆN CHẾ ĐỘ 3: DẪN ĐƯỜNG TRỰC TIẾP (ẢNH 2)
          // ==========================================
          if (nav.uiMode == AppUiMode.activeNavigation) ...[
            SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF080B10),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      step?.icon ?? Icons.turn_sharp_left_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${nav.distanceToNextStep.toInt()} m',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            step?.streetName ?? 'Phố Trần Nguyên Hãn',
                            style: const TextStyle(color: Color(0xFF00D2FF), fontSize: 17, fontWeight: FontWeight.bold),
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

            // La bàn (Compass) góc trên bên trái
            Positioned(
              top: 110,
              left: 18,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(userPos, 16.5);
                },
                onLongPress: () => _openLayerSelectorModal(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12161E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.explore_outlined, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),

            // Nút Nhạc & Loa góc trên bên phải
            Positioned(
              top: 110,
              right: 18,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2634),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
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
                        color: const Color(0xFF1E2634),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8),
                        ],
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Đồng hồ Tốc độ (Speedometer) góc dưới bên trái
            Positioned(
              bottom: 125,
              left: 18,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2634),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${nav.currentSpeedKmh.toInt()}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Capsule Tên đường hiện tại ở giữa
            Positioned(
              bottom: 135,
              left: 95,
              right: 95,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0F14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    nav.destinationName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            // Nút Báo cáo sự cố Waze (Nút vàng) góc dưới phải
            Positioned(
              bottom: 125,
              right: 18,
              child: GestureDetector(
                onTap: () {
                  _showToolsModal(context);
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEAB308), Color(0xFFCA8A04)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 36),
                      const Positioned(child: Icon(Icons.add, color: Colors.black, size: 16)),
                    ],
                  ),
                ),
              ),
            ),

            // Thanh Bottom Waze Arrival Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF12161E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _openSearchModal(context),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: Color(0xFF1E2634), shape: BoxShape.circle),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => nav.setUiMode(AppUiMode.previewList),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentRoute?.arrivalTimeFormatted ?? '20:38',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              currentRoute?.durationAndDistanceFormatted ?? '10 phút  •  7 km',
                              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => nav.setUiMode(AppUiMode.previewMap),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: Color(0xFF0084FF), shape: BoxShape.circle),
                        child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 26),
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

  Widget _buildRouteCard({
    required String duration,
    required String etaAndDist,
    required String roadName,
    required String btnLabel,
    required bool hasHelmet,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2634),
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: const Color(0xFF00D2FF), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(duration, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D2FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: onTap,
                child: Text(btnLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(etaAndDist, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(roadName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
              if (hasHelmet)
                Positioned(
                  left: 100,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Color(0xFFEAB308), shape: BoxShape.circle),
                    child: const Icon(Icons.engineering_rounded, color: Colors.black, size: 14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showToolsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101725),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Công cụ & Thiết bị ESP32', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.layers_rounded, color: Color(0xFF00D2FF)),
                  title: const Text('Chọn Lớp Bản Đồ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Chế độ Tối Waze, OSM, Vệ tinh, Địa hình...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openLayerSelectorModal(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bluetooth_searching_rounded, color: Colors.blueAccent),
                  title: const Text('Kết Nối Bluetooth ESP32', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Quét và ghép nối thiết bị định vị ESP32', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BleDevicesScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.developer_board_rounded, color: Colors.cyanAccent),
                  title: const Text('Mô phỏng Màn hình ESP32', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Xem trước màn hình OLED/TFT', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const Esp32SimulatorScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                  title: const Text('Hướng dẫn Cuộc gọi / SMS (ANCS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cách kết nối nhận thông báo từ iOS', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
