import '../features/home/home_models.dart';

abstract class PlaceRepository {
  Future<List<Place>> fetchPlaces();
}

class MockPlaceRepository implements PlaceRepository {
  @override
  Future<List<Place>> fetchPlaces() async => Place.mockList();
}
