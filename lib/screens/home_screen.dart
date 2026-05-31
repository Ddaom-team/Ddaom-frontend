import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../features/user/user_service.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ddaom'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라 열기'),
            ),
            const SizedBox(height: 16),
            // ── 테스트용 버튼 (서버 확인 후 제거) ──
            OutlinedButton.icon(
              onPressed: () async {
                final api = context.read<ApiClient>();
                final userService = UserService(api);

                try {
                  final me = await userService.getMe();
                  debugPrint('[GET /api/users/me 응답] $me');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('성공: $me')),
                    );
                  }
                } catch (e) {
                  debugPrint('[GET /api/users/me 실패] $e');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('실패: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('[DEBUG] GET /api/users/me'),
            ),
          ],
        ),
      ),
    );
  }
}
