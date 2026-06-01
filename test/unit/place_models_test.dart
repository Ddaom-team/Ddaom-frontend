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
}
