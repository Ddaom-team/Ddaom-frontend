import 'package:flutter_test/flutter_test.dart';
import 'package:ddaom_frontend/core/place_repository.dart';
import 'package:ddaom_frontend/features/home/home_provider.dart';
import 'package:ddaom_frontend/features/home/home_models.dart';

class _FakeRepo implements PlaceRepository {
  @override
  Future<List<Place>> fetchPlaces() async => Place.mockList();

  @override
  Future<List<Place>> fetchPopularPlaces({
    PlaceCategory? category,
    int limit = 12,
  }) async {
    final places = Place.mockList().reversed.where(
          (place) =>
              category == null ||
              category == PlaceCategory.all ||
              place.category == category,
        );
    return places.take(limit).toList();
  }
}

class _FailingRepo implements PlaceRepository {
  @override
  Future<List<Place>> fetchPlaces() async => throw Exception('network error');

  @override
  Future<List<Place>> fetchPopularPlaces({
    PlaceCategory? category,
    int limit = 12,
  }) async => throw Exception('network error');
}

void main() {
  group('HomeProvider', () {
    test('loadPlaces populates filteredPlaces', () async {
      final provider = HomeProvider(_FakeRepo());
      await Future.delayed(Duration.zero);
      expect(provider.filteredPlaces, isNotEmpty);
    });

    test('popularPlaces preserves repository popularity order', () async {
      final provider = HomeProvider(_FakeRepo());
      await Future.delayed(Duration.zero);
      expect(provider.popularPlaces.first.id, Place.mockList().last.id);
    });

    test('selectPlace sets selectedPlaceId', () async {
      final provider = HomeProvider(_FakeRepo());
      await Future.delayed(Duration.zero);
      provider.selectPlace('p1');
      expect(provider.selectedPlaceId, 'p1');
    });

    test('selectPlace same id is idempotent', () async {
      final provider = HomeProvider(_FakeRepo());
      await Future.delayed(Duration.zero);
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.selectPlace('p1');
      provider.selectPlace('p1');
      expect(notifyCount, 1);
    });

    test('clearSelection sets selectedPlaceId to null', () async {
      final provider = HomeProvider(_FakeRepo());
      await Future.delayed(Duration.zero);
      provider.selectPlace('p1');
      provider.clearSelection();
      expect(provider.selectedPlaceId, isNull);
    });

    test('setCategory filters filteredPlaces', () async {
      final provider = HomeProvider(_FakeRepo());
      await Future.delayed(Duration.zero);
      provider.setCategory(PlaceCategory.cafe);
      expect(provider.filteredPlaces.every((p) => p.category == PlaceCategory.cafe), isTrue);
    });

    test('loadPlaces failure sets error', () async {
      final provider = HomeProvider(_FailingRepo());
      await Future.delayed(Duration.zero);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });
}
