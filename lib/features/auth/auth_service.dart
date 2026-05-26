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
      'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';

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
    final body = res.data as Map<String, dynamic>;
    final login = LoginResponse.fromJson(body);
    await _storage.saveSession(login.accessToken, login.user);
    return login;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.clear();
  }
}
