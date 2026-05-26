import 'package:flutter/foundation.dart';

import '../../core/secure_storage.dart';
import 'auth_models.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final SecureStorage _storage;

  User? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._service, this._storage);

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> bootstrap() async {
    _user = await _storage.readUser();
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.signInWithGoogle();
      _user = res.user;
      return true;
    } on GoogleAuthCancelled {
      return false;
    } on GoogleAuthFailed catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = '로그인 실패: ${e.toString()}';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    notifyListeners();
  }
}
