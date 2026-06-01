import 'package:flutter/foundation.dart';

import 'home_models.dart';

class HomeProvider extends ChangeNotifier {
  PlaceCategory _selectedCategory = PlaceCategory.all;
  final List<Place> _allPlaces = Place.mockList();

  PlaceCategory get selectedCategory => _selectedCategory;

  List<Place> get filteredPlaces {
    if (_selectedCategory == PlaceCategory.all) return _allPlaces;
    return _allPlaces.where((p) => p.category == _selectedCategory).toList();
  }

  void setCategory(PlaceCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }
}
