// lib/core/place_repository.dart
import 'api_client.dart';
import '../features/home/home_models.dart';

abstract class PlaceRepository {
  Future<List<Place>> fetchPlaces();
}

class MockPlaceRepository implements PlaceRepository {
  @override
  Future<List<Place>> fetchPlaces() async => Place.mockList();
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
}
