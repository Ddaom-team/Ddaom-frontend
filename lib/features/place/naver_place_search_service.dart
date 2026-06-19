import '../../core/api_client.dart';

/// 네이버 지역 검색 결과 한 건.
class NaverPlace {
  final String name;
  final String category;
  final String roadAddress;
  final String address;
  final String? telephone;
  final double lat;
  final double lng;

  const NaverPlace({
    required this.name,
    required this.category,
    required this.roadAddress,
    required this.address,
    required this.telephone,
    required this.lat,
    required this.lng,
  });

  /// 표시용 주소: 도로명 우선, 없으면 지번.
  String get displayAddress => roadAddress.isNotEmpty ? roadAddress : address;

  factory NaverPlace.fromJson(Map<String, dynamic> json) {
    final tel = json['telephone'] as String? ?? '';
    return NaverPlace(
      name: _stripTags(json['title'] as String? ?? ''),
      category: json['category'] as String? ?? '',
      roadAddress: json['roadAddress'] as String? ?? '',
      address: json['address'] as String? ?? '',
      telephone: tel.isEmpty ? null : tel,
      lng: _coord(json['mapx']),
      lat: _coord(json['mapy']),
    );
  }
}

String _stripTags(String s) =>
    s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&amp;', '&');

/// 지역 검색 mapx/mapy는 WGS84 좌표 × 10^7 정수 문자열.
double _coord(dynamic v) {
  final n = double.tryParse(v?.toString() ?? '') ?? 0;
  return n / 1e7;
}

/// 네이버 카테고리 문자열을 우리 태그로 매핑(정보 카드의 초기 추정값). 매칭 실패 시 '카페'.
/// (카페가 음식점 하위로 올 수 있어 카페를 먼저 검사한다.)
String mapNaverCategory(String naverCategory) {
  final c = naverCategory;
  if (c.contains('카페') || c.contains('커피')) return '카페';
  if (c.contains('술집') ||
      c.contains('바') ||
      c.contains('포차') ||
      c.contains('호프') ||
      c.contains('와인') ||
      c.contains('펍') ||
      c.contains('주점')) {
    return '술집';
  }
  if (c.contains('음식') || c.contains('식당') || c.contains('레스토랑')) return '식당';
  if (c.contains('전시') || c.contains('미술') || c.contains('박물관') || c.contains('갤러리')) {
    return '전시';
  }
  if (c.contains('팝업')) return '팝업';
  if (c.contains('노래') ||
      c.contains('오락') ||
      c.contains('게임') ||
      c.contains('볼링') ||
      c.contains('당구') ||
      c.contains('스크린') ||
      c.contains('PC')) {
    return '오락';
  }
  if (c.contains('쇼핑') ||
      c.contains('편의점') ||
      c.contains('마트') ||
      c.contains('백화점') ||
      c.contains('소품') ||
      c.contains('시장') ||
      c.contains('상가')) {
    return '쇼핑';
  }
  if (c.contains('공원') ||
      c.contains('관광') ||
      c.contains('명소') ||
      c.contains('해변') ||
      c.contains('해수욕장') ||
      c.contains('산')) {
    return '명소';
  }
  if (c.contains('야경') || c.contains('전망')) return '야경';
  return '카페';
}

/// 네이버 검색을 백엔드 프록시(`/api/places/search`)를 통해 호출한다.
/// Client ID/Secret은 서버에만 두어 앱 번들에 노출되지 않는다.
class NaverPlaceSearchService {
  final ApiClient _api;
  NaverPlaceSearchService(this._api);

  Future<List<NaverPlace>> search(String query) async {
    try {
      final res = await _api.dio.get(
        '/api/places/search',
        queryParameters: {'query': query, 'display': 5},
      );
      final items = res.data as List<dynamic>? ?? [];
      return items
          .map((e) => NaverPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 장소 대표 이미지로 쓸 이미지 URL을 네이버 이미지 검색으로 가져온다.
  /// 네이버 지도엔 공식 장소사진 API가 없어 이미지 검색(웹 이미지)을 사용한다.
  /// 백엔드가 네이버 CDN 썸네일을 우선 반환하며, 결과가 없거나 실패하면 null.
  Future<String?> searchImage(String query) async {
    try {
      final res = await _api.dio.get(
        '/api/places/search/image',
        queryParameters: {'query': query},
      );
      final data = res.data as Map<String, dynamic>?;
      final url = data?['imageUrl'] as String?;
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (_) {
      return null;
    }
  }
}
