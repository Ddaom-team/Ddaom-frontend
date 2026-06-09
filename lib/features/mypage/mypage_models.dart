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
  final String id;
  final String imageUrl;
  const GridPhoto({required this.id, required this.imageUrl});

  static List<GridPhoto> mockList() => List.generate(
    9,
    (i) => GridPhoto(id: 'g$i', imageUrl: 'https://picsum.photos/seed/g$i/200/200'),
  );
}
