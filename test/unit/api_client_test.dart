import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ddaom_frontend/core/api_client.dart';

void main() {
  Response<dynamic> _makeResponse(Map<String, dynamic> body, int status) {
    return Response(
      data: body,
      statusCode: status,
      requestOptions: RequestOptions(path: '/test'),
    );
  }

  group('parseResponse', () {
    test('S200이면 data를 fromJson에 넘긴다', () {
      final res = _makeResponse({'code': 'S200', 'message': 'ok', 'data': {'name': 'test'}}, 200);
      final result = parseResponse(res, (d) => d['name'] as String);
      expect(result, 'test');
    });

    test('S201이면 data를 fromJson에 넘긴다', () {
      final res = _makeResponse({'code': 'S201', 'message': 'created', 'data': {'id': '1'}}, 201);
      final result = parseResponse(res, (d) => d['id'] as String);
      expect(result, '1');
    });

    test('E401이면 ApiException을 throw한다', () {
      final res = _makeResponse({'code': 'E401', 'message': '권한이 없습니다.', 'data': null}, 200);
      expect(
        () => parseResponse(res, (d) => d),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'E401')),
      );
    });
  });
}
