import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class PhotoService {
  final ApiClient _api;

  PhotoService(this._api);

  Future<void> uploadPhoto({
    required String filePath,
    String? photoSpotId,
  }) async {
    final parsedPhotoSpotId =
        photoSpotId == null ? null : int.tryParse(photoSpotId);

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: 'photo.jpg'),
      'request': MultipartFile.fromString(
        jsonEncode({
          if (parsedPhotoSpotId != null) 'photoSpotId': parsedPhotoSpotId,
          'tip': 'temporary tip',
          'mood': 'CALM',
          'timeTag': 'AFTERNOON',
          'photoType': 'LANDSCAPE',
          'crowdLevel': 'NORMAL',
          'photoVisibility': 'PUBLIC',
        }),
        contentType: DioMediaType('application', 'json'),
      ),
    });

    await _api.dio.post('/api/photos', data: formData);
  }
}
