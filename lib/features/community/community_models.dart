import '../photo/photo_models.dart';

class FollowingPhoto {
  final int photoId;
  final int userId;
  final String nickname;
  final String? profileImage;
  final int? photoSpotId;
  final String? photoSpotTitle;
  final int? placeId;
  final String? placeName;
  final String photoUrl;
  final String? tip;
  final PhotoMood mood;
  final PhotoTimeTag timeTag;
  final PhotoType photoType;
  final CrowdLevel crowdLevel;
  final PhotoVisibility photoVisibility;
  final String createdAt;
  final bool liked;
  final int likeCount;

  const FollowingPhoto({
    required this.photoId,
    required this.userId,
    required this.nickname,
    this.profileImage,
    this.photoSpotId,
    this.photoSpotTitle,
    this.placeId,
    this.placeName,
    required this.photoUrl,
    this.tip,
    required this.mood,
    required this.timeTag,
    required this.photoType,
    required this.crowdLevel,
    required this.photoVisibility,
    required this.createdAt,
    this.liked = false,
    this.likeCount = 0,
  });

  factory FollowingPhoto.fromJson(Map<String, dynamic> json) => FollowingPhoto(
        photoId: (json['photoId'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        nickname: (json['nickname'] ?? '사용자').toString(),
        profileImage: json['profileImage'] as String?,
        photoSpotId: (json['photoSpotId'] as num?)?.toInt(),
        photoSpotTitle: json['photoSpotTitle'] as String?,
        placeId: (json['placeId'] as num?)?.toInt(),
        placeName: json['placeName'] as String?,
        photoUrl: json['photoUrl'] as String,
        tip: json['tip'] as String?,
        mood: PhotoMood.values.firstWhere(
          (e) => e.name == json['mood'],
          orElse: () => PhotoMood.CALM,
        ),
        timeTag: PhotoTimeTag.values.firstWhere(
          (e) => e.name == json['timeTag'],
          orElse: () => PhotoTimeTag.AFTERNOON,
        ),
        photoType: PhotoType.values.firstWhere(
          (e) => e.name == json['photoType'],
          orElse: () => PhotoType.LANDSCAPE,
        ),
        crowdLevel: CrowdLevel.values.firstWhere(
          (e) => e.name == json['crowdLevel'],
          orElse: () => CrowdLevel.NORMAL,
        ),
        photoVisibility: PhotoVisibility.values.firstWhere(
          (e) => e.name == json['photoVisibility'],
          orElse: () => PhotoVisibility.PUBLIC,
        ),
        createdAt: json['createdAt'] as String,
        liked: json['liked'] as bool? ?? false,
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      );
}

class CommunityUser {
  final int userId;
  final String email;
  final String nickname;
  final String? profileImage;
  final bool me;
  final bool following;

  const CommunityUser({
    required this.userId,
    required this.email,
    required this.nickname,
    this.profileImage,
    required this.me,
    required this.following,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) => CommunityUser(
        userId: (json['userId'] as num).toInt(),
        email: (json['email'] ?? '').toString(),
        nickname: (json['nickname'] ?? json['email'] ?? '사용자').toString(),
        profileImage: json['profileImage'] as String?,
        me: json['me'] as bool? ?? false,
        following: json['following'] as bool? ?? false,
      );

  CommunityUser copyWith({bool? following}) => CommunityUser(
        userId: userId,
        email: email,
        nickname: nickname,
        profileImage: profileImage,
        me: me,
        following: following ?? this.following,
      );
}
