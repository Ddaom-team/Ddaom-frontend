import '../../core/api_client.dart';
import 'community_models.dart';

class CommunityService {
  final ApiClient _api;

  CommunityService(this._api);

  Future<List<CommunityUser>> searchUsers(String query) async {
    final res = await _api.dio.get(
      '/api/users/search',
      queryParameters: {'query': query},
    );
    final items = res.data as List<dynamic>;
    return items
        .map((json) => CommunityUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> follow(int userId) async {
    await _api.dio.post('/api/follows/$userId');
  }

  Future<void> unfollow(int userId) async {
    await _api.dio.delete('/api/follows/$userId');
  }

  Future<Map<String, dynamic>> likePhoto(int photoId) async {
    final res = await _api.dio.post('/api/photos/$photoId/likes');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlikePhoto(int photoId) async {
    final res = await _api.dio.delete('/api/photos/$photoId/likes');
    return res.data['data'] as Map<String, dynamic>;
  }
}
