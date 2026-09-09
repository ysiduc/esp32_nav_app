enum MapLayerType {
  osmStandard,
  osmHot,
  esriSatellite,
  esriStreet,
  darkOSM,
  openTopo,
}

extension MapLayerExtension on MapLayerType {
  String get displayName {
    switch (this) {
      case MapLayerType.osmStandard:
        return 'OpenStreetMap (Tiêu chuẩn chính thức)';
      case MapLayerType.osmHot:
        return 'OpenStreetMap Nhân đạo (Màu sắc tươi sáng)';
      case MapLayerType.esriSatellite:
        return 'Ảnh Vệ Tinh (Esri World Imagery)';
      case MapLayerType.esriStreet:
        return 'Bản Đồ Đường Phố (Esri Street Map)';
      case MapLayerType.darkOSM:
        return 'Chế độ Ban đêm (Dark Mode)';
      case MapLayerType.openTopo:
        return 'Bản đồ Địa hình Đồi núi (OpenTopo)';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MapLayerType.osmStandard:
        return '🗺️';
      case MapLayerType.osmHot:
        return '🎨';
      case MapLayerType.esriSatellite:
        return '🛰️';
      case MapLayerType.esriStreet:
        return '🛣️';
      case MapLayerType.darkOSM:
        return '🌙';
      case MapLayerType.openTopo:
        return '🏔️';
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapLayerType.osmStandard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayerType.osmHot:
        return 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
      case MapLayerType.esriSatellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.esriStreet:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.darkOSM:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapLayerType.openTopo:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> get subdomains {
    switch (this) {
      case MapLayerType.osmStandard:
        return const [];
      case MapLayerType.osmHot:
        return const ['a', 'b', 'c'];
      case MapLayerType.esriSatellite:
      case MapLayerType.esriStreet:
        return const [];
      case MapLayerType.darkOSM:
        return const ['a', 'b', 'c', 'd'];
      case MapLayerType.openTopo:
        return const ['a', 'b', 'c'];
    }
  }

  int get maxZoom {
    switch (this) {
      case MapLayerType.osmStandard:
      case MapLayerType.osmHot:
        return 19;
      case MapLayerType.esriSatellite:
        return 18;
      case MapLayerType.esriStreet:
        return 19;
      case MapLayerType.darkOSM:
        return 20;
      case MapLayerType.openTopo:
        return 17;
    }
  }

  bool get isDarkMode => this == MapLayerType.darkOSM;
}
