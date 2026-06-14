import 'package:flutter_test/flutter_test.dart';
import 'package:ddaom_frontend/features/place/place_registration.dart';
import 'package:ddaom_frontend/features/home/home_models.dart';

void main() {
  Place mk(String id, double lat, double lng) => Place(
        id: id,
        name: id,
        address: '',
        photoSpotCount: 0,
        category: PlaceCategory.cafe,
        lat: lat,
        lng: lng,
      );

  group('findRegisteredNearby', () {
    final places = [mk('a', 37.5446, 127.0581), mk('b', 37.5000, 127.0000)];

    test('좌표가 가깝고 이름도 같으면 기존 장소를 찾는다', () {
      final hit = findRegisteredNearby(places, 37.54462, 127.05812, name: 'a');
      expect(hit?.id, 'a');
    });

    test('좌표가 가까워도 이름이 다르면 null (근처 다른 가게는 등록 허용)', () {
      final hit =
          findRegisteredNearby(places, 37.54462, 127.05812, name: '다른가게');
      expect(hit, isNull);
    });

    test('멀리 떨어진 좌표는 null', () {
      expect(findRegisteredNearby(places, 37.6000, 127.1000, name: 'a'), isNull);
    });

    test('빈 목록은 null', () {
      expect(findRegisteredNearby([], 37.5446, 127.0581, name: 'a'), isNull);
    });
  });
}
