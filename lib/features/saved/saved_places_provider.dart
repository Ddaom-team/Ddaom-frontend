import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../home/home_models.dart';

class SavedPlacesProvider extends ChangeNotifier {
  final ApiClient _api;
  List<Place> _places = [];
  bool isLoading = false;
  String? error;

  SavedPlacesProvider(this._api) {
    load();
  }

  List<Place> get places => _places;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/places/saves/me');
      final list = res.data as List<dynamic>;
      _places = list
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      error = '저장한 장소를 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
