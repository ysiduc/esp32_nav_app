enum MapLayerType {
  openFreeMapLiberty,
  openFreeMapBright,
  openFreeMapPositron,
  openFreeMapDark,
  openFreeMapFiord,
}

extension MapLayerExtension on MapLayerType {
  String get displayName {
    switch (this) {
      case MapLayerType.openFreeMapLiberty:
        return 'OpenFreeMap Liberty (Sống động & Tòa nhà 3D)';
      case MapLayerType.openFreeMapBright:
        return 'OpenFreeMap Bright (Ban ngày tươi sáng)';
      case MapLayerType.openFreeMapPositron:
        return 'OpenFreeMap Positron (Tối giản thanh lịch)';
      case MapLayerType.openFreeMapDark:
        return 'OpenFreeMap Dark (Chế độ ban đêm)';
      case MapLayerType.openFreeMapFiord:
        return 'OpenFreeMap Fiord (Tông màu lạnh)';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MapLayerType.openFreeMapLiberty:
        return '🏙️';
      case MapLayerType.openFreeMapBright:
        return '☀️';
      case MapLayerType.openFreeMapPositron:
        return '⚪';
      case MapLayerType.openFreeMapDark:
        return '🌙';
      case MapLayerType.openFreeMapFiord:
        return '🌊';
    }
  }

  String get styleUrl {
    switch (this) {
      case MapLayerType.openFreeMapLiberty:
        return 'https://tiles.openfreemap.org/styles/liberty';
      case MapLayerType.openFreeMapBright:
        return 'https://tiles.openfreemap.org/styles/bright';
      case MapLayerType.openFreeMapPositron:
        return 'https://tiles.openfreemap.org/styles/positron';
      case MapLayerType.openFreeMapDark:
        return 'https://tiles.openfreemap.org/styles/dark';
      case MapLayerType.openFreeMapFiord:
        return 'https://tiles.openfreemap.org/styles/fiord';
    }
  }

  String get pbfUrlTemplate => 'https://tiles.openfreemap.org/planet/{z}/{x}/{y}.pbf';

  bool get isDarkMode => this == MapLayerType.openFreeMapDark;
}
