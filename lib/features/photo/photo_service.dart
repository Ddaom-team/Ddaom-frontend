import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import 'photo_models.dart';

class PhotoService {
  final ApiClient _api;

  PhotoService(this._api);

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