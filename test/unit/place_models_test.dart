import 'package:flutter_test/flutter_test.dart';
import 'package:ddaom_frontend/features/place/place_models.dart';

void main() {
  group('PlaceDetail.mock', () {
    test('photoZones가 1개 이상이다', () {
      expect(PlaceDetail.mock().photoZones.isNotEmpty, true);
    });

    test('각 PhotoZone은 tags 리스트를 갖는다', () {
      for (final zone in PlaceDetail.mock().photoZones) {
        expect(zone.tags, isA<List<PhotoZoneTag>>());
      }
    });

    test('reviews가 1개 이상이다', () {
      expect(PlaceDetail.mock().reviews.isNotEmpty, true);
    });
  });

  group('PhotoZone.fromJson', () {
    test('imageUrl이 없으면 null (picsum 하드코딩 안 함)', () {
      final z = PhotoZone.fromJson({'photoSpotId': 1, 'title': '창가'});
      expect(z.imageUrl, isNull);
    });

    test('imageUrl이 있으면 그대로 사용', () {
      final z = PhotoZone.fromJson(
          {'photoSpotId': 1, 'title': '창가', 'imageUrl': 'http://x/a.jpg'});
      expect(z.imageUrl, 'http://x/a.jpg');
    });
  });

  group('PlaceDetail.fromJson 대표 이미지', () {
    test('thumbnailUrl이 있으면 heroImageUrl로 사용', () {
      final d = PlaceDetail.fromJson({
        'placeId': 1,
        'name': '카페',
        'thumbnailUrl': 'http://x/thumb.jpg',
        'photoSpots': [
          {'photoSpotId': 1, 'title': 's', 'imageUrl': 'http://x/spot.jpg'}
        ],
      });
      expect(d.heroImageUrl, 'http://x/thumb.jpg');
    });

    test('thumbnailUrl이 없으면 첫 포토스팟 이미지로 대체', () {
      final d = PlaceDetail.fromJson({
        'placeId': 1,
        'name': '카페',
        'photoSpots': [
          {'photoSpotId': 1, 'title': 's', 'imageUrl': 'http://x/spot.jpg'}
        ],
      });
      expect(d.heroImageUrl, 'http://x/spot.jpg');
    });

    test('썸네일도 포토스팟도 없으면 null', () {
      final d = PlaceDetail.fromJson(
          {'placeId': 1, 'name': '카페', 'photoSpots': []});
      expect(d.heroImageUrl, isNull);
    });
  });
}
