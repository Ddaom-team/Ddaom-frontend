import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import 'photo_models.dart';

class PhotoService {
  final ApiClient _api;

  PhotoService(this._api);

  Future<PhotoInfo> getPhoto(int photoId) async {
    final res = await _api.dio.get('/api/photos/$photoId');
    return PhotoInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PhotoInfo>> getMyPhotos() async {
    final res = await _api.dio.get('/api/photos/me');
    final items = res.data as List<dynamic>;
    return items
        .map((json) => PhotoInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PhotoInfo>> getUserPhotos(int userId) async {
    final res = await _api.dio.get('/api/photos/users/$userId');
    final items = res.data as List<dynamic>;
    return items
        .map((json) => PhotoInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PhotoInfo>> getPhotosByPhotoSpot(int photoSpotId) async {
    final res = await _api.dio
        .get('/api/photos', queryParameters: {'photoSpotId': photoSpotId});
    final items = res.data as List<dynamic>;
    return items
        .map((json) => PhotoInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PhotoInfo>> getLikedPhotos() async {
    final res = await _api.dio.get('/api/photos/likes/me');
    final items = res.data as List<dynamic>;
    return items
        .map((json) => PhotoInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PhotoInfo>> getTopPhotos() async {
    final res = await _api.dio.get('/api/photos/likes/top');
    final items = res.data as List<dynamic>;
    return items
        .map((json) => PhotoInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PhotoLikeResult> likePhoto(int photoId) async {
    final res = await _api.dio.post('/api/photos/$photoId/likes');
    return PhotoLikeResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PhotoLikeResult> unlikePhoto(int photoId) async {
    final res = await _api.dio.delete('/api/photos/$photoId/likes');
    return PhotoLikeResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> uploadPhoto({
    required String filePath,
    required PhotoUploadRequest request,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: 'photo.jpg'),
      'request': MultipartFile.fromString(
        jsonEncode(request.toJson()),
        contentType: DioMediaType('application', 'json'),
      ),
    });

    await _api.dio.post('/api/photos', data: formData);
  }
}