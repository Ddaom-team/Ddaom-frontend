// lib/core/place_repository.dart
import 'api_client.dart';
import '../features/home/home_models.dart';

abstract class PlaceRepository {
  Future<List<Place>> fetchPlaces();

  Future<List<Place>> fetchPopularPlaces({
    PlaceCategory? category,
    int limit = 12,
  });
}

class MockPlaceRepository implements PlaceRepository {
  @override
  Future<List<Place>> fetchPlaces() async => Place.mockList();

  @override
  Future<List<Place>> fetchPopularPlaces({
    PlaceCategory? category,
    int limit = 12,
  }) async {
    final places = category == null || category == PlaceCategory.all
        ? Place.mockList()
        : Place.mockList().where((place) => place.category == category).toList();
    return places.take(limit).toList();
  }
}

class ApiPlaceRepository implements PlaceRepository {
  final ApiClient _api;
  ApiPlaceRepository(this._api);

  @override
  Future<List<Place>> fetchPlaces() async {
    final res = await _api.dio.get('/api/places');
    final list = res.data as List<dynamic>;
    return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Place>> fetchPopularPlaces({
    PlaceCategory? category,
    int limit = 12,
  }) async {
    final res = await _api.dio.get(
      '/api/places/popular',
      queryParameters: {
        'limit': limit,
        if (category != null && category != PlaceCategory.all)
          'category': category.label,
      },
    );
    final list = res.data as List<dynamic>;
    return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }
}
