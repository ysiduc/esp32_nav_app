enum MapLayerType {
  osmStandard,
  esriSatellite,
  cartoDark,
  cartoVoyager,
  openTopo,
}

extension MapLayerExtension on MapLayerType {
  String get displayName {
    switch (this) {
      case MapLayerType.osmStandard:
        return 'OSM Standard (Mặc định)';
      case MapLayerType.esriSatellite:
        return 'Esri Satellite (Ảnh vệ tinh)';
      case MapLayerType.cartoDark:
        return 'Dark Matter (Ban đêm)';
      case MapLayerType.cartoVoyager:
        return 'Voyager (Đường phố rõ nét)';
      case MapLayerType.openTopo:
        return 'OpenTopo (Bản đồ địa hình)';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MapLayerType.osmStandard:
        return '🗺️';
      case MapLayerType.esriSatellite:
        return '🛰️';
      case MapLayerType.cartoDark:
        return '🌙';
      case MapLayerType.cartoVoyager:
        return '🏙️';
      case MapLayerType.openTopo:
        return '🏔️';
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapLayerType.osmStandard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayerType.esriSatellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.cartoDark:
        return 'https://a.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png';
      case MapLayerType.cartoVoyager:
        return 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
      case MapLayerType.openTopo:
        return 'https://a.tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> get subdomains {
    switch (this) {
      case MapLayerType.osmStandard:
        return const ['a', 'b', 'c'];
      case MapLayerType.esriSatellite:
        return const [];
      case MapLayerType.cartoDark:
      case MapLayerType.cartoVoyager:
        return const ['a', 'b', 'c', 'd'];
      case MapLayerType.openTopo:
        return const ['a', 'b', 'c'];
    }
  }

  int get maxZoom {
    switch (this) {
      case MapLayerType.osmStandard:
        return 19;
      case MapLayerType.esriSatellite:
        return 18;
      case MapLayerType.cartoDark:
      case MapLayerType.cartoVoyager:
        return 20;
      case MapLayerType.openTopo:
        return 17;
    }
  }
}
