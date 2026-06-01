import 'package:flutter/foundation.dart';

import 'place_models.dart';

class PlaceProvider extends ChangeNotifier {
  final String placeId;
  PlaceDetail? _detail;
  PhotoZoneTag? _selectedTag;

  PlaceProvider(this.placeId) {
    _load();
  }

  PlaceDetail? get detail => _detail;
  PhotoZoneTag? get selectedTag => _selectedTag;

  List<PhotoZone> get filteredZones {
    if (_detail == null) return [];
    if (_selectedTag == null) return _detail!.photoZones;
    return _detail!.photoZones.where((z) => z.tags.contains(_selectedTag)).toList();
  }

  Set<PhotoZoneTag> get availableTags {
    if (_detail == null) return {};
    return _detail!.photoZones.expand((z) => z.tags).toSet();
  }

  void setTag(PhotoZoneTag? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void _load() {
    // Mock: 실 API 전환 시 ApiClient 호출로 교체
    _detail = PlaceDetail.mock();
    notifyListeners();
  }
}
