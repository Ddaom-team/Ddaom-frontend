import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../mypage/mypage_models.dart';

class UserService {
  final ApiClient _api;
  UserService(this._api);

  Future<UserProfile> getUserProfile(int userId) async {
    final res = await _api.dio.get('/api/users/$userId');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  // 실제 사용: SecureStorage에서 JWT를 인터셉터가 자동 주입
  Future<Map<String, dynamic>> getMe() async {
    final res = await _api.dio.get('/api/users/me');
    return res.data as Map<String, dynamic>;
  }

  // 테스트용: JWT를 직접 지정해서 호출 (하드코딩 테스트에 사용)
  Future<void> getMeDebug(String jwt) async {
    try {
      debugPrint('[getMeDebug] GET /api/users/me 호출 중...');
      final res = await _api.dio.get(
        '/api/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $jwt'},
        ),
      );
      debugPrint('[getMeDebug] 응답 status: ${res.statusCode}');
      debugPrint('[getMeDebug] 응답 body: ${res.data}');

      // 예상 필드 존재 여부 확인
      final data = res.data as Map<String, dynamic>;
      for (final key in ['email', 'nickname', 'profileImage']) {
        debugPrint(
          '[getMeDebug] "$key": ${data.containsKey(key) ? data[key] : "❌ 없음"}',
        );
      }
    } on DioException catch (e) {
      debugPrint('[getMeDebug] 오류: ${e.response?.statusCode} ${e.response?.data}');
    } catch (e) {
      debugPrint('[getMeDebug] 예외: $e');
    }
  }
}
