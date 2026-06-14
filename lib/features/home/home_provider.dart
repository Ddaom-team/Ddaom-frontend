import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../core/place_repository.dart';
import 'home_models.dart';

class Region {
  final String name;
  final double lat;
  final double lng;
  const Region({required this.name, required this.lat, required this.lng});

  String get titleLabel {
    final code = name.codeUnits.last;
    final hasJongseong =
        (code >= 0xAC00 && code <= 0xD7A3) && (code - 0xAC00) % 28 != 0;
    return '지금, $name${hasJongseong ? '은' : '는'}?';
  }

  static const List<Region> presets = [
    Region(name: '성수동', lat: 37.5445, lng: 127.0556),
    Region(name: '홍대', lat: 37.5563, lng: 126.9239),
    Region(name: '이태원', lat: 37.5349, lng: 126.9946),
    Region(name: '연남동', lat: 37.5620, lng: 126.9249),
    Region(name: '삼청동', lat: 37.5793, lng: 126.9797),
    Region(name: '명동', lat: 37.5636, lng: 126.9855),
    Region(name: '강남', lat: 37.4979, lng: 127.0276),
    Region(name: '잠실', lat: 37.5133, lng: 127.1001),
    Region(name: '인하대', lat: 37.4499, lng: 126.6537),
    Region(name: '간석역', lat: 37.4765, lng: 126.7041),
    Region(name: '주안역', lat: 37.4607, lng: 126.6849),
    Region(name: '부평', lat: 37.4891, lng: 126.7224),
    Region(name: '송도', lat: 37.3826, lng: 126.6622),
    Region(name: '차이나타운', lat: 37.4762, lng: 126.6174),
    Region(name: '월미도', lat: 37.4752, lng: 126.5970),
    Region(name: '해운대', lat: 35.1587, lng: 129.1603),
    Region(name: '광안리', lat: 35.1530, lng: 129.1186),
    Region(name: '감천문화마을', lat: 35.0979, lng: 129.0106),
  ];
}

class HomeProvider extends ChangeNotifier {
  final PlaceRepository _repository;

  HomeProvider(this._repository) {
    loadPlaces();
  }

  Region _selectedRegion = Region.presets.first;
  PlaceCategory _selectedCategory = PlaceCategory.all;
  List<Place> _allPlaces = [];
  String? selectedPlaceId;
  NaverMapController? mapController;
  bool isLoading = false;
  String? error;

  Region get selectedRegion => _selectedRegion;

  void setRegion(Region region) {
    if (_selectedRegion.name == region.name) return;
    _selectedRegion = region;
    notifyListeners();
    loadPlaces();
  }

  PlaceCategory get selectedCategory => _selectedCategory;

  List<Place> get filteredPlaces {
    if (_selectedCategory == PlaceCategory.all) return List.unmodifiable(_allPlaces);
    return _allPlaces.where((p) => p.category == _selectedCategory).toList();
  }

  /// 등록된 전체 장소(중복 등록 검사용 — 카테고리 필터와 무관).
  List<Place> get allPlaces => List.unmodifiable(_allPlaces);

  Future<void> loadPlaces() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _allPlaces = await _repository.fetchPlaces();
    } catch (_) {
      error = '장소를 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(PlaceCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void selectPlace(String id) {
    if (selectedPlaceId == id) return;
    selectedPlaceId = id;
    notifyListeners();
  }

  void clearSelection() {
    if (selectedPlaceId == null) return;
    selectedPlaceId = null;
    notifyListeners();
  }

  void registerMapController(NaverMapController controller) {
    mapController = controller;
    notifyListeners();
  }

  void moveToRegion(Region region) {
    mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(region.lat, region.lng),
        zoom: 15,
      ),
    );
  }
}
