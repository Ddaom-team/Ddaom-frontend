import '../../core/api_client.dart';
import '../photo/photo_models.dart';

class UserProfile {
  final int userId;
  final String name;
  final String? avatarUrl;
  final int followingCount;
  final int followerCount;

  const UserProfile({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.followingCount,
    required this.followerCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: (json['userId'] as num).toInt(),
    name: (json['nickname'] ?? json['name'] ?? json['email'] ?? '사용자').toString(),
    avatarUrl: (json['profileImage'] ?? json['avatarUrl']) as String?,
    followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
  );

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    int? followingCount,
    int? followerCount,
  }) => UserProfile(
    userId: userId,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    followingCount: followingCount ?? this.followingCount,
    followerCount: followerCount ?? this.followerCount,
  );
}

class GridPhoto {
  final int photoId;
  final String id;
  final String imageUrl;
  final String authorName;
  final String authorAvatarUrl;
  final String location;
  final List<String> hashtags;
  final int likeCount;
  final bool liked;

  const GridPhoto({
    required this.photoId,
    required this.id,
    required this.imageUrl,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.location,
    required this.hashtags,
    required this.likeCount,
    this.liked = false,
  });

  factory GridPhoto.fromPhotoInfo(PhotoInfo photo) {
    final url = photo.photoUrl;
    final imageUrl = (url.startsWith('http://') || url.startsWith('https://'))
        ? url
        : '${ApiClient.baseUrl}$url';
    return GridPhoto(
      photoId: photo.photoId,
      id: 'photo_${photo.photoId}',
      imageUrl: imageUrl,
      authorName: '',
      authorAvatarUrl: '',
      location: '',
      hashtags: const [],
      likeCount: photo.likeCount,
      liked: photo.liked,
    );
  }

  static List<GridPhoto> mockMyPhotos() {
    final locations = ['경복궁', '북촌한옥마을', '성수동', '홍대거리', '한강공원', '망원시장', '서울숲', '인사동', '남산타워'];
    final tagSets = [
      ['포토존', '서울여행'], ['한옥', '데이트'], ['카페거리', '스냅'],
      ['감성사진', '홍대'], ['한강', '빈티지'], ['시장', '필름'],
      ['서울숲', '봄'], ['인사동', '전통'], ['남산', '야경'],
    ];
    final likeCounts = [12, 34, 7, 58, 3, 21, 9, 45, 16];
    return List.generate(9, (i) => GridPhoto(
      photoId: i + 1,
      id: 'm$i',
      imageUrl: 'https://picsum.photos/seed/myphoto$i/400/400',
      authorName: '나',
      authorAvatarUrl: 'https://picsum.photos/seed/myavatar/100/100',
      location: locations[i % locations.length],
      hashtags: tagSets[i % tagSets.length],
      likeCount: likeCounts[i % likeCounts.length],
    ));
  }

  static List<GridPhoto> mockLikedPhotos() {
    final names = ['지윤', '민서', '하린', '서아', '예린', '도현', '채원', '준호', '하아'];
    final locations = ['광화문', '동대문DDP', '창덕궁', '서울숲', '한강공원', '홍대거리', '성수동', '북촌', '망원시장'];
    final tagSets = [
      ['광화문', '야간'], ['DDP', '건축'], ['창덕궁', '궁궐'],
      ['서울숲', '벚꽃'], ['한강', '석양'], ['홍대', '스냅'],
      ['성수', '감성'], ['북촌', '한옥'], ['망원', '필름'],
    ];
    final likeCounts = [89, 143, 57, 312, 76, 204, 33, 167, 91];
    return List.generate(9, (i) => GridPhoto(
      photoId: i + 101,
      id: 'l$i',
      imageUrl: 'https://picsum.photos/seed/liked$i/400/400',
      authorName: names[i % names.length],
      authorAvatarUrl: 'https://picsum.photos/seed/lavatar$i/100/100',
      location: locations[i % locations.length],
      hashtags: tagSets[i % tagSets.length],
      likeCount: likeCounts[i % likeCounts.length],
      liked: true,
    ));
  }
}