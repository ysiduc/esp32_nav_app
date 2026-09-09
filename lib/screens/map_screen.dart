import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/search_place.dart';
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
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm nơi đến (Tên đường, chung cư, địa chỉ)...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              nav.searchDestination(val);
                              setModalState(() {});
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 20),
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
                  Expanded(
                    child: isSearching
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D2FF)))
                        : (searchResults.isNotEmpty)
                            ? ListView.separated(
                                itemCount: searchResults.length,
                                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                                itemBuilder: (context, index) {
                                  final place = searchResults[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00D2FF).withAlpha(30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(place.icon, color: const Color(0xFF00D2FF), size: 22),
                                    ),
                                    title: Text(place.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    subtitle: Text(place.description, style: const TextStyle(color: Colors.white60, fontSize: 13), maxLines: 2),
                                    onTap: () {
                                      nav.selectSearchPlace(place);
                                      Navigator.pop(ctx);
                                      _mapController.move(place.location, 14.5);
                                    },
                                  );
                                },
                              )
                            : ListView(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'GỢI Ý ĐỊA ĐIỂM TẠI HÀ NỘI & VIỆT NAM',
                                      style: TextStyle(color: Color(0xFF00D2FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                                  ),
                                  _buildPlaceTile('Phương Hạnh', 'Quốc Oai, Hà Nội', const LatLng(20.9125, 105.6548), ctx, nav),
                                  _buildPlaceTile('Nguyễn Cảnh Dị (Định Công)', 'Phố Nguyễn Cảnh Dị, Hoàng Mai, Hà Nội', const LatLng(20.9789, 105.8368), ctx, nav),
                                  _buildPlaceTile('Chung cư Smile Building', 'Số 1 Nguyễn Cảnh Dị, Hoàng Mai, Hà Nội', const LatLng(20.9765, 105.8392), ctx, nav),
                                  _buildPlaceTile('Chung cư CT36A Định Công', 'Ngõ 177 Định Công, Hoàng Mai, Hà Nội', const LatLng(20.9812, 105.8354), ctx, nav),
                                  _buildPlaceTile('Hồ Hoàn Kiếm', 'Hàng Trống, Hoàn Kiếm, Hà Nội', const LatLng(21.0287, 105.8524), ctx, nav),
                                  _buildPlaceTile('Chợ Bến Thành', 'Quận 1, TP. Hồ Chí Minh', const LatLng(10.7725, 106.6980), ctx, nav),
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
      onTap: () {
        nav.selectSearchPlace(SearchPlace(name: name, description: desc, location: loc));
        Navigator.pop(ctx);
        _mapController.move(loc, 14.0);
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
      backgroundColor: const Color(0xFF0C131F),
      body: Stack(
        children: [
          // 1. BẢN ĐỒ TỐI ĐA ĐIỂM WAZE (SIÊU MƯỢT, 60FPS, TẢI TILE NHANH)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: nav.uiMode == AppUiMode.activeNavigation ? 16.5 : 12.8,
              maxZoom: 19.0,
              minZoom: 3.0,
              keepAlive: true,
              onTap: (tapPosition, point) {
                if (nav.uiMode != AppUiMode.activeNavigation) {
                  nav.setDestination(point);
                }
              },
            ),
            children: [
              // Tile Layer tải từ CDN đa luồng với bộ đệm cao keepBuffer: 6
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -0.80, 0.05, 0.05, 0, 230,
                  0.05, -0.80, 0.05, 0, 235,
                  0.10, 0.10, -0.75, 0, 245,
                  0, 0, 0, 1, 0,
                ]),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.esp32nav.app',
                  keepBuffer: 6,
                  maxZoom: 19.0,
                ),
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

                  // 3. Cảnh báo Công trường / Sự cố (Mũ bảo hộ công nhân 👷 giống Waze)
                  if (currentRoute != null && currentRoute.polyline.length > 10)
                    Marker(
                      point: currentRoute.polyline[currentRoute.polyline.length ~/ 2],
                      width: 38,
                      height: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.engineering_rounded, color: Colors.black, size: 22),
                        ),
                      ),
                    ),

                  // 4. HUY HIỆU THỜI GIAN TRÊN CÁC TUYẾN ĐƯỜNG (Ảnh 1)
                  if (nav.uiMode != AppUiMode.activeNavigation && routes.isNotEmpty) ...[
                    // Huy hiệu tuyến chính (Xanh Cyan "1h 11p Tốt nhất")
                    if (currentRoute != null && currentRoute.polyline.length > 15)
                      Marker(
                        point: currentRoute.polyline[currentRoute.polyline.length ~/ 3],
                        width: 110,
                        height: 46,
                        child: GestureDetector(
                          onTap: () => nav.selectRoute(nav.selectedRouteIndex),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D2FF),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentRoute.shortDurationFormatted,
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                                const Text(
                                  'Tốt nhất',
                                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Huy hiệu tuyến phụ (Màu Đen "1h 14p", "1h 16p")
                    for (int i = 0; i < routes.length; i++)
                      if (i != nav.selectedRouteIndex && routes[i].polyline.length > 15)
                        Marker(
                          point: routes[i].polyline[routes[i].polyline.length ~/ 2],
                          width: 80,
                          height: 32,
                          child: GestureDetector(
                            onTap: () => nav.selectRoute(i),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2634),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 6),
                                ],
                              ),
                              child: Text(
                                routes[i].shortDurationFormatted,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                  ],

                  // 5. MŨI TÊN 3D DẪN ĐƯỜNG KHI Ở ACTIVE NAVIGATION (Ảnh 2)
                  if (nav.uiMode == AppUiMode.activeNavigation)
                    Marker(
                      point: userPos,
                      width: 54,
                      height: 54,
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D2FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.navigation_rounded, color: Color(0xFF0B1426), size: 24),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ==========================================
          // 2. GIAO DIỆN CHẾ ĐỘ 1: XEM TRƯỚC LỘ TRÌNH (ẢNH 1)
          // ==========================================
          if (nav.uiMode == AppUiMode.previewMap) ...[
            // Hộp 2 Điểm Đi - Đến trên cùng
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Nút Back
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E2634)),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: () => _openSearchModal(context),
                        ),
                        const SizedBox(width: 8),

                        // Hộp Địa chỉ Đi & Đến
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openSearchModal(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2634).withAlpha(240),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 12),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.radio_button_checked, color: Colors.white70, size: 16),
                                            const SizedBox(width: 8),
                                            Text(nav.startAddressName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                          ],
                                        ),
                                        const Divider(color: Colors.white10, height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, color: Color(0xFF00D2FF), size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              nav.destinationName,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.swap_vert_rounded, color: Colors.white60, size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Nút Lọc "Tránh ⌵"
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2634),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Tránh', style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00D2FF), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Card Thời gian, Lộ trình & Nút Bắt đầu
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF12161E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab Handle (Chạm vào chuyển sang Tab Danh Sách Tuyến Đường - Ảnh 3)
                    Center(
                      child: GestureDetector(
                        onTap: () => nav.setUiMode(AppUiMode.previewList),
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Thời gian to & Quãng đường
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentRoute?.shortDurationFormatted ?? '1h 11p',
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          currentRoute?.formattedTotalDistance ?? '41,4 km',
                          style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Tên lộ trình chính & Trạng thái giao thông
                    Text(
                      currentRoute?.viaRoadName ?? 'Qua CT. Đại lộ Thăng Long Hà Nội',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Lộ trình tốt nhất, dù đông hơn bình thường',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Badge Cảnh báo nguy hiểm / thông thoáng
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2634),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFFEAB308), size: 10),
                          SizedBox(width: 6),
                          Text('Nguy hiểm', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2 Nút "Lên lịch trình" & "Bắt đầu"
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2634),
                              foregroundColor: const Color(0xFF00D2FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () => nav.setUiMode(AppUiMode.previewList),
                            child: const Text('Xem danh sách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D2FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () => nav.startNavigation(),
                            child: const Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
            // Top Turn Banner
            SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(245),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.u_turn_left_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${nav.distanceToNextStep.round()} m', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(nav.destinationName, style: const TextStyle(color: Color(0xFF00D2FF), fontSize: 17, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Selector "B.đồ" / "D.sách"
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2634),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => nav.setUiMode(AppUiMode.previewMap),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: const Text('B.đồ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0084FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('D.sách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Danh sách các thẻ Tuyến đường
            Positioned(
              top: 170,
              left: 16,
              right: 16,
              bottom: 20,
              child: ListView(
                children: [
                  for (int i = 0; i < (routes.isNotEmpty ? routes.length : 3); i++) ...[
                    _buildRouteCard(
                      duration: i == 0 ? '1 giờ 11 phút' : (i == 1 ? '1 giờ 14 phút' : '1 giờ 17 phút'),
                      etaAndDist: i == 0 ? '21:35  •  41 km' : (i == 1 ? '21:38  •  32 km' : '21:41  •  39 km'),
                      roadName: i == 0 ? 'Qua CT. Đại lộ Thăng Long Hà Nội' : (i == 1 ? 'Qua QL6 Hà Nội' : 'Qua Lương Thế Vinh Quảng Bị, Hà...'),
                      btnLabel: i == 0 ? '▲ Tiếp tục' : '▲ Xuất phát',
                      hasHelmet: i == 0 || i == 1,
                      isSelected: i == nav.selectedRouteIndex,
                      onTap: () {
                        nav.selectRoute(i);
                        nav.startNavigation();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],

          // ==========================================
          // 4. GIAO DIỆN CHẾ ĐỘ 3: DẪN ĐƯỜNG TRỰC TIẾP (ẢNH 2)
          // ==========================================
          if (nav.uiMode == AppUiMode.activeNavigation) ...[
            // Top Waze Turn Banner
            SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(245),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.u_turn_left_rounded, color: Colors.white, size: 42),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${nav.distanceToNextStep.round()} m',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            step?.streetName.isNotEmpty == true ? step!.streetName : nav.destinationName,
                            style: const TextStyle(color: Color(0xFF00D2FF), fontSize: 19, fontWeight: FontWeight.w800),
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
                onTap: () => _mapController.rotate(0.0),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(220),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 4, height: 22, color: Colors.white70),
                        Positioned(top: 0, child: Container(width: 4, height: 11, color: Colors.redAccent)),
                        const Icon(Icons.explore_rounded, color: Colors.white, size: 28),
                      ],
                    ),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BleDevicesScreen()));
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: nav.bleService.isConnected ? const Color(0xFF10B981) : Colors.black.withAlpha(220),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(220),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 24),
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
                  color: Colors.black.withAlpha(230),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${nav.currentSpeedKmh.round()}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const Text('km/h', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // Capsule Tên đường hiện tại ở giữa
            Positioned(
              bottom: 135,
              left: 95,
              right: 95,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(240),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  nav.destinationName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                              currentRoute?.arrivalTimeFormatted ?? '21:34',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              currentRoute?.durationAndDistanceFormatted ?? '1:11 h  •  41 km',
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
          // Thanh tiến trình với icon công trình
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
