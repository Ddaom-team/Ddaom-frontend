import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../screens/camera_screen.dart';
import '../community/community_screen.dart';
import '../home/home_screen.dart';
import '../mypage/mypage_screen.dart';
import '../saved/saved_places_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _myPageRefreshKey = 0;
  int _savedRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const CommunityScreen(),
      CameraScreen(onBack: () => setState(() => _currentIndex = 0)),
      SavedPlacesScreen(key: ValueKey(_savedRefreshKey)),
      MyPageScreen(key: ValueKey(_myPageRefreshKey)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _currentIndex == 2 ? null : Container(
        decoration: const BoxDecoration(
          color: AppColors.navBar,
          border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() {
            // 저장·마이 탭은 진입할 때마다 최신 데이터로 다시 로드.
            if (i == 3) _savedRefreshKey++;
            if (i == 4) _myPageRefreshKey++;
            _currentIndex = i;
          }),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.navBar,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: AppColors.textMuted,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: '커뮤니티'),
            BottomNavigationBarItem(icon: _CameraNavIcon(), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: '저장'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '마이'),
          ],
        ),
      ),
    );
  }
}

class _CameraNavIcon extends StatelessWidget {
  const _CameraNavIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -6),
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: AppColors.primaryPink,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x44FF6B8A), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 27),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text('$label 화면 준비 중')),
    );
  }
}
