class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final int followingCount;
  final int followerCount;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.followingCount,
    required this.followerCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'].toString(),
    name: (json['name'] ?? json['email'] ?? '사용자').toString(),
    avatarUrl: json['avatarUrl'] as String?,
    followingCount: json['followingCount'] as int? ?? 0,
    followerCount: json['followerCount'] as int? ?? 0,
  );

  UserProfile copyWith({String? name, String? avatarUrl}) => UserProfile(
    id: id,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    followingCount: followingCount,
    followerCount: followerCount,
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
