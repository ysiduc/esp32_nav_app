import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/map_layer_type.dart';
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
  bool _isSearchExpanded = false;

  // Địa điểm phổ biến gợi ý nhanh
  final List<SearchPlace> _popularPlaces = [
    SearchPlace(
      name: 'Hồ Hoàn Kiếm (Hà Nội)',
      description: 'Phường Hàng Trống, Quận Hoàn Kiếm, Hà Nội',
      location: const LatLng(21.0287, 105.8524),
      type: 'tourism',
    ),
    SearchPlace(
      name: 'Chợ Bến Thành (TP.HCM)',
      description: 'Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
      location: const LatLng(10.7725, 106.6980),
      type: 'tourism',
    ),
    SearchPlace(
      name: 'Sân bay Quốc tế Nội Bài',
      description: 'Phú Cường, Sóc Sơn, Hà Nội',
      location: const LatLng(21.2212, 105.8072),
      type: 'airport',
    ),
    SearchPlace(
      name: 'Cầu Rồng (Đà Nẵng)',
      description: 'Đường Nguyễn Văn Linh, Phước Ninh, Hải Châu, Đà Nẵng',
      location: const LatLng(16.0610, 108.2272),
      type: 'tourism',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSelectPlace(SearchPlace place) {
    final nav = context.read<NavigationProvider>();
    _searchFocus.unfocus();
    setState(() {
      _isSearchExpanded = false;
      _searchController.text = place.name;
    });
    nav.selectSearchPlace(place);
    _mapController.move(place.location, 16.0);
  }

  void _showLayerSelectionModal(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
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
                Row(
                  children: [
                    const Icon(Icons.layers_rounded, color: Color(0xFF00E5FF), size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Lớp Bản Đồ (Không Watermark)',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...MapLayerType.values.map((layer) {
                  final isSelected = nav.currentMapLayer == layer;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00E5FF).withAlpha(30) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Text(layer.iconEmoji, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        layer.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF))
                          : null,
                      onTap: () {
                        nav.setMapLayer(layer);
                        Navigator.pop(ctx);
                      },
                    ),
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
    final userPos = nav.userLocation ?? const LatLng(21.028511, 105.854444);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Stack(
        children: [
          // 1. OPENSTREETMAP TILE LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: 15.0,
              maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
              onTap: (tapPosition, point) {
                if (_searchFocus.hasFocus) {
                  _searchFocus.unfocus();
                }
                setState(() {
                  _isSearchExpanded = false;
                });
                if (!nav.isNavigating) {
                  nav.setDestination(point);
                }
              },
            ),
            children: [
              // Tile Layer với Dark Filter nếu chọn Dark OSM
              if (nav.currentMapLayer.isDarkMode)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -0.85, 0, 0, 0, 240,
                    0, -0.85, 0, 0, 240,
                    0, 0, -0.85, 0, 240,
                    0, 0, 0, 1, 0,
                  ]),
                  child: TileLayer(
                    urlTemplate: nav.currentMapLayer.urlTemplate,
                    subdomains: nav.currentMapLayer.subdomains,
                    userAgentPackageName: 'com.esp32nav.app',
                    maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
                  ),
                )
              else
                TileLayer(
                  urlTemplate: nav.currentMapLayer.urlTemplate,
                  subdomains: nav.currentMapLayer.subdomains,
                  userAgentPackageName: 'com.esp32nav.app',
                  maxZoom: nav.currentMapLayer.maxZoom.toDouble(),
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

              // Markers
              MarkerLayer(
                markers: [
                  // Marker Vị trí người dùng
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
                  // Marker Điểm đến
                  if (nav.destination != null)
                    Marker(
                      point: nav.destination!,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 44),
                    ),
                ],
              ),
            ],
          ),

          // 2. THANH TÌM KIẾM & CÔNG CỤ TRÊN CÙNG
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // THANH TÌM KIẾM ĐỊA ĐIỂM (SEARCH BAR)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withAlpha(245),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isSearchExpanded ? const Color(0xFF00E5FF) : Colors.white24,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 14, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên đường, địa chỉ hoặc tọa độ...',
                              hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E5FF), size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        nav.clearSearchResults();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (text) {
                              setState(() {
                                _isSearchExpanded = true;
                              });
                              nav.searchDestination(text);
                            },
                            onSubmitted: (text) {
                              nav.searchDestination(text);
                            },
                            onTap: () {
                              setState(() {
                                _isSearchExpanded = true;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Nút Chọn Lớp Bản Đồ
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                        icon: Text(nav.currentMapLayer.iconEmoji, style: const TextStyle(fontSize: 18)),
                        tooltip: 'Chọn Lớp Bản Đồ',
                        onPressed: () => _showLayerSelectionModal(context),
                      ),
                      const SizedBox(width: 6),

                      // Nút BLE
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: nav.bleService.isConnected ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                        ),
                        icon: Icon(
                          nav.bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Quản lý Bluetooth ESP32',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BleDevicesScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // DANH SÁCH GỢI Ý TÌM KIẾM / ĐỊA ĐIỂM PHỔ BIẾN
                if (_isSearchExpanded)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF00E5FF).withAlpha(120)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: nav.isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2.5),
                                  SizedBox(height: 12),
                                  Text('Đang tìm kiếm trên OpenStreetMap...', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        : (nav.searchResults.isNotEmpty)
                            ? ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: nav.searchResults.length,
                                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                                itemBuilder: (context, index) {
                                  final SearchPlace place = nav.searchResults[index];
                                  return ListTile(
                                    leading: Icon(place.icon, color: const Color(0xFF00E5FF), size: 22),
                                    title: Text(
                                      place.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      place.description,
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _onSelectPlace(place),
                                  );
                                },
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                                    child: Text(
                                      'GỢI Ý ĐỊA ĐIỂM PHỔ BIẾN',
                                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                                    ),
                                  ),
                                  ..._popularPlaces.map(
                                    (place) => ListTile(
                                      leading: Icon(place.icon, color: const Color(0xFF00E5FF), size: 20),
                                      title: Text(place.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      subtitle: Text(place.description, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1),
                                      onTap: () => _onSelectPlace(place),
                                    ),
                                  ),
                                ],
                              ),
                  ),
              ],
            ),
          ),

          // 3. CARD CHỈ ĐƯỜNG TRỰC TIẾP (TURN-BY-TURN HUD) KHI ĐANG DẪN ĐƯỜNG
          if (nav.isNavigating && nav.currentStep != null)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withAlpha(240),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E5FF).withAlpha(80)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 16, offset: const Offset(0, 6)),
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

          // 4. FLOATING BUTTONS
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                // Nút Định vị vị trí hiện tại
                FloatingActionButton.small(
                  heroTag: 'my_loc_btn',
                  backgroundColor: const Color(0xFF0F172A),
                  child: const Icon(Icons.my_location_rounded, color: Color(0xFF00E5FF)),
                  onPressed: () {
                    if (nav.userLocation != null) {
                      _mapController.move(nav.userLocation!, 16.0);
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Nút Mở Giả Lập ESP32
                FloatingActionButton.small(
                  heroTag: 'esp32_hud_btn',
                  backgroundColor: const Color(0xFF0F172A),
                  child: const Icon(Icons.developer_board_rounded, color: Colors.cyanAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Esp32SimulatorScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Nút Mở Hướng dẫn Cuộc gọi ANCS
                FloatingActionButton.small(
                  heroTag: 'ancs_btn',
                  backgroundColor: const Color(0xFF0F172A),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AncsGuideScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // 5. HUD TỐC ĐỘ (SPEED GAUGE)
          if (nav.isNavigating)
            Positioned(
              bottom: 190,
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

          // 6. THANH ĐIỀU KHIỂN DƯỚI CÙNG (BOTTOM NAVIGATION SHEET)
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
                    // Tên điểm đến đã chọn
                    if (nav.destinationName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                nav.destinationName!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: Color(0xFF00E5FF), size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tìm kiếm nơi đến ở thanh trên hoặc chạm vào bản đồ để tạo lộ trình chỉ đường OSRM',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
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
