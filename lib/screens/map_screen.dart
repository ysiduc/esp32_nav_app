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
  final FocusNode _searchFocus = FocusNode();

  bool _isMuted = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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
                  // Grab handle
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

                  // Thanh tìm kiếm Waze Search Bar
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
                              hintText: 'Tìm điểm đến (Tên đường, chung cư, địa chỉ)...',
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

                  const SizedBox(height: 16),

                  // Danh mục nhanh (Quick Category Pills)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('🏠 Nhà riêng', () {
                          _searchController.text = 'Nhà riêng';
                          nav.searchDestination('Định Công');
                        }),
                        _buildCategoryChip('🏢 Cơ quan', () {
                          _searchController.text = 'Cơ quan';
                          nav.searchDestination('Cầu Giấy');
                        }),
                        _buildCategoryChip('⛽ Cây xăng', () {
                          _searchController.text = 'Cây xăng';
                          nav.searchDestination('Cây xăng');
                        }),
                        _buildCategoryChip('☕ Quán Cafe', () {
                          _searchController.text = 'Cafe';
                          nav.searchDestination('Cafe');
                        }),
                        _buildCategoryChip('🅿️ Bãi đỗ xe', () {
                          _searchController.text = 'Bãi đỗ xe';
                          nav.searchDestination('Bãi đỗ xe');
                        }),
                        _buildCategoryChip('🏥 Bệnh viện', () {
                          _searchController.text = 'Bệnh viện';
                          nav.searchDestination('Bệnh viện');
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10),

                  // Danh sách kết quả gợi ý
                  Expanded(
                    child: isSearching
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF00D2FF)),
                          )
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
                                    title: Text(
                                      place.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      place.description,
                                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      nav.selectSearchPlace(place);
                                      Navigator.pop(ctx);
                                      _mapController.move(place.location, 16.5);
                                    },
                                  );
                                },
                              )
                            : ListView(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'ĐỊA ĐIỂM GỢI Ý PHỔ BIẾN',
                                      style: TextStyle(color: Color(0xFF00D2FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                                  ),
                                  _buildLandmarkTile(
                                    name: 'Nguyễn Cảnh Dị (Hoàng Mai)',
                                    address: 'Phường Định Công, Quận Hoàng Mai, Hà Nội',
                                    loc: const LatLng(20.9789, 105.8368),
                                    icon: Icons.alt_route_rounded,
                                    ctx: ctx,
                                    nav: nav,
                                  ),
                                  _buildLandmarkTile(
                                    name: 'Chung cư Smile Building',
                                    address: 'Số 1 Nguyễn Cảnh Dị, Định Công, Hoàng Mai, Hà Nội',
                                    loc: const LatLng(20.9765, 105.8392),
                                    icon: Icons.apartment_rounded,
                                    ctx: ctx,
                                    nav: nav,
                                  ),
                                  _buildLandmarkTile(
                                    name: 'Chung cư CT36B Định Công',
                                    address: 'Ngõ 177 Định Công, Hoàng Mai, Hà Nội',
                                    loc: const LatLng(20.9812, 105.8354),
                                    icon: Icons.apartment_rounded,
                                    ctx: ctx,
                                    nav: nav,
                                  ),
                                  _buildLandmarkTile(
                                    name: 'Hồ Hoàn Kiếm (Hồ Gươm)',
                                    address: 'Phường Hàng Trống, Quận Hoàn Kiếm, Hà Nội',
                                    loc: const LatLng(21.0287, 105.8524),
                                    icon: Icons.park_rounded,
                                    ctx: ctx,
                                    nav: nav,
                                  ),
                                  _buildLandmarkTile(
                                    name: 'Chợ Bến Thành (TP.HCM)',
                                    address: 'Đường Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM',
                                    loc: const LatLng(10.7725, 106.6980),
                                    icon: Icons.storefront_rounded,
                                    ctx: ctx,
                                    nav: nav,
                                  ),
                                  _buildLandmarkTile(
                                    name: 'Landmark 81',
                                    address: '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM',
                                    loc: const LatLng(10.7950, 106.7218),
                                    icon: Icons.business_rounded,
                                    ctx: ctx,
                                    nav: nav,
                                  ),
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

  Widget _buildCategoryChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF1E293B),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildLandmarkTile({
    required String name,
    required String address,
    required LatLng loc,
    required IconData icon,
    required BuildContext ctx,
    required NavigationProvider nav,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.cyanAccent, size: 20),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(address, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1),
      onTap: () {
        nav.selectSearchPlace(SearchPlace(name: name, description: address, location: loc));
        Navigator.pop(ctx);
        _mapController.move(loc, 16.5);
      },
    );
  }

  void _showToolsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101725),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final userPos = nav.userLocation ?? const LatLng(20.9789, 105.8368);
    final route = nav.currentRoute;
    final step = nav.currentStep;

    // Khoảng cách tới bước rẽ tiếp theo
    final distNext = nav.distanceToNextStep;
    final distNextStr = distNext >= 1000
        ? '${(distNext / 1000).toStringAsFixed(1)} km'
        : '${distNext.round()} m';

    // Tên đường rẽ tiếp theo & tên đường hiện tại
    final nextStreetName = step?.streetName.isNotEmpty == true ? step!.streetName : (nav.destinationName ?? 'Nguyễn Cảnh Dị');
    final currentStreetName = nav.destinationName ?? 'Nguyễn Cảnh Dị';

    return Scaffold(
      backgroundColor: const Color(0xFF0C131F),
      body: Stack(
        children: [
          // 1. WAZE DARK STYLE VECTOR-LIKE MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: 16.0,
              maxZoom: 19.0,
              onTap: (tapPosition, point) {
                if (!nav.isNavigating) {
                  nav.setDestination(point);
                }
              },
            ),
            children: [
              // Lớp bản đồ tối siêu sắc nét không Watermark phong cách Waze
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
                  maxZoom: 19.0,
                ),
              ),

              // Polyline Lộ trình phong cách Waze (Double Casing phát sáng Neon Cyan)
              if (route != null) ...[
                // Lớp viền ngoài (Glow casing)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route.polyline,
                      strokeWidth: 10.0,
                      color: const Color(0xFF0084FF).withAlpha(160),
                    ),
                    // Lớp phát sáng trung tâm Neon Cyan
                    Polyline(
                      points: route.polyline,
                      strokeWidth: 6.0,
                      color: const Color(0xFF00E5FF),
                    ),
                  ],
                ),
              ],

              // Marker Lộ trình, Vị trí xe & Biển Cảnh báo Giao thông (Waze Hazard)
              MarkerLayer(
                markers: [
                  // 1. Biển cảnh báo công trường / sự cố trên đường (Hazard Marker giống Waze)
                  if (route != null && route.polyline.length > 5)
                    Marker(
                      point: route.polyline[route.polyline.length ~/ 2],
                      width: 38,
                      height: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.construction_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                  // 2. Điểm đến đích (Destination Marker)
                  if (nav.destination != null)
                    Marker(
                      point: nav.destination!,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 44),
                    ),

                  // 3. MŨI TÊN DẪN ĐƯỜNG 3D PUCK (WAZE STYLE 3D NAVIGATOR ARROW)
                  Marker(
                    point: userPos,
                    width: 56,
                    height: 56,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Vòng tròn quầng sáng cyan
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00D2FF).withAlpha(40),
                              border: Border.all(color: const Color(0xFF00D2FF).withAlpha(120), width: 1.5),
                            ),
                          ),
                          // Mũi tên 3D Cyan
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D2FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Color(0xFF0B1426),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. THANH HƯỚNG RẼ TRÊN CÙNG (TOP WAZE TURN BANNER)
          SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(240),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  // Icon Rẽ to rõ màu trắng bên trái (U-Turn / Rẽ trái / Rẽ phải)
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      step?.icon ?? Icons.u_turn_left_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Khoảng cách rẽ to & Tên đường sắp rẽ màu Cyan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          distNextStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          nextStreetName,
                          style: const TextStyle(
                            color: Color(0xFF00D2FF),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
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

          // 3. WIDGETS NỔI TRÊN BẢN ĐỒ (COMPASS, AUDIO, ESP32 STATUS)
          // La bàn góc trên bên trái
          Positioned(
            top: 110,
            left: 18,
            child: GestureDetector(
              onTap: () {
                _mapController.rotate(0.0);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(210),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
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

          // Nút Âm thanh & Nhạc góc trên bên phải
          Positioned(
            top: 110,
            right: 18,
            child: Column(
              children: [
                // Nút Nhạc / Bluetooth ESP32
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BleDevicesScreen()),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: nav.bleService.isConnected ? const Color(0xFF10B981) : Colors.black.withAlpha(210),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Loa / Âm thanh chỉ đường
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
                      color: Colors.black.withAlpha(210),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 10, offset: const Offset(0, 3)),
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

          // 4. ĐỒNG HỒ TỐC ĐỘ (SPEEDOMETER) GÓC DƯỚI BÊN TRÁI
          Positioned(
            bottom: 125,
            left: 18,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(220),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${nav.currentSpeedKmh.round()}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.0),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'km/h',
                    style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 5. CAPSULE TÊN ĐƯỜNG HIỆN TẠI (STREET NAME PILL) Ở GIỮA
          Positioned(
            bottom: 135,
            left: 95,
            right: 95,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(235),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                currentStreetName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 6. NÚT CẢNH BÁO / BÁO CÁO SỰ CỐ (WAZE HAZARD REPORT BUTTON) GÓC DƯỚI PHẢI
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFEAB308).withAlpha(90), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 36),
                    const Positioned(
                      child: Icon(Icons.add, color: Colors.black, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 7. THANH ĐIỀU HƯỚNG BOTTOM (WAZE ARRIVAL & ROUTE BAR)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF12161E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grab Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nút Tìm kiếm 🔍
                      GestureDetector(
                        onTap: () => _openSearchModal(context),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E2634),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                        ),
                      ),

                      // Thông tin ETA to đậm ở giữa (21:25 | 1:11 h • 41 km)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openSearchModal(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                route != null ? route.arrivalTimeFormatted : '21:25',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                route != null ? route.durationAndDistanceFormatted : '1:11 h  •  41 km',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Nút Lộ trình phụ / Đổi hướng (🔀)
                      GestureDetector(
                        onTap: () {
                          // Gửi lộ trình sang ESP32 và đồng bộ
                          nav.sendMapVectorToEsp32();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đồng bộ lộ trình Waze sang ESP32!')),
                          );
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0084FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
