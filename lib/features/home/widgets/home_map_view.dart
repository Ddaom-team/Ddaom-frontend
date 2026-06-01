import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

// API 키 발급 후 flutter_naver_map을 import하고 NaverMap 위젯으로 교체
class HomeMapView extends StatelessWidget {
  const HomeMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD0D8E0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              '지도 API 키 미설정',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
