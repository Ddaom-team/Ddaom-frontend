// lib/features/home/home_models.dart
enum PlaceCategory { all, cafe, restaurant, popup, exhibition, nightView }

extension PlaceCategoryLabel on PlaceCategory {
  String get label {
    switch (this) {
      case PlaceCategory.all: return '전체';
      case PlaceCategory.cafe: return '카페';
      case PlaceCategory.restaurant: return '식당';
      case PlaceCategory.popup: return '팝업';
      case PlaceCategory.exhibition: return '전시';
      case PlaceCategory.nightView: return '야경';
    }
  }

  static PlaceCategory fromApiString(String? s) {
    switch (s) {
      case '카페': return PlaceCategory.cafe;
      case '식당': return PlaceCategory.restaurant;
      case '팝업': return PlaceCategory.popup;
      case '전시': return PlaceCategory.exhibition;
      case '야경': return PlaceCategory.nightView;
      default: return PlaceCategory.all;
    }
  }
}

class Place {
  final String id;           // placeId.toString()
  final String name;
  final String address;
  final String? thumbnailUrl;
  final int photoSpotCount;
  final PlaceCategory category;
  final double lat;
  final double lng;

  const Place({
    required this.id,
    required this.name,
    required this.address,
    this.thumbnailUrl,
    required this.photoSpotCount,
    required this.category,
    required this.lat,
    required this.lng,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['placeId'].toString(),
    name: json['name'] as String,
    address: json['address'] as String? ?? '',
    thumbnailUrl: json['thumbnailUrl'] as String?,
    photoSpotCount: (json['photoSpotCount'] as num).toInt(),
    category: PlaceCategoryLabel.fromApiString(json['category'] as String?),
    lat: (json['latitude'] as num).toDouble(),
    lng: (json['longitude'] as num).toDouble(),
  );

  static List<Place> mockList() => const [
    Place(id: 'p1', name: 'onion 성수', address: '서울 성동구 아차산로9길 8',
      photoSpotCount: 8, category: PlaceCategory.cafe, lat: 37.5447, lng: 127.0557),
    Place(id: 'p2', name: '대림창고', address: '서울 성동구 연무장길 3',
      photoSpotCount: 5, category: PlaceCategory.cafe, lat: 37.5441, lng: 127.0561),
    Place(id: 'p3', name: '경양식 1920', address: '서울 성동구 성수이로 78',
      photoSpotCount: 3, category: PlaceCategory.restaurant, lat: 37.5451, lng: 127.0548),
  ];
}
