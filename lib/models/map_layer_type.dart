enum MapLayerType {
  darkOSM,
  osmStandard,
  osmHot,
  esriStreet,
  esriSatellite,
  openTopo,
}

extension MapLayerExtension on MapLayerType {
  String get displayName {
    switch (this) {
      case MapLayerType.darkOSM:
        return 'Chế độ Tối Waze (Dark Map - Siêu Mượt)';
      case MapLayerType.osmStandard:
        return 'OSM Standard (Tiêu chuẩn OpenStreetMap)';
      case MapLayerType.osmHot:
        return 'OSM Humanitarian (Màu sắc rõ nét)';
      case MapLayerType.esriStreet:
        return 'Esri Street (Đường phố chi tiết cao)';
      case MapLayerType.esriSatellite:
        return 'Esri Satellite (Ảnh vệ tinh thực tế)';
      case MapLayerType.openTopo:
        return 'OpenTopo (Bản đồ địa hình đồi núi)';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MapLayerType.darkOSM:
        return '🌙';
      case MapLayerType.osmStandard:
        return '🗺️';
      case MapLayerType.osmHot:
        return '🎨';
      case MapLayerType.esriStreet:
        return '🛣️';
      case MapLayerType.esriSatellite:
        return '🛰️';
      case MapLayerType.openTopo:
        return '🏔️';
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapLayerType.darkOSM:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapLayerType.osmStandard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayerType.osmHot:
        return 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
      case MapLayerType.esriStreet:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.esriSatellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.openTopo:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> get subdomains {
    switch (this) {
      case MapLayerType.darkOSM:
        return const ['a', 'b', 'c', 'd'];
      case MapLayerType.osmStandard:
        return const [];
      case MapLayerType.osmHot:
        return const ['a', 'b', 'c'];
      case MapLayerType.esriStreet:
      case MapLayerType.esriSatellite:
        return const [];
      case MapLayerType.openTopo:
        return const ['a', 'b', 'c'];
    }
  }

  int get maxZoom {
    switch (this) {
      case MapLayerType.darkOSM:
        return 20;
      case MapLayerType.osmStandard:
      case MapLayerType.osmHot:
        return 19;
      case MapLayerType.esriStreet:
        return 19;
      case MapLayerType.esriSatellite:
        return 18;
      case MapLayerType.openTopo:
        return 17;
    }
  }

  bool get isDarkMode => this == MapLayerType.darkOSM;
}
