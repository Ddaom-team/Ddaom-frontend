import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../core/place_repository.dart';
import 'home_models.dart';

class HomeProvider extends ChangeNotifier {
  final PlaceRepository _repository;

  HomeProvider(this._repository) {
    loadPlaces();
  }

  PlaceCategory _selectedCategory = PlaceCategory.all;
  List<Place> _allPlaces = [];
  String? selectedPlaceId;
  NaverMapController? mapController;
  bool isLoading = false;
  String? error;

  PlaceCategory get selectedCategory => _selectedCategory;

  List<Place> get filteredPlaces {
    if (_selectedCategory == PlaceCategory.all) return List.unmodifiable(_allPlaces);
    return _allPlaces.where((p) => p.category == _selectedCategory).toList();
  }

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
}
