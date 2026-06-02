import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../screens/camera_screen.dart';
import '../home/home_screen.dart';
import '../mypage/mypage_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const _PlaceholderScreen(label: '검색'),
      CameraScreen(onBack: () => setState(() => _currentIndex = 0)),
      const _PlaceholderScreen(label: '저장한 장소'),
      const MyPageScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBar,
          border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.navBar,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: AppColors.textMuted,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
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
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.primaryPink,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x33FF6B8A), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
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
