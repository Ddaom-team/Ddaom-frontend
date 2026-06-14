import 'package:flutter_test/flutter_test.dart';
import 'package:ddaom_frontend/features/place/naver_place_search_service.dart';

void main() {
  group('NaverPlace.fromJson', () {
    test('title의 HTML 태그를 제거한다', () {
      final p = NaverPlace.fromJson({
        'title': '<b>어니언</b> 성수',
        'category': '카페,디저트',
        'roadAddress': '서울 성동구 아차산로9길 8',
        'address': '서울 성동구 성수동',
        'telephone': '',
        'mapx': '1270556000',
        'mapy': '375445000',
      });
      expect(p.name, '어니언 성수');
    });

    test('mapx/mapy를 1e7로 나눠 좌표로 변환한다', () {
      final p = NaverPlace.fromJson({
        'title': 'x', 'category': '', 'roadAddress': '', 'address': '',
        'telephone': '', 'mapx': '1270556000', 'mapy': '375445000',
      });
      expect(p.lng, closeTo(127.0556, 0.0001));
      expect(p.lat, closeTo(37.5445, 0.0001));
    });

    test('빈 telephone은 null이 된다', () {
      final p = NaverPlace.fromJson({
        'title': 'x', 'category': '', 'roadAddress': '', 'address': '',
        'telephone': '', 'mapx': '0', 'mapy': '0',
      });
      expect(p.telephone, isNull);
    });

    test('displayAddress는 도로명 우선, 없으면 지번', () {
      final road = NaverPlace.fromJson({
        'title': 'x', 'category': '', 'roadAddress': 'road', 'address': 'jibun',
        'telephone': '02', 'mapx': '0', 'mapy': '0',
      });
      final jibun = NaverPlace.fromJson({
        'title': 'x', 'category': '', 'roadAddress': '', 'address': 'jibun',
        'telephone': '02', 'mapx': '0', 'mapy': '0',
      });
      expect(road.displayAddress, 'road');
      expect(jibun.displayAddress, 'jibun');
    });
  });

  group('mapNaverCategory', () {
    test('카페 우선 매칭', () => expect(mapNaverCategory('음식점>카페'), '카페'));
    test('음식점→식당', () => expect(mapNaverCategory('음식점>한식'), '식당'));
    test('미술관→전시', () => expect(mapNaverCategory('미술관'), '전시'));
    test('팝업', () => expect(mapNaverCategory('생활,편의>팝업스토어'), '팝업'));
    test('매칭 실패 시 카페', () => expect(mapNaverCategory('교통,운송>주차장'), '카페'));
  });
}
