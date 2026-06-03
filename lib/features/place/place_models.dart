enum PhotoZoneTag { indoor, outdoor, rooftop, window, entrance, staircase, view }

extension PhotoZoneTagLabel on PhotoZoneTag {
  String get label {
    switch (this) {
      case PhotoZoneTag.indoor: return '실내';
      case PhotoZoneTag.outdoor: return '야외';
      case PhotoZoneTag.rooftop: return '루프탑';
      case PhotoZoneTag.window: return '창가';
      case PhotoZoneTag.entrance: return '입구';
      case PhotoZoneTag.staircase: return '계단';
      case PhotoZoneTag.view: return '뷰맛집';
    }
  }
}

class PhotoZone {
  final String id;
  final String name;
  final String imageUrl;
  final int likeCount;
  final int saveCount;
  final List<PhotoZoneTag> tags;

  const PhotoZone({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.likeCount,
    required this.saveCount,
    required this.tags,
  });

  factory PhotoZone.fromJson(Map<String, dynamic> json) => PhotoZone(
    id: json['photoSpotId'].toString(),
    name: json['title'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? 'https://picsum.photos/seed/${json['photoSpotId']}/300/300',
    likeCount: 0,
    saveCount: 0,
    tags: [],
  );
}

class PlaceInfo {
  final String address;
  final String hours;
  final String? phone;

  const PlaceInfo({required this.address, required this.hours, this.phone});
}

class Review {
  final String id;
  final String userName;
  final String content;
  final int rating;

  const Review({
    required this.id,
    required this.userName,
    required this.content,
    required this.rating,
  });
}

class PlaceDetail {
  final String id;
  final String name;
  final String heroImageUrl;
  final double rating;
  final int reviewCount;
  final List<PhotoZone> photoZones;
  final PlaceInfo info;
  final List<Review> reviews;

  const PlaceDetail({
    required this.id,
    required this.name,
    required this.heroImageUrl,
    required this.rating,
    required this.reviewCount,
    required this.photoZones,
    required this.info,
    required this.reviews,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final spots = (json['photoSpots'] as List<dynamic>? ?? [])
        .map((e) => PhotoZone.fromJson(e as Map<String, dynamic>))
        .toList();
    final heroUrl = spots.isNotEmpty
        ? spots.first.imageUrl
        : 'https://picsum.photos/seed/default/600/400';
    return PlaceDetail(
      id: json['placeId'].toString(),
      name: json['name'] as String,
      heroImageUrl: heroUrl,
      rating: 0.0,
      reviewCount: 0,
      photoZones: spots,
      info: PlaceInfo(address: json['address'] as String? ?? '', hours: ''),
      reviews: [],
    );
  }

  static PlaceDetail mock() => const PlaceDetail(
    id: 'p1',
    name: 'onion 성수',
    heroImageUrl: 'https://picsum.photos/seed/hero1/600/400',
    rating: 4.7,
    reviewCount: 1234,
    photoZones: [
      PhotoZone(
        id: 'z1', name: '2층 창가 자리',
        imageUrl: 'https://picsum.photos/seed/z1/300/300',
        likeCount: 523, saveCount: 341,
        tags: [PhotoZoneTag.indoor, PhotoZoneTag.window],
      ),
      PhotoZone(
        id: 'z2', name: '종정 나무 앞',
        imageUrl: 'https://picsum.photos/seed/z2/300/300',
        likeCount: 287, saveCount: 198,
        tags: [PhotoZoneTag.outdoor],
      ),
      PhotoZone(
        id: 'z3', name: '입구 계단',
        imageUrl: 'https://picsum.photos/seed/z3/300/300',
        likeCount: 142, saveCount: 87,
        tags: [PhotoZoneTag.entrance, PhotoZoneTag.staircase],
      ),
    ],
    info: PlaceInfo(
      address: '서울 성동구 아차산로9길 8',
      hours: '월–금 10:00–21:00 / 토일 09:00–21:00',
      phone: '02-1234-5678',
    ),
    reviews: [
      Review(id: 'r1', userName: 'sunny_day', content: '2층 창가에서 찍은 사진이 최고예요!', rating: 5),
      Review(id: 'r2', userName: 'photo_lover', content: '주말엔 사람이 많아서 오전에 가세요.', rating: 4),
    ],
  );
}
