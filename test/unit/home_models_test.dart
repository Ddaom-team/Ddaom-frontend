import 'package:flutter_test/flutter_test.dart';
import 'package:ddaom_frontend/features/home/home_models.dart';

void main() {
  group('Place.mockList', () {
    test('5개의 장소를 반환한다', () {
      expect(Place.mockList().length, 5);
    });

    test('각 장소는 id, name, imageUrl, photoZoneCount를 갖는다', () {
      for (final place in Place.mockList()) {
        expect(place.id.isNotEmpty, true);
        expect(place.name.isNotEmpty, true);
        expect(place.photoZoneCount, greaterThan(0));
      }
    });

    test('카페 카테고리 장소가 1개 이상 있다', () {
      final cafes = Place.mockList().where((p) => p.category == PlaceCategory.cafe);
      expect(cafes.isNotEmpty, true);
    });
  });
}
