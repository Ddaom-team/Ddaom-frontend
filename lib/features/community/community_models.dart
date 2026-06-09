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
