enum PhotoMood {
  CALM, COZY, EMOTIONAL, LONELY, ROMANTIC, DREAMY, VINTAGE, FRESH,
  HEALING, SENTIMENTAL, MODERN, CINEMATIC, QUIET, BRIGHT, NIGHT, NOSTALGIC;
}

extension PhotoMoodLabel on PhotoMood {
  String get label {
    switch (this) {
      case PhotoMood.CALM: return '잔잔한';
      case PhotoMood.COZY: return '아늑한';
      case PhotoMood.EMOTIONAL: return '감성적인';
      case PhotoMood.LONELY: return '외로운';
      case PhotoMood.ROMANTIC: return '로맨틱';
      case PhotoMood.DREAMY: return '몽환적인';
      case PhotoMood.VINTAGE: return '빈티지';
      case PhotoMood.FRESH: return '청량한';
      case PhotoMood.HEALING: return '힐링';
      case PhotoMood.SENTIMENTAL: return '감성';
      case PhotoMood.MODERN: return '모던';
      case PhotoMood.CINEMATIC: return '시네마틱';
      case PhotoMood.QUIET: return '고요한';
      case PhotoMood.BRIGHT: return '밝은';
      case PhotoMood.NIGHT: return '야경';
      case PhotoMood.NOSTALGIC: return '추억의';
    }
  }
}

enum PhotoTimeTag { MORNING, AFTERNOON, SUNSET, NIGHT }

extension PhotoTimeTagLabel on PhotoTimeTag {
  String get label {
    switch (this) {
      case PhotoTimeTag.MORNING: return '아침';
      case PhotoTimeTag.AFTERNOON: return '오후';
      case PhotoTimeTag.SUNSET: return '노을';
      case PhotoTimeTag.NIGHT: return '야간';
    }
  }
}

enum PhotoType { FULL_BODY, UPPER_BODY, SELFIE, FOOD, LANDSCAPE, ETC }

extension PhotoTypeLabel on PhotoType {
  String get label {
    switch (this) {
      case PhotoType.FULL_BODY: return '전신';
      case PhotoType.UPPER_BODY: return '상반신';
      case PhotoType.SELFIE: return '셀카';
      case PhotoType.FOOD: return '음식';
      case PhotoType.LANDSCAPE: return '풍경';
      case PhotoType.ETC: return '기타';
    }
  }
}

enum CrowdLevel { RELAXED, NORMAL, CROWDED, HARD_TO_SHOOT }

extension CrowdLevelLabel on CrowdLevel {
  String get label {
    switch (this) {
      case CrowdLevel.RELAXED: return '한산';
      case CrowdLevel.NORMAL: return '보통';
      case CrowdLevel.CROWDED: return '복잡';
      case CrowdLevel.HARD_TO_SHOOT: return '촬영어려움';
    }
  }
}

enum PhotoVisibility { PUBLIC, FRIENDS, PRIVATE }

extension PhotoVisibilityLabel on PhotoVisibility {
  String get label {
    switch (this) {
      case PhotoVisibility.PUBLIC: return '전체공개';
      case PhotoVisibility.FRIENDS: return '친구공개';
      case PhotoVisibility.PRIVATE: return '비공개';
    }
  }
}

class PhotoInfo {
  final int photoId;
  final int userId;
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
  final String? nickname;
  final String? profileImage;

  const PhotoInfo({
    required this.photoId,
    required this.userId,
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
    this.nickname,
    this.profileImage,
  });

  factory PhotoInfo.fromJson(Map<String, dynamic> json) => PhotoInfo(
        photoId: (json['photoId'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
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
        nickname: json['nickname'] as String?,
        profileImage: json['profileImage'] as String?,
      );
}

class PhotoLikeResult {
  final int photoId;
  final bool liked;
  final int likeCount;

  const PhotoLikeResult({
    required this.photoId,
    required this.liked,
    required this.likeCount,
  });

  factory PhotoLikeResult.fromJson(Map<String, dynamic> json) => PhotoLikeResult(
        photoId: (json['photoId'] as num).toInt(),
        liked: json['liked'] as bool,
        likeCount: (json['likeCount'] as num).toInt(),
      );
}

class PhotoUploadRequest {
  final String? photoSpotId;
  final String? tip;
  final PhotoMood mood;
  final PhotoTimeTag timeTag;
  final PhotoType photoType;
  final CrowdLevel crowdLevel;
  final PhotoVisibility photoVisibility;

  const PhotoUploadRequest({
    this.photoSpotId,
    this.tip,
    required this.mood,
    required this.timeTag,
    required this.photoType,
    required this.crowdLevel,
    required this.photoVisibility,
  });

  Map<String, dynamic> toJson() => {
    if (photoSpotId != null) 'photoSpotId': int.tryParse(photoSpotId!),
    if (tip != null && tip!.isNotEmpty) 'tip': tip,
    'mood': mood.name,
    'timeTag': timeTag.name,
    'photoType': photoType.name,
    'crowdLevel': crowdLevel.name,
    'photoVisibility': photoVisibility.name,
  };
}