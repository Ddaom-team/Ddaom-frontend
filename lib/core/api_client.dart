import 'package:dio/dio.dart';

import 'secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.55.62:8080'; // 임서현 실기기
  // static const String baseUrl = 'http://10.0.2.2:8080'; // 로컬 테스트 (안드로이드 에뮬레이터)

  final Dio dio;
  final SecureStorage _storage;
  void Function()? onUnauthorized;

  ApiClient(this._storage)
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final jwt = await _storage.readJwt();
        if (jwt != null) {
          options.headers['Authorization'] = 'Bearer $jwt';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // 모든 응답이 { code, message, data } 형태이므로 data 필드만 추출
        final body = response.data;
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          response.data = body['data'];
        }
        handler.next(response);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          await _storage.clear();
          onUnauthorized?.call();
        }
        handler.next(e);
      },
    ));
  }
}
