import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ddaom_frontend/core/api_client.dart';
import 'package:ddaom_frontend/core/secure_storage.dart';
import 'package:ddaom_frontend/features/auth/auth_provider.dart';
import 'package:ddaom_frontend/features/auth/auth_service.dart';
import 'package:ddaom_frontend/features/auth/login_screen.dart';

void main() {
  testWidgets('로그인 화면 핵심 텍스트 렌더링', (WidgetTester tester) async {
    final storage = SecureStorage();
    final api = ApiClient(storage);
    final service = AuthService(api, storage);
    final auth = AuthProvider(service, storage);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('따옴'), findsOneWidget);
    expect(find.text('Google 계정으로 로그인'), findsOneWidget);
    expect(find.text('다른 방법으로 로그인'), findsOneWidget);
  });
}
