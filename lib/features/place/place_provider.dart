// lib/features/place/place_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import 'place_models.dart';

class PlaceProvider extends ChangeNotifier {
  final String placeId;
  final ApiClient _api;
  PlaceDetail? _detail;
  PhotoZoneTag? _selectedTag;
  bool isLoading = false;
  String? error;

  PlaceProvider(this.placeId, this._api) {
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

  /// 등록 등으로 데이터가 바뀐 뒤 상세를 다시 불러온다.
  Future<void> reload() => _load();

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/places/$placeId');
      _detail = PlaceDetail.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      error = '장소 정보를 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
