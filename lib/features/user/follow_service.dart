// lib/features/user/follow_service.dart
import '../../core/api_client.dart';

class FollowCounts {
  final int followerCount;
  final int followingCount;
  const FollowCounts({required this.followerCount, required this.followingCount});

  factory FollowCounts.fromJson(Map<String, dynamic> json) => FollowCounts(
    followerCount: (json['followerCount'] as num).toInt(),
    followingCount: (json['followingCount'] as num).toInt(),
  );
}

class FollowService {
  final ApiClient _api;
  FollowService(this._api);

  Future<void> follow(int userId) async {
    await _api.dio.post('/api/follows/$userId');
  }

  Future<void> unfollow(int userId) async {
    await _api.dio.delete('/api/follows/$userId');
  }

  Future<FollowCounts> getCounts(int userId) async {
    final res = await _api.dio.get('/api/follows/$userId/counts');
    return FollowCounts.fromJson(res.data as Map<String, dynamic>);
  }

  // NOTE: checks only the first page of followers. If the backend paginates
  // this endpoint, users appearing on later pages will always read as not-following.
  Future<bool> isFollowing(int userId) async {
    final res = await _api.dio.get('/api/follows/$userId/followers');
    final list = res.data as List<dynamic>;
    return list.any((item) => (item as Map<String, dynamic>)['me'] == true);
  }
}
