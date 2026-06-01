enum PlaceCategory { all, cafe, restaurant, popup, exhibition, nightView }

extension PlaceCategoryLabel on PlaceCategory {
  String get label {
    switch (this) {
      case PlaceCategory.all:
        return '전체';
      case PlaceCategory.cafe:
        return '카페';
      case PlaceCategory.restaurant:
        return '식당';
      case PlaceCategory.popup:
        return '팝업';
      case PlaceCategory.exhibition:
        return '전시';
      case PlaceCategory.nightView:
        return '야경';
    }
  }
}

class Place {
  final String id;
  final String name;
  final String imageUrl;
  final int photoZoneCount;
  final PlaceCategory category;
  final double lat;
  final double lng;

  const Place({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.photoZoneCount,
    required this.category,
    required this.lat,
    required this.lng,
  });

  static List<Place> mockList() => const [
        Place(
          id: 'p1',
          name: 'onion 성수',
          imageUrl: 'https://picsum.photos/seed/p1/300/200',
          photoZoneCount: 8,
          category: PlaceCategory.cafe,
          lat: 37.5447,
          lng: 127.0557,
        ),
        Place(
          id: 'p2',
          name: '대림창고',
          imageUrl: 'https://picsum.photos/seed/p2/300/200',
          photoZoneCount: 5,
          category: PlaceCategory.cafe,
          lat: 37.5441,
          lng: 127.0561,
        ),
        Place(
          id: 'p3',
          name: '경양식 1920',
          imageUrl: 'https://picsum.photos/seed/p3/300/200',
          photoZoneCount: 3,
          category: PlaceCategory.restaurant,
          lat: 37.5451,
          lng: 127.0548,
        ),
        Place(
          id: 'p4',
          name: '성수 팝업 스토어',
          imageUrl: 'https://picsum.photos/seed/p4/300/200',
          photoZoneCount: 6,
          category: PlaceCategory.popup,
          lat: 37.5438,
          lng: 127.0573,
        ),
        Place(
          id: 'p5',
          name: '서울숲 야경 포인트',
          imageUrl: 'https://picsum.photos/seed/p5/300/200',
          photoZoneCount: 4,
          category: PlaceCategory.nightView,
          lat: 37.5443,
          lng: 127.0378,
        ),
      ];
}
