import 'package:ddaom_frontend/features/photo/photo_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PhotoInfo parses ddaomCount and defaults it to zero', () {
    final baseJson = <String, dynamic>{
      'photoId': 1,
      'userId': 2,
      'photoUrl': 'https://example.com/photo.jpg',
      'mood': 'CALM',
      'timeTag': 'AFTERNOON',
      'photoType': 'LANDSCAPE',
      'crowdLevel': 'NORMAL',
      'photoVisibility': 'PUBLIC',
      'createdAt': '2026-06-21T12:00:00',
    };

    expect(PhotoInfo.fromJson({...baseJson, 'ddaomCount': 7}).ddaomCount, 7);
    expect(PhotoInfo.fromJson(baseJson).ddaomCount, 0);
  });

  test('PhotoUploadRequest sends sourcePhotoId only for derived photos', () {
    const common = PhotoUploadRequest(
      sourcePhotoId: 42,
      mood: PhotoMood.CALM,
      timeTag: PhotoTimeTag.AFTERNOON,
      photoType: PhotoType.LANDSCAPE,
      crowdLevel: CrowdLevel.NORMAL,
      photoVisibility: PhotoVisibility.PUBLIC,
    );
    const normal = PhotoUploadRequest(
      mood: PhotoMood.CALM,
      timeTag: PhotoTimeTag.AFTERNOON,
      photoType: PhotoType.LANDSCAPE,
      crowdLevel: CrowdLevel.NORMAL,
      photoVisibility: PhotoVisibility.PUBLIC,
    );

    expect(common.toJson()['sourcePhotoId'], 42);
    expect(normal.toJson().containsKey('sourcePhotoId'), isFalse);
  });
}
