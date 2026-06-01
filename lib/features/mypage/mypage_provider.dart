import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import 'mypage_models.dart';

class MyPageProvider extends ChangeNotifier {
  final ApiClient _api;
  UserProfile? _profile;
  bool _loading = false;
  String? _error;

  MyPageProvider(this._api);

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/users/me');
      _profile = parseResponse(res, (d) => UserProfile.fromJson(d as Map<String, dynamic>));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void updateProfile({String? name, String? avatarUrl}) {
    if (_profile == null) return;
    _profile = _profile!.copyWith(name: name, avatarUrl: avatarUrl);
    notifyListeners();
  }
}
