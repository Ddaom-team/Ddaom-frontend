import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/api_client.dart';
import '../../core/secure_storage.dart';
import 'auth_models.dart';

class GoogleAuthCancelled implements Exception {}

class GoogleAuthFailed implements Exception {
  final String message;
  GoogleAuthFailed(this.message);
  @override
  String toString() => message;
}

class AuthService {
  // 백엔드 idToken 검증의 audience로 쓰일 Web Client ID.
  // Google Cloud Console에서 OAuth Client(Web) 발급 후 교체.
  static const String _webClientId =
      '505282435869-e9l69k0s182bokeib91hu3l3mckojiiq.apps.googleusercontent.com';

  final ApiClient _api;
  final SecureStorage _storage;
  final GoogleSignIn _googleSignIn;

  AuthService(this._api, this._storage)
      : _googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'],
          serverClientId: _webClientId,
        );

  Future<LoginResponse> signInWithGoogle() async {
    if (_webClientId.startsWith('YOUR_')) {
      throw GoogleAuthFailed(
        'Google OAuth 자격증명이 아직 설정되지 않았습니다.\n'
        'docs/api/google-oauth-setup.md 를 참고해 발급 후\n'
        'auth_service.dart 와 ios/Runner/Info.plist 를 채워주세요.',
      );
    }
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw GoogleAuthCancelled();
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw GoogleAuthFailed('Google 인증 토큰을 가져올 수 없습니다.');
    }

    final res = await _api.dio.post(
      '/api/auth/google',
      data: {'idToken': idToken},
    );

    debugPrint('[AuthService] status: ${res.statusCode}');
    debugPrint('[AuthService] body: ${res.data}');
    debugPrint('[AuthService] authorization header: ${res.headers.value('authorization')}');

    // JWT는 항상 응답 헤더 Authorization: Bearer <jwt> 로 전달됨
    final authHeader = res.headers.value('authorization');
    if (authHeader == null || authHeader.isEmpty) {
      throw GoogleAuthFailed('서버로부터 JWT를 받지 못했습니다.');
    }
    final jwt = authHeader.replaceFirst(RegExp(r'Bearer\s+', caseSensitive: false), '');

    // 유저 정보: 바디가 직접 유저이거나 body['user']에 중첩될 수 있음
    final body = res.data as Map<String, dynamic>;
    final userJson = body.containsKey('user')
        ? body['user'] as Map<String, dynamic>
        : body;
    final user = User.fromJson(userJson);

    await _storage.saveSession(jwt, user);
    return LoginResponse(accessToken: jwt, tokenType: 'Bearer', expiresIn: 0, user: user);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.clear();
  }
}
