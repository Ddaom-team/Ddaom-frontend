import '../../core/api_client.dart';
import '../home/home_models.dart';
import '../home/home_provider.dart';
import 'naver_place_search_service.dart';

enum RegisterOutcome { success, duplicate, failure }

/// 좌표가 거의 같고(약 50m 이내) 이름도 같거나 포함 관계인 이미 등록된 장소를 찾는다.
/// 없으면 null. 한 장소를 한 번만 등록하도록 중복 검사에 사용한다.
/// 좌표만 보면 같은 거리/건물의 다른 가게까지 중복으로 막히므로 이름도 함께 비교한다.
/// (시드 데이터는 좌표가 절단돼 한 격자에 여럿 뭉쳐 있어 더욱 필요.)
Place? findRegisteredNearby(
  List<Place> places,
  double lat,
  double lng, {
  required String name,
  double epsilon = 0.0005,
}) {
  final target = _normalizeName(name);
  for (final p in places) {
    final near = (p.lat - lat).abs() < epsilon && (p.lng - lng).abs() < epsilon;
    if (!near) continue;
    final pn = _normalizeName(p.name);
    // 이름을 비교할 수 없으면(빈 값) 좌표만으로 중복 처리.
    if (target.isEmpty || pn.isEmpty) return p;
    if (pn == target || pn.contains(target) || target.contains(pn)) return p;
  }
  return null;
}

String _normalizeName(String s) =>
    s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

/// 네이버 장소를 따옴에 등록한다.
/// [category]는 사용자가 정보 카드에서 고른 태그, [address]는 입력/수정한 주소.
/// 이미 등록된 장소면 등록하지 않고 [RegisterOutcome.duplicate]를 반환한다.
/// 성공 시 홈 장소 목록을 갱신한다.
Future<RegisterOutcome> registerNaverPlace({
  required ApiClient api,
  required HomeProvider home,
  required NaverPlace place,
  required PlaceCategory category,
  required String address,
}) async {
  if (findRegisteredNearby(home.allPlaces, place.lat, place.lng,
          name: place.name) !=
      null) {
    return RegisterOutcome.duplicate;
  }
  // 장소 대표 이미지를 네이버 이미지 검색으로 채운다(없으면 생략).
  String? thumbnailUrl;
  try {
    thumbnailUrl = await NaverPlaceSearchService().searchImage(place.name);
  } catch (_) {
    thumbnailUrl = null;
  }
  try {
    await api.dio.post('/api/places', data: {
      'name': place.name,
      'address': address,
      'category': category.label,
      'latitude': place.lat,
      'longitude': place.lng,
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
        'thumbnailUrl': thumbnailUrl,
    });
    await home.loadPlaces();
    return RegisterOutcome.success;
  } catch (_) {
    return RegisterOutcome.failure;
  }
}
